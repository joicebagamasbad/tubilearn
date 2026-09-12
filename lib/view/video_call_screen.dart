import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/video_call_config.dart';

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
  RtcEngine? _engine;
  RtcEngineEventHandler? _eventHandler;

  int? _remoteUid;

  bool _initializing = true;
  bool _joined = false;
  bool _microphoneMuted = false;
  bool _cameraOff = false;
  bool _leaving = false;

  String? _errorMessage;

  String get _channelName {
    final String? supplied =
    widget.channelName?.trim();

    if (supplied != null &&
        supplied.isNotEmpty) {
      return supplied;
    }

    return VideoCallConfig.agoraChannel;
  }

  String get _token {
    final String? supplied =
    widget.token?.trim();

    if (supplied != null &&
        supplied.isNotEmpty) {
      return supplied;
    }

    return VideoCallConfig.agoraTempToken;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_initializeCall());
  }

  Future<void> _initializeCall() async {
    if (mounted) {
      setState(() {
        _initializing = true;
        _errorMessage = null;
      });
    }

    try {
      if (!VideoCallConfig.isConfigured &&
          (widget.channelName == null ||
              widget.token == null)) {
        throw Exception(
          'Agora video calling is not configured.',
        );
      }

      final Map<Permission, PermissionStatus>
      permissions = await <Permission>[
        Permission.camera,
        Permission.microphone,
      ].request();

      final bool cameraGranted =
          permissions[Permission.camera]
              ?.isGranted ??
              false;

      final bool microphoneGranted =
          permissions[Permission.microphone]
              ?.isGranted ??
              false;

      if (!cameraGranted ||
          !microphoneGranted) {
        throw Exception(
          'Camera and microphone permissions are required for video calls.',
        );
      }

      final RtcEngine engine =
      createAgoraRtcEngine();

      await engine.initialize(
        RtcEngineContext(
          appId:
          VideoCallConfig.agoraAppId,
        ),
      );

      final RtcEngineEventHandler handler =
      RtcEngineEventHandler(
        onError: (
            ErrorCodeType error,
            String message,
            ) {
          if (!mounted) {
            return;
          }

          setState(() {
            _errorMessage =
            message.trim().isEmpty
                ? 'Agora error: $error'
                : message;
          });
        },
        onJoinChannelSuccess: (
            RtcConnection connection,
            int elapsed,
            ) {
          if (!mounted) {
            return;
          }

          setState(() {
            _joined = true;
            _errorMessage = null;
          });
        },
        onUserJoined: (
            RtcConnection connection,
            int remoteUid,
            int elapsed,
            ) {
          if (!mounted) {
            return;
          }

          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (
            RtcConnection connection,
            int remoteUid,
            UserOfflineReasonType reason,
            ) {
          if (!mounted) {
            return;
          }

          if (_remoteUid == remoteUid) {
            setState(() {
              _remoteUid = null;
            });
          }
        },
        onLeaveChannel: (
            RtcConnection connection,
            RtcStats stats,
            ) {
          if (!mounted) {
            return;
          }

          setState(() {
            _joined = false;
            _remoteUid = null;
          });
        },
      );

      engine.registerEventHandler(
        handler,
      );

      await engine.enableAudio();
      await engine.enableVideo();

      await engine.startPreview();

      await engine.joinChannel(
        token: _token,
        channelId: _channelName,
        uid: 0,
        options:
        const ChannelMediaOptions(
          channelProfile:
          ChannelProfileType
              .channelProfileCommunication,
          clientRoleType:
          ClientRoleType
              .clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      if (!mounted) {
        await engine.leaveChannel();
        await engine.release();
        return;
      }

      setState(() {
        _engine = engine;
        _eventHandler = handler;
        _initializing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _initializing = false;
        _errorMessage =
            _friendlyError(error);
      });
    }
  }

  String _friendlyError(
      Object error,
      ) {
    final String raw =
    error.toString();

    if (raw.startsWith(
      'Exception: ',
    )) {
      return raw.substring(
        'Exception: '.length,
      );
    }

    return raw;
  }

  Future<void> _toggleMicrophone() async {
    final RtcEngine? engine =
        _engine;

    if (engine == null) {
      return;
    }

    final bool nextMuted =
    !_microphoneMuted;

    await engine.muteLocalAudioStream(
      nextMuted,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _microphoneMuted = nextMuted;
    });
  }

  Future<void> _toggleCamera() async {
    final RtcEngine? engine =
        _engine;

    if (engine == null) {
      return;
    }

    final bool nextCameraOff =
    !_cameraOff;

    if (nextCameraOff) {
      await engine.stopPreview();

      await engine.enableLocalVideo(
        false,
      );
    } else {
      await engine.enableLocalVideo(
        true,
      );

      await engine.startPreview();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _cameraOff = nextCameraOff;
    });
  }

  Future<void> _switchCamera() async {
    final RtcEngine? engine =
        _engine;

    if (engine == null ||
        _cameraOff) {
      return;
    }

    await engine.switchCamera();
  }

  Future<void> _leaveCall() async {
    if (_leaving) {
      return;
    }

    setState(() {
      _leaving = true;
    });

    final RtcEngine? engine =
        _engine;

    if (engine != null) {
      await engine.leaveChannel();
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _retry() async {
    await _disposeEngine();

    if (!mounted) {
      return;
    }

    setState(() {
      _remoteUid = null;
      _joined = false;
      _microphoneMuted = false;
      _cameraOff = false;
      _leaving = false;
      _errorMessage = null;
    });

    await _initializeCall();
  }

  Future<void> _disposeEngine() async {
    final RtcEngine? engine =
        _engine;

    final RtcEngineEventHandler? handler =
        _eventHandler;

    _engine = null;
    _eventHandler = null;

    if (engine == null) {
      return;
    }

    if (handler != null) {
      engine.unregisterEventHandler(
        handler,
      );
    }

    try {
      await engine.leaveChannel();
    } catch (_) {
      // Ignore cleanup errors.
    }

    try {
      await engine.release();
    } catch (_) {
      // Ignore cleanup errors.
    }
  }

  @override
  void dispose() {
    unawaited(
      _disposeEngine(),
    );

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_initializing) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null &&
        _engine == null) {
      return _buildErrorScreen();
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
              if (_joined)
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

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor:
      Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: const <Widget>[
              CircularProgressIndicator(),
              SizedBox(
                height: 18,
              ),
              Text(
                'Preparing video call...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
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
                  size: 64,
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  'Unable to start video call',
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    color:
                    Colors.white,
                    fontSize: 22,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  _errorMessage ??
                      'Something went wrong.',
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    color:
                    Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                FilledButton.icon(
                  onPressed:
                  _retry,
                  icon: const Icon(
                    Icons
                        .refresh_rounded,
                  ),
                  label:
                  const Text(
                    'Try again',
                  ),
                ),
                const SizedBox(
                  height: 8,
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

  Widget _buildMainVideo() {
    final RtcEngine? engine =
        _engine;

    final int? remoteUid =
        _remoteUid;

    if (engine != null &&
        remoteUid != null) {
      return AgoraVideoView(
        controller:
        VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(
            uid: remoteUid,
            renderMode:
            RenderModeType
                .renderModeHidden,
          ),
          connection:
          RtcConnection(
            channelId:
            _channelName,
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
            horizontal: 32,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: <Widget>[
              CircleAvatar(
                radius: 44,
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
                    fontSize: 32,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                widget.partnerName,
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  color:
                  Colors.white,
                  fontSize: 21,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                _joined
                    ? 'Waiting for your swap partner to join...'
                    : 'Joining video session...',
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  color:
                  Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalPreview() {
    final RtcEngine? engine =
        _engine;

    return Container(
      width: 112,
      height: 158,
      clipBehavior:
      Clip.antiAlias,
      decoration: BoxDecoration(
        color:
        const Color(
          0xFF1A2223,
        ),
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
          Colors.white24,
        ),
        boxShadow:
        const <BoxShadow>[
          BoxShadow(
            color:
            Colors.black45,
            blurRadius: 16,
            offset:
            Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: _cameraOff ||
          engine == null
          ? const Center(
        child: Icon(
          Icons
              .videocam_off_rounded,
          color:
          Colors.white70,
          size: 30,
        ),
      )
          : AgoraVideoView(
        controller:
        VideoViewController(
          rtcEngine:
          engine,
          canvas:
          const VideoCanvas(
            uid: 0,
            renderMode:
            RenderModeType
                .renderModeHidden,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: <Widget>[
        _circleButton(
          icon:
          Icons.arrow_back_rounded,
          onPressed:
          _leaveCall,
          backgroundColor:
          Colors.black45,
        ),
        const SizedBox(
          width: 12,
        ),
        Expanded(
          child: Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
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
                  width: 8,
                  height: 8,
                  decoration:
                  BoxDecoration(
                    color: _remoteUid !=
                        null
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    shape:
                    BoxShape.circle,
                  ),
                ),
                const SizedBox(
                  width: 9,
                ),
                Expanded(
                  child: Text(
                    _remoteUid != null
                        ? 'Connected'
                        : _joined
                        ? 'Waiting for partner'
                        : 'Connecting',
                    maxLines: 1,
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

  Widget _buildControls() {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
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
        MainAxisAlignment
            .spaceEvenly,
        children: <Widget>[
          _circleButton(
            icon: _microphoneMuted
                ? Icons
                .mic_off_rounded
                : Icons.mic_rounded,
            onPressed:
            _toggleMicrophone,
            backgroundColor:
            _microphoneMuted
                ? Colors.white
                : Colors.white12,
            foregroundColor:
            _microphoneMuted
                ? Colors.black
                : Colors.white,
          ),
          _circleButton(
            icon: _cameraOff
                ? Icons
                .videocam_off_rounded
                : Icons
                .videocam_rounded,
            onPressed:
            _toggleCamera,
            backgroundColor:
            _cameraOff
                ? Colors.white
                : Colors.white12,
            foregroundColor:
            _cameraOff
                ? Colors.black
                : Colors.white,
          ),
          _circleButton(
            icon: Icons
                .cameraswitch_rounded,
            onPressed:
            _cameraOff
                ? null
                : _switchCamera,
            backgroundColor:
            Colors.white12,
          ),
          _circleButton(
            icon:
            Icons.call_end_rounded,
            onPressed:
            _leaving
                ? null
                : _leaveCall,
            backgroundColor:
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback?
    onPressed,
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
          width: 54,
          height: 54,
          child: Icon(
            icon,
            color: onPressed == null
                ? Colors.white30
                : foregroundColor,
            size: 26,
          ),
        ),
      ),
    );
  }

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