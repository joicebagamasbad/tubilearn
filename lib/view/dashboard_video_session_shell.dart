import 'dart:async';

import 'package:flutter/material.dart';

import '../model/repositories/explore_repository.dart';
import '../model/swap_request.dart';
import '../model/user.dart';
import '../services/current_user_service.dart';
import '../services/swap_service.dart';
import '../services/video_call_config.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'video_call_screen.dart';

class DashboardVideoSessionShell extends StatefulWidget {
  const DashboardVideoSessionShell({
    super.key,
  });

  @override
  State<DashboardVideoSessionShell> createState() =>
      _DashboardVideoSessionShellState();
}

class _DashboardVideoSessionShellState
    extends State<DashboardVideoSessionShell>
    with WidgetsBindingObserver {
  static const Duration _joinLeadTime = Duration(
    minutes: 15,
  );

  static const Duration _joinGracePeriod = Duration(
    hours: 2,
  );

  static const Duration _refreshInterval = Duration(
    seconds: 15,
  );

  final SwapService _swapService = SwapService.instance;

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  final ExploreRepository _exploreRepository =
      ExploreRepository.instance;

  Timer? _refreshTimer;

  bool _openingCall = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(
      this,
    );

    _refreshTimer = Timer.periodic(
      _refreshInterval,
          (_) {
        if (!mounted) {
          return;
        }

        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(
      this,
    );

    _refreshTimer?.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (state == AppLifecycleState.resumed &&
        mounted) {
      setState(() {});
    }
  }

  String get _currentUserId {
    return _currentUserService.userId.trim();
  }

  DateTime _joinOpensAt(
      SwapRequest session,
      ) {
    return session.proposedAt.subtract(
      _joinLeadTime,
    );
  }

  DateTime _joinClosesAt(
      SwapRequest session,
      ) {
    return session.proposedAt.add(
      _joinGracePeriod,
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

  SwapRequest? get _scheduledOnlineSession {
    final String currentUserId =
        _currentUserId;

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

  String _partnerName(
      SwapRequest request,
      ) {
    final String currentUserId =
        _currentUserId;

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
      final User? user =
      _exploreRepository.findUserById(
        otherUserId,
      );

      final String? name =
      user?.name.trim();

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

  String _formatSessionTime(
      DateTime dateTime,
      ) {
    const List<String> months =
    <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final int hour =
        dateTime.hour;

    final int displayHour =
    hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    final String minute =
    dateTime.minute
        .toString()
        .padLeft(
      2,
      '0',
    );

    final String period =
    hour >= 12
        ? 'PM'
        : 'AM';

    final String month =
    months[
    dateTime.month -
        1];

    return '$month ${dateTime.day} • '
        '$displayHour:$minute $period';
  }

  String _joinAvailabilityText(
      SwapRequest session,
      DateTime referenceTime,
      ) {
    final DateTime opensAt =
    _joinOpensAt(
      session,
    );

    final Duration remaining =
    opensAt.difference(
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

  void _showJoinUnavailableMessage(
      SwapRequest session,
      ) {
    final DateTime now =
    DateTime.now();

    final bool tooEarly =
    now.isBefore(
      _joinOpensAt(
        session,
      ),
    );

    final String message =
    tooEarly
        ? 'Video session opens 15 minutes before the scheduled time.'
        : 'The video join window for this session has ended.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  Future<void> _joinVideoSession(
      SwapRequest request,
      ) async {
    if (_openingCall) {
      return;
    }

    final DateTime now =
    DateTime.now();

    if (!_isJoinWindowOpen(
      request,
      now,
    )) {
      _showJoinUnavailableMessage(
        request,
      );

      return;
    }

    if (!VideoCallConfig.isConfigured) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Video calling is not configured for this app run.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _openingCall = true;
    });

    final String partnerName =
    _partnerName(
      request,
    );

    try {
      await Navigator.of(
        context,
      ).push(
        MaterialPageRoute<void>(
          builder: (
              BuildContext context,
              ) {
            return VideoCallScreen(
              partnerName:
              partnerName,
              channelName:
              VideoCallConfig
                  .agoraChannel,
              token:
              VideoCallConfig
                  .agoraTempToken,
            );
          },
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingCall = false;
        });
      }
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final SwapRequest? session =
        _scheduledOnlineSession;

    return Stack(
      children: <Widget>[
        const DashboardScreen(),

        if (session != null)
          Positioned(
            left: 14,
            right: 14,
            bottom: 88,
            child: SafeArea(
              top: false,
              child: _buildVideoSessionCard(
                session,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoSessionCard(
      SwapRequest session,
      ) {
    final ThemeData theme =
    Theme.of(
      context,
    );

    final Color primaryColor =
        theme.colorScheme.primary;

    final Color surfaceColor =
        theme.colorScheme.surface;

    final Color textColor =
        theme.colorScheme.onSurface;

    final Color mutedColor =
        theme.colorScheme.onSurfaceVariant;

    final String partnerName =
    _partnerName(
      session,
    );

    final DateTime now =
    DateTime.now();

    final bool canJoin =
    _isJoinWindowOpen(
      session,
      now,
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        padding:
        const EdgeInsets.all(
          12,
        ),
        decoration:
        BoxDecoration(
          color:
          surfaceColor,
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          border:
          Border.all(
            color:
            primaryColor.withValues(
              alpha: 0.35,
            ),
          ),
          boxShadow:
          <BoxShadow>[
            BoxShadow(
              color:
              Colors.black.withValues(
                alpha: 0.16,
              ),
              blurRadius:
              18,
              offset:
              const Offset(
                0,
                7,
              ),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration:
              BoxDecoration(
                color:
                primaryColor.withValues(
                  alpha: 0.14,
                ),
                borderRadius:
                BorderRadius.circular(
                  13,
                ),
              ),
              child: Icon(
                Icons.videocam_rounded,
                color:
                primaryColor,
              ),
            ),
            const SizedBox(
              width: 11,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                mainAxisSize:
                MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Online session',
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    AppTextStyles.cardTitle.copyWith(
                      color:
                      textColor,
                      fontSize:
                      13,
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    partnerName,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    AppTextStyles.caption.copyWith(
                      color:
                      mutedColor,
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    _formatSessionTime(
                      session.proposedAt,
                    ),
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    AppTextStyles.caption.copyWith(
                      color:
                      primaryColor,
                      fontSize:
                      10,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            if (canJoin)
              FilledButton.icon(
                onPressed:
                _openingCall
                    ? null
                    : () {
                  _joinVideoSession(
                    session,
                  );
                },
                style:
                FilledButton.styleFrom(
                  backgroundColor:
                  primaryColor,
                  foregroundColor:
                  Colors.white,
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal:
                    12,
                    vertical:
                    10,
                  ),
                ),
                icon:
                _openingCall
                    ? const SizedBox(
                  width:
                  15,
                  height:
                  15,
                  child:
                  CircularProgressIndicator(
                    strokeWidth:
                    2,
                    color:
                    Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.video_call_rounded,
                  size:
                  18,
                ),
                label:
                const Text(
                  'JOIN VIDEO',
                  style:
                  TextStyle(
                    fontSize:
                    10,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              )
            else
              Container(
                constraints:
                const BoxConstraints(
                  maxWidth:
                  98,
                ),
                padding:
                const EdgeInsets.symmetric(
                  horizontal:
                  10,
                  vertical:
                  8,
                ),
                decoration:
                BoxDecoration(
                  color:
                  primaryColor.withValues(
                    alpha:
                    0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child:
                Text(
                  _joinAvailabilityText(
                    session,
                    now,
                  ),
                  textAlign:
                  TextAlign.center,
                  style:
                  TextStyle(
                    color:
                    primaryColor,
                    fontSize:
                    9,
                    height:
                    1.2,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}