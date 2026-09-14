import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/swap_request.dart';
import '../model/user.dart';
import '../services/current_user_service.dart';
import '../services/review_service.dart';
import '../services/swap_service.dart';

class SwapRequestsControllerException implements Exception {
  final String message;

  const SwapRequestsControllerException(
      this.message,
      );

  @override
  String toString() => message;
}

// ============================================================
// ITEM
// ============================================================

class ManagedSwapRequest {
  final SwapRequest request;
  final SwapRequestDirection direction;
  final User? otherUser;
  final bool hasReviewed;

  const ManagedSwapRequest({
    required this.request,
    required this.direction,
    required this.otherUser,
    required this.hasReviewed,
  });

  bool get isIncoming =>
      direction ==
          SwapRequestDirection.incoming;

  bool get isOutgoing =>
      direction ==
          SwapRequestDirection.outgoing;
}

// ============================================================
// SNAPSHOT
// ============================================================

class SwapRequestsSnapshot {
  final List<ManagedSwapRequest> requests;
  final DateTime? nextSessionBoundary;

  const SwapRequestsSnapshot({
    required this.requests,
    required this.nextSessionBoundary,
  });
}

// ============================================================
// CONTROLLER
// ============================================================

class SwapRequestsController {
  SwapRequestsController({
    CurrentUserService? currentUserService,
    ExploreRepository? exploreRepository,
    SwapService? swapService,
    ReviewService? reviewService,
  })  : _currentUserService =
      currentUserService ??
          CurrentUserService.instance,
        _exploreRepository =
            exploreRepository ??
                ExploreRepository.instance,
        _swapService =
            swapService ??
                SwapService.instance,
        _reviewService =
            reviewService ??
                ReviewService.instance;

  final CurrentUserService _currentUserService;
  final ExploreRepository _exploreRepository;
  final SwapService _swapService;
  final ReviewService _reviewService;

  // ============================================================
  // LOAD
  // ============================================================

  Future<SwapRequestsSnapshot> loadRequests() async {
    try {
      await _exploreRepository.initialize();
      await _swapService.initialize();

      return await _buildSnapshot();
    } on CurrentUserServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } on SwapServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } on ReviewServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } catch (_) {
      throw const SwapRequestsControllerException(
        'Swap requests could not be loaded. Please try again.',
      );
    }
  }

  // ============================================================
  // CURRENT SNAPSHOT
  // ============================================================

  Future<SwapRequestsSnapshot> currentSnapshot() async {
    try {
      return await _buildSnapshot();
    } on CurrentUserServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } on SwapServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } on ReviewServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } catch (_) {
      throw const SwapRequestsControllerException(
        'Swap requests could not be refreshed.',
      );
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<ManagedSwapRequest> filterRequests({
    required List<ManagedSwapRequest> requests,
    required String filter,
  }) {
    if (filter == 'All') {
      return List<ManagedSwapRequest>.unmodifiable(
        requests,
      );
    }

    final List<ManagedSwapRequest> filtered =
    requests.where(
          (
          ManagedSwapRequest managed,
          ) {
        final SwapRequestStatus status =
            managed.request.status;

        switch (filter) {
          case 'Pending':
            return status ==
                SwapRequestStatus.pending;

          case 'Accepted':
            return status ==
                SwapRequestStatus.accepted;

          case 'Scheduled':
            return status ==
                SwapRequestStatus.scheduled;

          case 'Completed':
            return status ==
                SwapRequestStatus.completed;

          case 'Declined':
            return status ==
                SwapRequestStatus.declined;

          case 'Cancelled':
            return status ==
                SwapRequestStatus.cancelled;

          default:
            return true;
        }
      },
    ).toList();

    return List<ManagedSwapRequest>.unmodifiable(
      filtered,
    );
  }

  // ============================================================
  // ACTION AVAILABILITY
  // ============================================================

  bool canAccept(
      SwapRequest request,
      ) {
    return request.canAccept(
      _requireCurrentUserId(),
    );
  }

  bool canDecline(
      SwapRequest request,
      ) {
    return request.canDecline(
      _requireCurrentUserId(),
    );
  }

  bool canCancel(
      SwapRequest request,
      ) {
    return request.canCancel(
      _requireCurrentUserId(),
    );
  }

  bool canEditSchedule(
      SwapRequest request,
      ) {
    final String currentUserId =
    _requireCurrentUserId();

    return request.canEditSchedule(
      currentUserId,
    ) ||
        request.canReschedule(
          currentUserId,
        );
  }

  bool canSchedule(
      SwapRequest request,
      ) {
    return request.canSchedule(
      _requireCurrentUserId(),
    );
  }

  bool canComplete(
      SwapRequest request,
      ) {
    return request.canComplete(
      _requireCurrentUserId(),
    );
  }

  bool canReview(
      ManagedSwapRequest managed,
      ) {
    final SwapRequest request =
        managed.request;

    return request.status ==
        SwapRequestStatus.completed &&
        request.hasStableIdentity &&
        request.involvesUser(
          _requireCurrentUserId(),
        ) &&
        !managed.hasReviewed;
  }

  bool canRemoveFromHistory(
      SwapRequest request,
      ) {
    return request.hasStableIdentity &&
        request.status.isTerminal &&
        request.involvesUser(
          _requireCurrentUserId(),
        );
  }

  bool hasAvailableAction(
      ManagedSwapRequest managed,
      ) {
    final SwapRequest request =
        managed.request;

    return canAccept(
      request,
    ) ||
        canDecline(
          request,
        ) ||
        canCancel(
          request,
        ) ||
        canEditSchedule(
          request,
        ) ||
        canSchedule(
          request,
        ) ||
        canComplete(
          request,
        ) ||
        canReview(
          managed,
        ) ||
        canRemoveFromHistory(
          request,
        );
  }

  // ============================================================
  // ACCEPT
  // ============================================================

  Future<SwapRequestsSnapshot> acceptRequest(
      String requestId,
      ) async {
    try {
      await _swapService.acceptRequest(
        requestId: requestId,
        actorUserId:
        _requireCurrentUserId(),
      );

      return await _buildSnapshot();
    } on SwapServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } on ReviewServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } catch (_) {
      throw const SwapRequestsControllerException(
        'Swap request could not be accepted.',
      );
    }
  }

  // ============================================================
  // DECLINE
  // ============================================================

  Future<SwapRequestsSnapshot> declineRequest(
      String requestId,
      ) async {
    try {
      await _swapService.declineRequest(
        requestId: requestId,
        actorUserId:
        _requireCurrentUserId(),
      );

      return await _buildSnapshot();
    } on SwapServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } on ReviewServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } catch (_) {
      throw const SwapRequestsControllerException(
        'Swap request could not be declined.',
      );
    }
  }

  // ============================================================
  // CANCEL
  // ============================================================

  Future<SwapRequestsSnapshot> cancelRequest(
      String requestId,
      ) async {
    try {
      await _swapService.cancelRequest(
        requestId: requestId,
        actorUserId:
        _requireCurrentUserId(),
      );

      return await _buildSnapshot();
    } on SwapServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } on ReviewServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } catch (_) {
      throw const SwapRequestsControllerException(
        'Swap request could not be cancelled.',
      );
    }
  }

  // ============================================================
  // CONFIRM SCHEDULE
  // ============================================================

  Future<SwapRequestsSnapshot> confirmSchedule(
      String requestId,
      ) async {
    try {
      await _swapService.scheduleRequest(
        requestId: requestId,
        actorUserId:
        _requireCurrentUserId(),
      );

      return await _buildSnapshot();
    } on SwapServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } on ReviewServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } catch (_) {
      throw const SwapRequestsControllerException(
        'Session schedule could not be confirmed.',
      );
    }
  }

  // ============================================================
  // COMPLETE
  // ============================================================

  Future<SwapRequestsSnapshot> completeRequest(
      String requestId,
      ) async {
    try {
      await _swapService.completeRequest(
        requestId: requestId,
        actorUserId:
        _requireCurrentUserId(),
      );

      return await _buildSnapshot();
    } on SwapServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } on ReviewServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } catch (_) {
      throw const SwapRequestsControllerException(
        'Swap request could not be completed.',
      );
    }
  }

  // ============================================================
  // UPDATE SCHEDULE
  // ============================================================

  Future<SwapRequestsSnapshot> updateSchedule({
    required String requestId,
    required DateTime proposedAt,
    required String mode,
    required String meetingDetails,
  }) async {
    try {
      await _swapService.updateSchedule(
        requestId: requestId,
        actorUserId:
        _requireCurrentUserId(),
        proposedAt: proposedAt,
        mode: mode,
        meetingDetails:
        meetingDetails,
      );

      return await _buildSnapshot();
    } on SwapServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } on ReviewServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } catch (_) {
      throw const SwapRequestsControllerException(
        'Session schedule could not be updated.',
      );
    }
  }

  // ============================================================
  // REMOVE FROM HISTORY
  // ============================================================

  Future<SwapRequestsSnapshot> removeFromHistory(
      String requestId,
      ) async {
    try {
      await _swapService.removeFromHistory(
        requestId: requestId,
        actorUserId:
        _requireCurrentUserId(),
      );

      return await _buildSnapshot();
    } on SwapServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } on ReviewServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } catch (_) {
      throw const SwapRequestsControllerException(
        'Swap request could not be removed from history.',
      );
    }
  }

  // ============================================================
  // REVIEW
  // ============================================================

  Future<SwapRequestsSnapshot> submitReview({
    required String requestId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _reviewService.submitReview(
        swapRequestId: requestId,
        rating: rating,
        comment: comment,
      );

      return await _buildSnapshot();
    } on ReviewServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } on SwapServiceException catch (error) {
      throw SwapRequestsControllerException(
        error.message,
      );
    } catch (_) {
      throw const SwapRequestsControllerException(
        'Review could not be submitted.',
      );
    }
  }

  // ============================================================
  // SUPPORTED SESSION MODES
  // ============================================================

  List<String> supportedModesFor(
      SwapRequest request,
      ) {
    if (!request.hasStableIdentity) {
      throw const SwapRequestsControllerException(
        'This swap does not have enough skill information to edit its session mode.',
      );
    }

    final String? skillToLearnId =
        request.skillToLearnId;

    final String? skillToOfferId =
        request.skillToOfferId;

    if (skillToLearnId == null ||
        skillToOfferId == null) {
      throw const SwapRequestsControllerException(
        'This swap does not have enough skill information to edit its session mode.',
      );
    }

    final Skill? skillToLearn =
    _exploreRepository.findSkillById(
      skillToLearnId,
    );

    final Skill? skillToOffer =
    _exploreRepository.findSkillById(
      skillToOfferId,
    );

    if (skillToLearn == null ||
        skillToOffer == null) {
      throw const SwapRequestsControllerException(
        'One of the skills in this swap is no longer available.',
      );
    }

    final List<String> modes =
    <String>[
      if (skillToLearn.supportsSessionMode(
        'Online',
      ) &&
          skillToOffer.supportsSessionMode(
            'Online',
          ))
        'Online',

      if (skillToLearn.supportsSessionMode(
        'In-person',
      ) &&
          skillToOffer.supportsSessionMode(
            'In-person',
          ))
        'In-person',
    ];

    if (modes.isEmpty) {
      throw const SwapRequestsControllerException(
        'These two skills do not share a compatible session mode.',
      );
    }

    return List<String>.unmodifiable(
      modes,
    );
  }

  // ============================================================
  // SNAPSHOT
  // ============================================================

  Future<SwapRequestsSnapshot> _buildSnapshot() async {
    final String currentUserId =
    _requireCurrentUserId();

    final List<SwapRequest> requests =
    _swapService.requests
        .where(
          (
          SwapRequest request,
          ) =>
          request.involvesUser(
            currentUserId,
          ),
    )
        .toList();

    requests.sort(
          (
          SwapRequest first,
          SwapRequest second,
          ) =>
          second.updatedAt.compareTo(
            first.updatedAt,
          ),
    );

    final List<ManagedSwapRequest> managed =
    <ManagedSwapRequest>[];

    for (final SwapRequest request in requests) {
      final SwapRequestDirection direction =
      request.directionFor(
        currentUserId,
      );

      final User? otherUser =
      _findOtherParticipant(
        request,
        direction,
      );

      bool hasReviewed = false;

      if (request.status ==
          SwapRequestStatus.completed &&
          request.hasStableIdentity) {
        hasReviewed =
        await _reviewService.hasReviewedSwap(
          request.id,
        );
      }

      managed.add(
        ManagedSwapRequest(
          request: request,
          direction: direction,
          otherUser: otherUser,
          hasReviewed: hasReviewed,
        ),
      );
    }

    return SwapRequestsSnapshot(
      requests:
      List<ManagedSwapRequest>.unmodifiable(
        managed,
      ),
      nextSessionBoundary:
      _findNextSessionBoundary(
        requests,
        currentUserId,
      ),
    );
  }

  // ============================================================
  // OTHER PARTICIPANT
  // ============================================================

  User? _findOtherParticipant(
      SwapRequest request,
      SwapRequestDirection direction,
      ) {
    String? userId;

    if (direction ==
        SwapRequestDirection.incoming) {
      userId =
          request.requesterUserId;
    } else if (direction ==
        SwapRequestDirection.outgoing) {
      userId =
          request.providerUserId;
    }

    final String cleanUserId =
        userId?.trim() ?? '';

    if (cleanUserId.isEmpty) {
      return null;
    }

    return _exploreRepository.findUserById(
      cleanUserId,
    );
  }

  // ============================================================
  // NEXT SESSION BOUNDARY
  // ============================================================

  DateTime? _findNextSessionBoundary(
      List<SwapRequest> requests,
      String currentUserId,
      ) {
    final DateTime now =
    DateTime.now();

    DateTime? nextBoundary;

    for (final SwapRequest request in requests) {
      if (request.status !=
          SwapRequestStatus.scheduled ||
          !request.hasStableIdentity ||
          !request.involvesUser(
            currentUserId,
          ) ||
          !request.proposedAt.isAfter(
            now,
          )) {
        continue;
      }

      if (nextBoundary == null ||
          request.proposedAt.isBefore(
            nextBoundary,
          )) {
        nextBoundary =
            request.proposedAt;
      }
    }

    return nextBoundary;
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String _requireCurrentUserId() {
    try {
      final String userId =
      _currentUserService
          .requireUserId()
          .trim();

      if (userId.isEmpty) {
        throw const SwapRequestsControllerException(
          'Current user identity is unavailable.',
        );
      }

      return userId;
    } on CurrentUserServiceException {
      throw const SwapRequestsControllerException(
        'Current user identity is unavailable.',
      );
    }
  }
}