import '../model/repositories/explore_repository.dart';
import '../model/swap_request.dart';
import '../model/user.dart';
import '../services/current_user_service.dart';
import '../services/swap_service.dart';
import '../services/video_call_config.dart';

// ============================================================
// EXCEPTION
// ============================================================

class DashboardVideoSessionControllerException
    implements Exception {
  final String message;

  const DashboardVideoSessionControllerException(
      this.message,
      );

  @override
  String toString() => message;
}

// ============================================================
// SESSION
// ============================================================

class DashboardVideoSession {
  final SwapRequest request;
  final String partnerName;

  final DateTime joinOpensAt;
  final DateTime joinClosesAt;

  final bool canJoin;
  final String availabilityText;

  const DashboardVideoSession({
    required this.request,
    required this.partnerName,
    required this.joinOpensAt,
    required this.joinClosesAt,
    required this.canJoin,
    required this.availabilityText,
  });
}

// ============================================================
// SNAPSHOT
// ============================================================

class DashboardVideoSessionSnapshot {
  final DashboardVideoSession? session;

  const DashboardVideoSessionSnapshot({
    required this.session,
  });

  bool get hasSession =>
      session != null;
}

// ============================================================
// CALL DATA
// ============================================================

class DashboardVideoCallData {
  final String partnerName;
  final String channelName;
  final String token;

  const DashboardVideoCallData({
    required this.partnerName,
    required this.channelName,
    required this.token,
  });
}

// ============================================================
// CONTROLLER
// ============================================================

class DashboardVideoSessionController {
  static const Duration joinLeadTime =
  Duration(
    minutes: 15,
  );

  static const Duration joinGracePeriod =
  Duration(
    hours: 2,
  );

  static const Duration refreshInterval =
  Duration(
    seconds: 15,
  );

  final SwapService _swapService;
  final CurrentUserService _currentUserService;
  final ExploreRepository _exploreRepository;

  DashboardVideoSessionController({
    SwapService? swapService,
    CurrentUserService? currentUserService,
    ExploreRepository? exploreRepository,
  })  : _swapService =
      swapService ??
          SwapService.instance,
        _currentUserService =
            currentUserService ??
                CurrentUserService.instance,
        _exploreRepository =
            exploreRepository ??
                ExploreRepository.instance;

  // ============================================================
  // LOAD
  // ============================================================

  Future<DashboardVideoSessionSnapshot>
  loadSession() async {
    try {
      await _swapService.initialize();
      await _exploreRepository.initialize();

      return _buildSnapshot();
    } on SwapServiceException catch (error) {
      throw DashboardVideoSessionControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw DashboardVideoSessionControllerException(
        error.message,
      );
    } catch (_) {
      throw const DashboardVideoSessionControllerException(
        'Video session information could not be loaded.',
      );
    }
  }

  // ============================================================
  // CURRENT SNAPSHOT
  // ============================================================

  DashboardVideoSessionSnapshot
  currentSnapshot() {
    try {
      return _buildSnapshot();
    } catch (_) {
      throw const DashboardVideoSessionControllerException(
        'Video session information could not be prepared.',
      );
    }
  }

  // ============================================================
  // PREPARE CALL
  // ============================================================

  DashboardVideoCallData prepareVideoCall(
      SwapRequest request,
      ) {
    final DateTime now =
    DateTime.now();

    if (!_isJoinWindowOpen(
      request,
      now,
    )) {
      if (now.isBefore(
        _joinOpensAt(
          request,
        ),
      )) {
        throw const DashboardVideoSessionControllerException(
          'Video session opens 15 minutes before the scheduled time.',
        );
      }

      throw const DashboardVideoSessionControllerException(
        'The video join window for this session has ended.',
      );
    }

    if (!VideoCallConfig.isConfigured) {
      throw const DashboardVideoSessionControllerException(
        'Video calling is not configured for this app run.',
      );
    }

    return DashboardVideoCallData(
      partnerName:
      _partnerName(
        request,
      ),
      channelName:
      VideoCallConfig.agoraChannel,
      token:
      VideoCallConfig.agoraTempToken,
    );
  }

  // ============================================================
  // BUILD SNAPSHOT
  // ============================================================

  DashboardVideoSessionSnapshot _buildSnapshot() {
    final SwapRequest? request =
    _findScheduledOnlineSession();

    if (request == null) {
      return const DashboardVideoSessionSnapshot(
        session: null,
      );
    }

    final DateTime now =
    DateTime.now();

    return DashboardVideoSessionSnapshot(
      session:
      DashboardVideoSession(
        request:
        request,
        partnerName:
        _partnerName(
          request,
        ),
        joinOpensAt:
        _joinOpensAt(
          request,
        ),
        joinClosesAt:
        _joinClosesAt(
          request,
        ),
        canJoin:
        _isJoinWindowOpen(
          request,
          now,
        ),
        availabilityText:
        _joinAvailabilityText(
          request,
          now,
        ),
      ),
    );
  }

  // ============================================================
  // FIND ACTIVE ONLINE SESSION
  // ============================================================

  SwapRequest? _findScheduledOnlineSession() {
    final String currentUserId =
    _currentUserService
        .userId
        .trim();

    if (currentUserId.isEmpty) {
      return null;
    }

    final DateTime now =
    DateTime.now();

    final List<SwapRequest> sessions =
    _swapService.requests
        .where(
          (
          SwapRequest request,
          ) {
        final bool isScheduledOnline =
            request.isScheduledFor(
              currentUserId,
            ) &&
                request.mode
                    .trim()
                    .toLowerCase() ==
                    'online';

        if (!isScheduledOnline) {
          return false;
        }

        return !_isJoinWindowExpired(
          request,
          now,
        );
      },
    )
        .toList();

    if (sessions.isEmpty) {
      return null;
    }

    sessions.sort(
          (
          SwapRequest first,
          SwapRequest second,
          ) {
        final bool firstJoinable =
        _isJoinWindowOpen(
          first,
          now,
        );

        final bool secondJoinable =
        _isJoinWindowOpen(
          second,
          now,
        );

        if (firstJoinable !=
            secondJoinable) {
          return firstJoinable
              ? -1
              : 1;
        }

        return first.proposedAt.compareTo(
          second.proposedAt,
        );
      },
    );

    return sessions.first;
  }

  // ============================================================
  // JOIN WINDOW
  // ============================================================

  DateTime _joinOpensAt(
      SwapRequest session,
      ) {
    return session.proposedAt.subtract(
      joinLeadTime,
    );
  }

  DateTime _joinClosesAt(
      SwapRequest session,
      ) {
    return session.proposedAt.add(
      joinGracePeriod,
    );
  }

  bool _isJoinWindowOpen(
      SwapRequest session,
      DateTime referenceTime,
      ) {
    final DateTime opensAt =
    _joinOpensAt(
      session,
    );

    final DateTime closesAt =
    _joinClosesAt(
      session,
    );

    return !referenceTime.isBefore(
      opensAt,
    ) &&
        !referenceTime.isAfter(
          closesAt,
        );
  }

  bool _isJoinWindowExpired(
      SwapRequest session,
      DateTime referenceTime,
      ) {
    return referenceTime.isAfter(
      _joinClosesAt(
        session,
      ),
    );
  }

  // ============================================================
  // PARTNER
  // ============================================================

  String _partnerName(
      SwapRequest request,
      ) {
    final String currentUserId =
    _currentUserService
        .userId
        .trim();

    String? otherUserId;

    if (request.isRequester(
      currentUserId,
    )) {
      otherUserId =
          request.providerUserId;
    } else if (request.isProvider(
      currentUserId,
    )) {
      otherUserId =
          request.requesterUserId;
    }

    if (otherUserId != null &&
        otherUserId.trim().isNotEmpty) {
      final User? otherUser =
      _exploreRepository.findUserById(
        otherUserId,
      );

      final String? name =
      otherUser?.name.trim();

      if (name != null &&
          name.isNotEmpty) {
        return name;
      }
    }

    if (request.isRequester(
      currentUserId,
    ) &&
        request.providerName
            .trim()
            .isNotEmpty) {
      return request.providerName.trim();
    }

    return 'Swap partner';
  }

  // ============================================================
  // AVAILABILITY TEXT
  // ============================================================

  String _joinAvailabilityText(
      SwapRequest session,
      DateTime referenceTime,
      ) {
    if (_isJoinWindowOpen(
      session,
      referenceTime,
    )) {
      return 'Available now';
    }

    if (_isJoinWindowExpired(
      session,
      referenceTime,
    )) {
      return 'Join window ended';
    }

    final Duration remaining =
    _joinOpensAt(
      session,
    ).difference(
      referenceTime,
    );

    if (remaining.inDays >= 1) {
      final int days =
          remaining.inDays;

      return days == 1
          ? 'Opens in 1 day'
          : 'Opens in $days days';
    }

    if (remaining.inHours >= 1) {
      final int hours =
          remaining.inHours;

      return hours == 1
          ? 'Opens in 1 hour'
          : 'Opens in $hours hours';
    }

    final int minutes =
    remaining.inMinutes.clamp(
      1,
      59,
    );

    return minutes == 1
        ? 'Opens in 1 minute'
        : 'Opens in $minutes minutes';
  }
}