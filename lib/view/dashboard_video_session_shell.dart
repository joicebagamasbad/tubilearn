import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/dashboard_video_session_controller.dart';
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
  final DashboardVideoSessionController _controller =
  DashboardVideoSessionController();

  Timer? _refreshTimer;

  DashboardVideoSessionSnapshot? _snapshot;

  bool _openingCall = false;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(
      this,
    );

    _loadSession();

    _refreshTimer = Timer.periodic(
      DashboardVideoSessionController
          .refreshInterval,
          (
          Timer timer,
          ) {
        if (!mounted) {
          return;
        }

        _refreshSnapshot();
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
      _refreshSnapshot();
    }
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadSession() async {
    try {
      final DashboardVideoSessionSnapshot snapshot =
      await _controller.loadSession();

      if (!mounted) {
        return;
      }

      setState(() {
        _snapshot = snapshot;
      });
    } catch (_) {
      // The dashboard should remain usable even when
      // the optional video-session overlay cannot load.
    }
  }

  void _refreshSnapshot() {
    try {
      final DashboardVideoSessionSnapshot snapshot =
      _controller.currentSnapshot();

      if (!mounted) {
        return;
      }

      setState(() {
        _snapshot = snapshot;
      });
    } catch (_) {
      // Keep the current overlay state if a refresh fails.
    }
  }

  // ============================================================
  // JOIN VIDEO
  // ============================================================

  Future<void> _joinVideoSession(
      DashboardVideoSession session,
      ) async {
    if (_openingCall) {
      return;
    }

    late final DashboardVideoCallData callData;

    try {
      callData =
          _controller.prepareVideoCall(
            session.request,
          );
    } on DashboardVideoSessionControllerException catch (
    error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );

      _refreshSnapshot();

      return;
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Video session could not be opened. Please try again.',
      );

      return;
    }

    setState(() {
      _openingCall = true;
    });

    try {
      await Navigator.of(
        context,
      ).push(
        MaterialPageRoute<void>(
          builder: (
              BuildContext routeContext,
              ) {
            return VideoCallScreen(
              partnerName:
              callData.partnerName,
              channelName:
              callData.channelName,
              token:
              callData.token,
            );
          },
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingCall = false;
        });

        _refreshSnapshot();
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final DashboardVideoSession? session =
        _snapshot?.session;

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

  // ============================================================
  // VIDEO SESSION CARD
  // ============================================================

  Widget _buildVideoSessionCard(
      DashboardVideoSession session,
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

    return Material(
      color:
      Colors.transparent,
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
              blurRadius: 18,
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
                    AppTextStyles.cardTitle
                        .copyWith(
                      color:
                      textColor,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    session.partnerName,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    AppTextStyles.caption
                        .copyWith(
                      color:
                      mutedColor,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    _formatSessionTime(
                      session
                          .request
                          .proposedAt,
                    ),
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    AppTextStyles.caption
                        .copyWith(
                      color:
                      primaryColor,
                      fontSize: 10,
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

            if (session.canJoin)
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
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                icon:
                _openingCall
                    ? const SizedBox(
                  width: 15,
                  height: 15,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                    Colors.white,
                  ),
                )
                    : const Icon(
                  Icons
                      .video_call_rounded,
                  size: 18,
                ),
                label:
                const Text(
                  'JOIN VIDEO',
                  style:
                  TextStyle(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              )
            else
              Container(
                constraints:
                const BoxConstraints(
                  maxWidth: 98,
                ),
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration:
                BoxDecoration(
                  color:
                  primaryColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Text(
                  session.availabilityText,
                  textAlign:
                  TextAlign.center,
                  style:
                  TextStyle(
                    color:
                    primaryColor,
                    fontSize: 9,
                    height: 1.2,
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

  // ============================================================
  // SESSION TIME
  // ============================================================

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
    dateTime.month - 1
    ];

    return '$month ${dateTime.day} • '
        '$displayHour:$minute $period';
  }

  // ============================================================
  // FEEDBACK
  // ============================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
          Text(
            message,
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }
}