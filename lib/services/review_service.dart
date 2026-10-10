import '../model/repositories/explore_repository.dart';
import '../model/repositories/firestore_review_repository.dart';
import '../model/repositories/review_repository.dart';
import '../model/review.dart';
import '../model/swap_request.dart';
import '../model/user.dart';

import 'current_user_service.dart';
import 'swap_service.dart';

// ============================================================
// RECEIVED REVIEW
// ============================================================

/// One review received by a user, paired with the denormalized
/// reviewer-name snapshot stored on the Firestore document at
/// submission time (not the current, possibly-changed, reviewer name).
class ReceivedReview {
  final Review review;
  final String reviewerName;

  const ReceivedReview({
    required this.review,
    required this.reviewerName,
  });
}

// ============================================================
// RECEIVED REVIEWS
// ============================================================

class ReceivedReviews {
  final List<ReceivedReview> reviews;
  final double averageRating;
  final int count;
  final bool available;

  const ReceivedReviews({
    required this.reviews,
    required this.averageRating,
    required this.count,
    required this.available,
  });

  const ReceivedReviews.unavailable()
      : reviews = const <ReceivedReview>[],
        averageRating = 0,
        count = 0,
        available = false;
}

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

  final FirestoreReviewRepository _firestoreReviewRepository =
      FirestoreReviewRepository.instance;

  final SwapService _swapService =
      SwapService.instance;

  final ExploreRepository _exploreRepository =
      ExploreRepository.instance;

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  final Map<String, Future<Review>>
  _pendingSubmissions =
  <String, Future<Review>>{};

  final Map<String, bool>
  _reviewedCache =
  <String, bool>{};

  Future<void> resetSession() async {
    try {
      await Future.wait<Review>(_pendingSubmissions.values.toList());
    } catch (_) {
      // Pending submission errors are reported to their callers.
    }
    _pendingSubmissions.clear();
    _reviewedCache.clear();
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

    final bool? cached =
        _reviewedCache[requestId];

    if (cached != null) {
      return cached;
    }

    // Legacy pre-Firestore reviews may still only exist locally.
    try {
      final Review? review =
      await _reviewRepository
          .findReviewForSwapByReviewer(
        swapRequestId:
        requestId,
        reviewerUserId:
        currentUserId,
      );

      if (review != null) {
        _reviewedCache[requestId] = true;
        return true;
      }
    } on ReviewRepositoryException catch (error) {
      throw ReviewServiceException(
        error.message,
      );
    } catch (_) {
      throw const ReviewServiceException(
        'Could not check review status.',
      );
    }

    // This must never throw because of Firestore: a review-status
    // check backing a swap card button is best-effort, not critical.
    try {
      final bool? exists =
      await _firestoreReviewRepository.reviewExists(
        swapRequestId:
        requestId,
        reviewerUid:
        currentUserId,
      );

      if (exists == true) {
        _reviewedCache[requestId] = true;
        return true;
      }

      if (exists == false) {
        _reviewedCache[requestId] = false;
        return false;
      }

      // exists == null: unknown (offline/unreachable) — do not cache,
      // so the next call tries again instead of being stuck on a guess.
      return false;
    } on FirestoreReviewRepositoryException {
      return false;
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

    // The reviewer's own display name, denormalized onto the Firestore
    // review document at submission time — same pattern as
    // swapRequests.providerName.
    final User? reviewer =
    _exploreRepository.findUserById(
      reviewerUserId,
    );

    final String? reviewerName =
        reviewer?.name.trim();

    if (reviewerName == null ||
        reviewerName.isEmpty) {
      throw const ReviewServiceException(
        'Your profile is not ready yet. Please try again.',
      );
    }

    try {
      _currentUserService.requireActiveOperation();

      final String documentId =
      await _firestoreReviewRepository.createReview(
        swapRequestId:
        requestId,
        reviewerUid:
        reviewerUserId,
        revieweeUid:
        revieweeUserId,
        reviewerName:
        reviewerName,
        rating:
        rating,
        comment:
        comment,
      );

      _currentUserService.requireActiveOperation();

      _reviewedCache[requestId] = true;

      return Review(
        id:
        documentId,
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
        DateTime.now(),
      );
    } on FirestoreReviewRepositoryException catch (error) {
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
  // REVIEWS RECEIVED BY A USER
  //
  // Reviews of OTHER users are never projected into local SQLite (it
  // would violate the reviews table's FK to swap_requests/users, since
  // the viewer's local tables only hold their OWN participant-scoped
  // rows) — these are held in memory only, for the caller to display.
  // ============================================================

  Future<ReceivedReviews> loadReviewsReceivedBy(
      String uid,
      ) async {
    return _currentUserService.runForSession<ReceivedReviews>(() async {
    final String cleanUid =
    _requireText(
      uid,
      'User ID',
    );

    final FirestoreReviewSnapshot snapshot;

    try {
      snapshot =
      await _firestoreReviewRepository.getReviewsReceivedBy(
        cleanUid,
      );
    } on FirestoreReviewRepositoryException {
      return const ReceivedReviews.unavailable();
    }
    _currentUserService.requireActiveOperation();

    if (snapshot.source ==
        FirestoreReviewSource.unavailable) {
      return const ReceivedReviews.unavailable();
    }

    final List<ReceivedReview> reviews =
    snapshot.reviews
        .map(
          (
          FirestoreReviewRecord record,
          ) {
        return ReceivedReview(
          review:
          Review(
            id:
            record.id,
            swapRequestId:
            record.swapRequestId,
            reviewerUserId:
            record.reviewerUid,
            revieweeUserId:
            record.revieweeUid,
            rating:
            record.rating,
            comment:
            record.comment,
            createdAt:
            record.createdAt.toLocal(),
          ),
          reviewerName:
          record.reviewerName,
        );
      },
    )
        .toList(
      growable: false,
    );

    final int count =
        reviews.length;

    final double averageRating =
        count == 0
            ? 0
            : reviews
            .map(
              (
              ReceivedReview item,
              ) =>
          item.review.rating,
        )
            .reduce(
              (
              int a,
              int b,
              ) =>
          a + b,
        ) /
            count;

    return ReceivedReviews(
      reviews:
      reviews,
      averageRating:
      averageRating,
      count:
      count,
      available:
      true,
    );
  });
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