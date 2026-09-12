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

class DashboardVideoSessionShell
    extends StatefulWidget {
  const DashboardVideoSessionShell({
    super.key,
  });

  @override
  State<DashboardVideoSessionShell>
  createState() =>
      _DashboardVideoSessionShellState();
}

class _DashboardVideoSessionShellState
    extends State<DashboardVideoSessionShell>
    with WidgetsBindingObserver {
  final SwapService _swapService =
      SwapService.instance;

  final CurrentUserService
  _currentUserService =
      CurrentUserService.instance;

  final ExploreRepository
  _exploreRepository =
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
      const Duration(
        seconds: 2,
      ),
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
    if (state ==
        AppLifecycleState.resumed &&
        mounted) {
      setState(() {});
    }
  }

  String get _currentUserId {
    return _currentUserService.userId.trim();
  }

  SwapRequest?
  get _scheduledOnlineSession {
    final String currentUserId =
        _currentUserId;

    if (currentUserId.isEmpty) {
      return null;
    }

    final List<SwapRequest> sessions =
    _swapService.requests
        .where(
          (
          SwapRequest request,
          ) {
        return request.isScheduledFor(
          currentUserId,
        ) &&
            request.mode
                .trim()
                .toLowerCase() ==
                'online';
      },
    )
        .toList();

    if (sessions.isEmpty) {
      return null;
    }

    final DateTime now =
    DateTime.now();

    sessions.sort(
          (
          SwapRequest first,
          SwapRequest second,
          ) {
        final bool firstStarted =
        !now.isBefore(
          first.proposedAt,
        );

        final bool secondStarted =
        !now.isBefore(
          second.proposedAt,
        );

        if (firstStarted !=
            secondStarted) {
          return firstStarted ? -1 : 1;
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

  Future<void> _joinVideoSession(
      SwapRequest request,
      ) async {
    if (_openingCall) {
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
    final Color primaryColor =
        Theme.of(
          context,
        ).colorScheme.primary;

    final Color surfaceColor =
        Theme.of(
          context,
        ).colorScheme.surface;

    final Color textColor =
        Theme.of(
          context,
        ).colorScheme.onSurface;

    final Color mutedColor =
        Theme.of(
          context,
        ).colorScheme.onSurfaceVariant;

    final String partnerName =
    _partnerName(
      session,
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
                Icons
                    .videocam_rounded,
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
                CrossAxisAlignment
                    .start,
                mainAxisSize:
                MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Online session',
                    maxLines: 1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    AppTextStyles
                        .cardTitle
                        .copyWith(
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
                    TextOverflow
                        .ellipsis,
                    style:
                    AppTextStyles
                        .caption
                        .copyWith(
                      color:
                      mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 10,
            ),
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
                const EdgeInsets
                    .symmetric(
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
                Icons
                    .video_call_rounded,
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
            ),
          ],
        ),
      ),
    );
  }
}