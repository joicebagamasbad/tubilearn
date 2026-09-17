import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../controller/video_call_controller.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    super.key,
    this.partnerName = 'Swap partner',
    this.channelName,
    this.token,
  });

  final String partnerName;
  final String? channelName;
  final String? token;

  @override
  State<VideoCallScreen> createState() =>
      _VideoCallScreenState();
}

class _VideoCallScreenState
    extends State<VideoCallScreen> {
  late final VideoCallController _controller;

  late VideoCallSnapshot _snapshot;

  bool _initializingCall = true;

  String? _initializationError;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller =
        VideoCallController();

    _snapshot =
        _controller.snapshot;

    _controller.addListener(
      _handleControllerChanged,
    );

    unawaited(
      _initializeCall(),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(
      _handleControllerChanged,
    );

    _controller.dispose();

    super.dispose();
  }

  // ============================================================
  // CONTROLLER LISTENER
  // ============================================================

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _snapshot =
          _controller.snapshot;
    });
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializeCall() async {
    if (mounted) {
      setState(() {
        _initializingCall = true;
        _initializationError = null;
      });
    }

    try {
      await _controller.initialize(
        channelName:
        widget.channelName,
        token:
        widget.token,
      );
    } on VideoCallControllerException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _initializationError =
            error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _initializationError =
        'Video call could not be started. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _snapshot =
              _controller.snapshot;

          _initializingCall =
          false;
        });
      }
    }
  }

  // ============================================================
  // MICROPHONE
  // ============================================================

  Future<void> _toggleMicrophone() async {
    try {
      await _controller.toggleMicrophone();
    } on VideoCallControllerException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Microphone could not be updated.',
      );
    }
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void> _toggleCamera() async {
    try {
      await _controller.toggleCamera();
    } on VideoCallControllerException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Camera could not be updated.',
      );
    }
  }

  // ============================================================
  // SWITCH CAMERA
  // ============================================================

  Future<void> _switchCamera() async {
    try {
      await _controller.switchCamera();
    } on VideoCallControllerException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Camera could not be switched.',
      );
    }
  }

  // ============================================================
  // LEAVE CALL
  // ============================================================

  Future<void> _leaveCall() async {
    if (_snapshot.leaving) {
      return;
    }

    try {
      await _controller.leaveCall();
    } on VideoCallControllerException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Video call could not be closed normally.',
      );
    }

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pop();
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<void> _retry() async {
    await _initializeCall();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_initializingCall ||
        _snapshot.initializing) {
      return _buildLoadingScreen();
    }

    final String? errorMessage =
        _initializationError ??
            _snapshot.errorMessage;

    if (errorMessage != null &&
        _snapshot.engine == null) {
      return _buildErrorScreen(
        errorMessage,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
          bool didPop,
          Object? result,
          ) {
        if (!didPop) {
          unawaited(
            _leaveCall(),
          );
        }
      },
      child: Scaffold(
        backgroundColor:
        Colors.black,
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child:
                _buildMainVideo(),
              ),

              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child:
                _buildTopBar(),
              ),

              if (_snapshot.joined)
                Positioned(
                  top: 84,
                  right: 16,
                  child:
                  _buildLocalPreview(),
                ),

              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child:
                _buildControls(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING SCREEN
  // ============================================================

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor:
      Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(),

              SizedBox(
                height: 18,
              ),

              Text(
                'Preparing video call...',
                style:
                TextStyle(
                  color:
                  Colors.white,
                  fontSize:
                  16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR SCREEN
  // ============================================================

  Widget _buildErrorScreen(
      String errorMessage,
      ) {
    return Scaffold(
      backgroundColor:
      Colors.black,
      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.all(
            24,
          ),
          child: Center(
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons
                      .videocam_off_rounded,
                  color:
                  Colors.white70,
                  size:
                  64,
                ),

                const SizedBox(
                  height:
                  20,
                ),

                const Text(
                  'Unable to start video call',
                  textAlign:
                  TextAlign.center,
                  style:
                  TextStyle(
                    color:
                    Colors.white,
                    fontSize:
                    22,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height:
                  12,
                ),

                Text(
                  errorMessage,
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    color:
                    Colors.white70,
                    fontSize:
                    14,
                    height:
                    1.4,
                  ),
                ),

                const SizedBox(
                  height:
                  24,
                ),

                FilledButton.icon(
                  onPressed:
                  _retry,
                  icon:
                  const Icon(
                    Icons.refresh_rounded,
                  ),
                  label:
                  const Text(
                    'Try again',
                  ),
                ),

                const SizedBox(
                  height:
                  8,
                ),

                TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop();
                  },
                  child:
                  const Text(
                    'Go back',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MAIN REMOTE VIDEO
  // ============================================================

  Widget _buildMainVideo() {
    final RtcEngine? engine =
        _snapshot.engine;

    final int? remoteUid =
        _snapshot.remoteUid;

    if (engine != null &&
        remoteUid != null) {
      return AgoraVideoView(
        controller:
        VideoViewController.remote(
          rtcEngine:
          engine,
          canvas:
          VideoCanvas(
            uid:
            remoteUid,
            renderMode:
            RenderModeType
                .renderModeHidden,
          ),
          connection:
          RtcConnection(
            channelId:
            _snapshot.channelName,
          ),
        ),
      );
    }

    return Container(
      color:
      const Color(
        0xFF111718,
      ),
      child: Center(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal:
            32,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: <Widget>[
              CircleAvatar(
                radius:
                44,
                backgroundColor:
                Colors.white12,
                child: Text(
                  _initialFor(
                    widget.partnerName,
                  ),
                  style:
                  const TextStyle(
                    color:
                    Colors.white,
                    fontSize:
                    32,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(
                height:
                20,
              ),

              Text(
                widget.partnerName,
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  color:
                  Colors.white,
                  fontSize:
                  21,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              const SizedBox(
                height:
                8,
              ),

              Text(
                _snapshot.joined
                    ? 'Waiting for your swap partner to join...'
                    : 'Joining video session...',
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  color:
                  Colors.white70,
                  fontSize:
                  14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOCAL CAMERA PREVIEW
  // ============================================================

  Widget _buildLocalPreview() {
    final RtcEngine? engine =
        _snapshot.engine;

    return Container(
      width:
      112,
      height:
      158,
      clipBehavior:
      Clip.antiAlias,
      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFF1A2223,
        ),
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color:
          Colors.white24,
        ),
        boxShadow:
        const <BoxShadow>[
          BoxShadow(
            color:
            Colors.black45,
            blurRadius:
            16,
            offset:
            Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child:
      _snapshot.cameraOff ||
          engine == null
          ? const Center(
        child: Icon(
          Icons
              .videocam_off_rounded,
          color:
          Colors.white70,
          size:
          30,
        ),
      )
          : AgoraVideoView(
        controller:
        VideoViewController(
          rtcEngine:
          engine,
          canvas:
          const VideoCanvas(
            uid:
            0,
            renderMode:
            RenderModeType
                .renderModeHidden,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Row(
      children: <Widget>[
        _circleButton(
          icon:
          Icons.arrow_back_rounded,
          onPressed:
          _snapshot.leaving
              ? null
              : _leaveCall,
          backgroundColor:
          Colors.black45,
        ),

        const SizedBox(
          width:
          12,
        ),

        Expanded(
          child: Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal:
              14,
              vertical:
              10,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.black45,
              borderRadius:
              BorderRadius.circular(
                18,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width:
                  8,
                  height:
                  8,
                  decoration:
                  BoxDecoration(
                    color:
                    _snapshot
                        .remoteUid !=
                        null
                        ? Colors
                        .greenAccent
                        : Colors
                        .orangeAccent,
                    shape:
                    BoxShape.circle,
                  ),
                ),

                const SizedBox(
                  width:
                  9,
                ),

                Expanded(
                  child: Text(
                    _snapshot
                        .connectionLabel,
                    maxLines:
                    1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      color:
                      Colors.white,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONTROLS
  // ============================================================

  Widget _buildControls() {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        14,
        vertical:
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.black54,
        borderRadius:
        BorderRadius.circular(
          28,
        ),
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _circleButton(
            icon:
            _snapshot.microphoneMuted
                ? Icons.mic_off_rounded
                : Icons.mic_rounded,
            onPressed:
            _snapshot.leaving
                ? null
                : _toggleMicrophone,
            backgroundColor:
            _snapshot.microphoneMuted
                ? Colors.white
                : Colors.white12,
            foregroundColor:
            _snapshot.microphoneMuted
                ? Colors.black
                : Colors.white,
          ),

          _circleButton(
            icon:
            _snapshot.cameraOff
                ? Icons
                .videocam_off_rounded
                : Icons
                .videocam_rounded,
            onPressed:
            _snapshot.leaving
                ? null
                : _toggleCamera,
            backgroundColor:
            _snapshot.cameraOff
                ? Colors.white
                : Colors.white12,
            foregroundColor:
            _snapshot.cameraOff
                ? Colors.black
                : Colors.white,
          ),

          _circleButton(
            icon:
            Icons.cameraswitch_rounded,
            onPressed:
            _snapshot.cameraOff ||
                _snapshot.leaving
                ? null
                : _switchCamera,
            backgroundColor:
            Colors.white12,
          ),

          _circleButton(
            icon:
            Icons.call_end_rounded,
            onPressed:
            _snapshot.leaving
                ? null
                : _leaveCall,
            backgroundColor:
            Colors.red,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CIRCLE BUTTON
  // ============================================================

  Widget _circleButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    Color foregroundColor =
        Colors.white,
  }) {
    return Material(
      color:
      backgroundColor,
      shape:
      const CircleBorder(),
      child: InkWell(
        customBorder:
        const CircleBorder(),
        onTap:
        onPressed,
        child: SizedBox(
          width:
          54,
          height:
          54,
          child: Icon(
            icon,
            color:
            onPressed == null
                ? Colors.white30
                : foregroundColor,
            size:
            26,
          ),
        ),
      ),
    );
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

  // ============================================================
  // INITIAL
  // ============================================================

  String _initialFor(
      String name,
      ) {
    final String trimmed =
    name.trim();

    if (trimmed.isEmpty) {
      return '?';
    }

    return trimmed
        .substring(
      0,
      1,
    )
        .toUpperCase();
  }
}