import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/skill_match.dart';
import '../model/swap_request.dart';
import '../model/user.dart';
import '../services/current_user_service.dart';
import '../services/swap_service.dart';

class DashboardControllerException implements Exception {
  final String message;

  const DashboardControllerException(
      this.message,
      );

  @override
  String toString() => message;
}

// ============================================================
// SESSION SNAPSHOT
// ============================================================

class DashboardSession {
  final SwapRequest request;
  final User? otherUser;
  final String displayName;
  final String initials;
  final bool readyForCompletion;

  const DashboardSession({
    required this.request,
    required this.otherUser,
    required this.displayName,
    required this.initials,
    required this.readyForCompletion,
  });
}

// ============================================================
// DASHBOARD SNAPSHOT
// ============================================================

class DashboardSnapshot {
  final User? currentUser;
  final List<Skill> featuredSkills;
  final SkillMatch? bestSmartMatch;
  final DashboardSession? prioritySession;

  const DashboardSnapshot({
    required this.currentUser,
    required this.featuredSkills,
    required this.bestSmartMatch,
    required this.prioritySession,
  });

  bool get sessionReady =>
      prioritySession?.readyForCompletion ??
          false;
}

// ============================================================
// CONTROLLER
// ============================================================

class DashboardController {
  final ExploreRepository _repository;
  final CurrentUserService _currentUserService;
  final SwapService _swapService;

  DashboardController({
    ExploreRepository? repository,
    CurrentUserService? currentUserService,
    SwapService? swapService,
  })  : _repository =
      repository ??
          ExploreRepository.instance,
        _currentUserService =
            currentUserService ??
                CurrentUserService.instance,
        _swapService =
            swapService ??
                SwapService.instance;

  // ============================================================
  // LOAD
  // ============================================================

  Future<DashboardSnapshot> loadDashboard() async {
    try {
      await _repository.initialize();

      await _swapService.initialize();

      return _buildSnapshot();
    } on ExploreRepositoryException catch (error) {
      throw DashboardControllerException(
        error.message,
      );
    } on CurrentUserServiceException catch (error) {
      throw DashboardControllerException(
        error.message,
      );
    } on SwapServiceException catch (error) {
      throw DashboardControllerException(
        error.message,
      );
    } catch (_) {
      throw const DashboardControllerException(
        'Dashboard could not be loaded. Please try again.',
      );
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<DashboardSnapshot> refreshDashboard() async {
    try {
      try {
        await _repository.refresh();
      } catch (_) {
        // Keep currently loaded local reference data if refresh fails.
      }

      await _swapService.initialize();

      return _buildSnapshot();
    } on CurrentUserServiceException catch (error) {
      throw DashboardControllerException(
        error.message,
      );
    } on SwapServiceException catch (error) {
      throw DashboardControllerException(
        error.message,
      );
    } catch (_) {
      throw const DashboardControllerException(
        'Dashboard could not be refreshed.',
      );
    }
  }

  // ============================================================
  // CURRENT
  // ============================================================

  DashboardSnapshot currentSnapshot() {
    try {
      return _buildSnapshot();
    } on DashboardControllerException {
      rethrow;
    } on CurrentUserServiceException catch (error) {
      throw DashboardControllerException(
        error.message,
      );
    } catch (_) {
      throw const DashboardControllerException(
        'Dashboard data could not be prepared.',
      );
    }
  }

  // ============================================================
  // SESSION BOUNDARY
  // ============================================================

  Duration? sessionBoundaryDelay(
      DashboardSession? session,
      ) {
    if (session == null ||
        session.readyForCompletion) {
      return null;
    }

    final Duration remaining =
    session.request.proposedAt.difference(
      DateTime.now(),
    );

    if (remaining <= Duration.zero) {
      return Duration.zero;
    }

    return remaining +
        const Duration(
          seconds: 1,
        );
  }

  // ============================================================
  // SESSION READY
  // ============================================================

  bool isSessionReadyForCompletion(
      SwapRequest request,
      ) {
    final User? currentUser =
    _findCurrentUser();

    if (currentUser == null) {
      return false;
    }

    return request
        .isScheduledSessionReadyForCompletionFor(
      currentUser.id,
      DateTime.now(),
    );
  }

  // ============================================================
  // BUILD SNAPSHOT
  // ============================================================

  DashboardSnapshot _buildSnapshot() {
    final User? currentUser =
    _findCurrentUser();

    final List<Skill> featuredSkills =
    List<Skill>.unmodifiable(
      _repository.skills
          .take(
        5,
      )
          .toList(),
    );

    final SkillMatch? bestSmartMatch =
    _findBestSmartMatch(
      currentUser,
    );

    final DashboardSession? prioritySession =
    _findPrioritySession(
      currentUser,
    );

    return DashboardSnapshot(
      currentUser:
      currentUser,
      featuredSkills:
      featuredSkills,
      bestSmartMatch:
      bestSmartMatch,
      prioritySession:
      prioritySession,
    );
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? _findCurrentUser() {
    final String userId =
    _currentUserService.requireUserId();

    return _repository.findUserById(
      userId,
    );
  }

  // ============================================================
  // SMART MATCH
  // ============================================================

  SkillMatch? _findBestSmartMatch(
      User? currentUser,
      ) {
    if (currentUser == null) {
      return null;
    }

    final List<SkillMatch> matches =
    _repository.getSmartMatchesForUser(
      currentUser.id,
      limit: 1,
    );

    if (matches.isEmpty) {
      return null;
    }

    return matches.first;
  }

  // ============================================================
  // SESSION PRIORITY
  // ============================================================

  DashboardSession? _findPrioritySession(
      User? currentUser,
      ) {
    if (currentUser == null) {
      return null;
    }

    final DateTime now =
    DateTime.now();

    final List<SwapRequest> scheduled =
    _swapService.requests
        .where(
          (
          SwapRequest request,
          ) =>
          request.isScheduledFor(
            currentUser.id,
          ),
    )
        .toList();

    if (scheduled.isEmpty) {
      return null;
    }

    final List<SwapRequest> ready =
    scheduled
        .where(
          (
          SwapRequest request,
          ) =>
          request
              .isScheduledSessionReadyForCompletionFor(
            currentUser.id,
            now,
          ),
    )
        .toList();

    SwapRequest? selected;

    if (ready.isNotEmpty) {
      ready.sort(
            (
            SwapRequest first,
            SwapRequest second,
            ) =>
            first.proposedAt.compareTo(
              second.proposedAt,
            ),
      );

      selected =
          ready.first;
    } else {
      final List<SwapRequest> upcoming =
      scheduled
          .where(
            (
            SwapRequest request,
            ) =>
            request
                .isUpcomingScheduledSessionFor(
              currentUser.id,
              now,
            ),
      )
          .toList();

      if (upcoming.isEmpty) {
        return null;
      }

      upcoming.sort(
            (
            SwapRequest first,
            SwapRequest second,
            ) =>
            first.proposedAt.compareTo(
              second.proposedAt,
            ),
      );

      selected =
          upcoming.first;
    }

    return _buildDashboardSession(
      selected,
      currentUser,
      now,
    );
  }

  // ============================================================
  // SESSION SNAPSHOT
  // ============================================================

  DashboardSession _buildDashboardSession(
      SwapRequest request,
      User currentUser,
      DateTime now,
      ) {
    final User? otherUser =
    _findOtherUser(
      request,
      currentUser,
    );

    final String displayName =
        otherUser?.name ??
            _fallbackOtherUserName(
              request,
              currentUser,
            );

    final String initials =
        otherUser?.initials ??
            _fallbackOtherUserInitials(
              request,
              currentUser,
            );

    final bool ready =
    request
        .isScheduledSessionReadyForCompletionFor(
      currentUser.id,
      now,
    );

    return DashboardSession(
      request:
      request,
      otherUser:
      otherUser,
      displayName:
      displayName,
      initials:
      initials,
      readyForCompletion:
      ready,
    );
  }

  // ============================================================
  // OTHER USER
  // ============================================================

  User? _findOtherUser(
      SwapRequest request,
      User currentUser,
      ) {
    if (!request.hasStableIdentity) {
      return null;
    }

    final String? otherUserId;

    if (request.isRequester(
      currentUser.id,
    )) {
      otherUserId =
          request.providerUserId;
    } else if (request.isProvider(
      currentUser.id,
    )) {
      otherUserId =
          request.requesterUserId;
    } else {
      return null;
    }

    if (otherUserId == null ||
        otherUserId.trim().isEmpty) {
      return null;
    }

    return _repository.findUserById(
      otherUserId,
    );
  }

  // ============================================================
  // FALLBACK USER DETAILS
  // ============================================================

  String _fallbackOtherUserName(
      SwapRequest request,
      User currentUser,
      ) {
    if (request.isRequester(
      currentUser.id,
    ) &&
        request.providerName
            .trim()
            .isNotEmpty) {
      return request.providerName.trim();
    }

    return 'Swap partner';
  }

  String _fallbackOtherUserInitials(
      SwapRequest request,
      User currentUser,
      ) {
    if (request.isRequester(
      currentUser.id,
    ) &&
        request.providerInitials
            .trim()
            .isNotEmpty) {
      return request.providerInitials
          .trim();
    }

    return '?';
  }
}