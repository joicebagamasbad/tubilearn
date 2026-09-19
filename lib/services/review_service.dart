import '../model/repositories/explore_repository.dart';
import '../model/repositories/review_repository.dart';
import '../model/review.dart';
import '../model/swap_request.dart';

import 'current_user_service.dart';
import 'swap_service.dart';

class ReviewServiceException implements Exception {
  final String message;

  const ReviewServiceException(
      this.message,
      );

  @override
  String toString() => message;
}

class ReviewService {
  ReviewService._();

  static final ReviewService instance =
  ReviewService._();

  final ReviewRepository _reviewRepository =
      ReviewRepository.instance;

  final SwapService _swapService =
      SwapService.instance;

  final ExploreRepository _exploreRepository =
      ExploreRepository.instance;

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  final Map<String, Future<Review>>
  _pendingSubmissions =
  <String, Future<Review>>{};

  int _lastReviewIdMicros = 0;

  Future<void> resetSession() async {
    try {
      await Future.wait<Review>(_pendingSubmissions.values.toList());
    } catch (_) {
      // Pending submission errors are reported to their callers.
    }
    _pendingSubmissions.clear();
    _lastReviewIdMicros = 0;
  }

  // ============================================================
  // REVIEW ELIGIBILITY
  // ============================================================

  Future<bool> hasReviewedSwap(
      String swapRequestId,
      ) async {
    final String requestId =
    _requireText(
      swapRequestId,
      'Swap request ID',
    );

    final String currentUserId =
    _requireCurrentUserId();

    try {
      final Review? review =
      await _reviewRepository
          .findReviewForSwapByReviewer(
        swapRequestId:
        requestId,
        reviewerUserId:
        currentUserId,
      );

      return review != null;
    } on ReviewRepositoryException catch (error) {
      throw ReviewServiceException(
        error.message,
      );
    } catch (_) {
      throw const ReviewServiceException(
        'Could not check review status.',
      );
    }
  }

  Future<bool> canReviewSwap(
      SwapRequest request,
      ) async {
    final String currentUserId =
    _requireCurrentUserId();

    if (request.status !=
        SwapRequestStatus.completed) {
      return false;
    }

    if (!request.hasStableIdentity ||
        !request.involvesUser(
          currentUserId,
        )) {
      return false;
    }

    if (_otherParticipantId(
      request,
      currentUserId,
    ) ==
        null) {
      return false;
    }

    return !(await hasReviewedSwap(
      request.id,
    ));
  }

  // ============================================================
  // SUBMIT REVIEW
  // ============================================================

  Future<Review> submitReview({
    required String swapRequestId,
    required int rating,
    String? comment,
  }) async {
    return _currentUserService.runForSession<Review>(() async {
    await _swapService.initialize();

    final String requestId =
    _requireText(
      swapRequestId,
      'Swap request ID',
    );

    final String currentUserId =
    _requireCurrentUserId();

    if (rating < 1 ||
        rating > 5) {
      throw const ReviewServiceException(
        'Please choose a rating from 1 to 5 stars.',
      );
    }

    final String? cleanComment =
    _normalizeNullable(
      comment,
    );

    if (cleanComment != null &&
        cleanComment.length > 500) {
      throw const ReviewServiceException(
        'Review comment must be 500 characters or less.',
      );
    }

    final SwapRequest? request =
    _swapService.findById(
      requestId,
    );

    if (request == null) {
      throw const ReviewServiceException(
        'Completed swap could not be found.',
      );
    }

    if (request.status !=
        SwapRequestStatus.completed) {
      throw const ReviewServiceException(
        'Only completed swaps can be reviewed.',
      );
    }

    if (!request.hasStableIdentity ||
        !request.involvesUser(
          currentUserId,
        )) {
      throw const ReviewServiceException(
        'You are not allowed to review this swap.',
      );
    }

    final String? revieweeUserId =
    _otherParticipantId(
      request,
      currentUserId,
    );

    if (revieweeUserId == null) {
      throw const ReviewServiceException(
        'The other participant could not be identified.',
      );
    }

    final String submissionKey =
        '$requestId|$currentUserId';

    final Future<Review>? pending =
    _pendingSubmissions[
    submissionKey
    ];

    if (pending != null) {
      return pending;
    }

    final Future<Review> submission =
    _submitReviewInternal(
      requestId:
      requestId,
      reviewerUserId:
      currentUserId,
      revieweeUserId:
      revieweeUserId,
      rating:
      rating,
      comment:
      cleanComment,
    );

    _pendingSubmissions[
    submissionKey
    ] = submission;

    try {
      return await submission;
    } finally {
      if (identical(
        _pendingSubmissions[
        submissionKey
        ],
        submission,
      )) {
        _pendingSubmissions.remove(
          submissionKey,
        );
      }
    }
  });
  }

  Future<Review> _submitReviewInternal({
    required String requestId,
    required String reviewerUserId,
    required String revieweeUserId,
    required int rating,
    required String? comment,
  }) async {
    final Review? existingReview;

    try {
      existingReview =
      await _reviewRepository
          .findReviewForSwapByReviewer(
        swapRequestId:
        requestId,
        reviewerUserId:
        reviewerUserId,
      );
    } on ReviewRepositoryException catch (error) {
      throw ReviewServiceException(
        error.message,
      );
    }

    if (existingReview != null) {
      throw const ReviewServiceException(
        'You already reviewed this completed swap.',
      );
    }

    _currentUserService.requireActiveOperation();

    final DateTime createdAt =
    DateTime.now();

    final String reviewId =
    _createReviewId(
      createdAt,
    );

    try {
      _currentUserService.requireActiveOperation();
      final Review review =
      await _reviewRepository.createReview(
        id:
        reviewId,
        swapRequestId:
        requestId,
        reviewerUserId:
        reviewerUserId,
        revieweeUserId:
        revieweeUserId,
        rating:
        rating,
        comment:
        comment,
        createdAt:
        createdAt,
      );

      _currentUserService.requireActiveOperation();

      try {
        await _exploreRepository.refresh();
      } catch (_) {
        // The review itself is already safely stored.
        // The Explore cache can refresh again on the next load.
      }

      return review;
    } on ReviewRepositoryException catch (error) {
      throw ReviewServiceException(
        error.message,
      );
    } catch (_) {
      throw const ReviewServiceException(
        'Review could not be submitted. Please try again.',
      );
    }
  }

  // ============================================================
  // PARTICIPANT HELPERS
  // ============================================================

  String? _otherParticipantId(
      SwapRequest request,
      String currentUserId,
      ) {
    if (request.isRequester(
      currentUserId,
    )) {
      final String? providerUserId =
          request.providerUserId;

      if (providerUserId == null ||
          providerUserId.trim().isEmpty) {
        return null;
      }

      return providerUserId.trim();
    }

    if (request.isProvider(
      currentUserId,
    )) {
      final String? requesterUserId =
          request.requesterUserId;

      if (requesterUserId == null ||
          requesterUserId.trim().isEmpty) {
        return null;
      }

      return requesterUserId.trim();
    }

    return null;
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String _requireCurrentUserId() {
    try {
      return _currentUserService
          .requireUserId();
    } on CurrentUserServiceException catch (_) {
      throw const ReviewServiceException(
        'Current user identity is unavailable.',
      );
    }
  }

  // ============================================================
  // REVIEW ID
  // ============================================================

  String _createReviewId(
      DateTime now,
      ) {
    int candidate =
        now.microsecondsSinceEpoch;

    if (candidate <=
        _lastReviewIdMicros) {
      candidate =
          _lastReviewIdMicros + 1;
    }

    _lastReviewIdMicros =
        candidate;

    return 'review_$candidate';
  }

  // ============================================================
  // TEXT
  // ============================================================

  String _requireText(
      String value,
      String label,
      ) {
    final String clean =
    value.trim();

    if (clean.isEmpty) {
      throw ReviewServiceException(
        '$label is required.',
      );
    }

    return clean;
  }

  String? _normalizeNullable(
      String? value,
      ) {
    if (value == null) {
      return null;
    }

    final String clean =
    value.trim();

    return clean.isEmpty
        ? null
        : clean;
  }
}