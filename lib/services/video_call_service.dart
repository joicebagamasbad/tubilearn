import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'video_call_config.dart';

// ============================================================
// EXCEPTION
// ============================================================

class VideoCallServiceException
    implements Exception {
  final String message;

  const VideoCallServiceException(
      this.message,
      );

  @override
  String toString() => message;
}

// ============================================================
// STATE
// ============================================================

class VideoCallServiceState {
  final RtcEngine? engine;
  final int? remoteUid;

  final bool initializing;
  final bool joined;

  final bool microphoneMuted;
  final bool cameraOff;

  final bool leaving;

  final String? errorMessage;

  const VideoCallServiceState({
    required this.engine,
    required this.remoteUid,
    required this.initializing,
    required this.joined,
    required this.microphoneMuted,
    required this.cameraOff,
    required this.leaving,
    required this.errorMessage,
  });

  const VideoCallServiceState.initial()
      : engine = null,
        remoteUid = null,
        initializing = false,
        joined = false,
        microphoneMuted = false,
        cameraOff = false,
        leaving = false,
        errorMessage = null;

  VideoCallServiceState copyWith({
    RtcEngine? engine,
    bool clearEngine = false,
    int? remoteUid,
    bool clearRemoteUid = false,
    bool? initializing,
    bool? joined,
    bool? microphoneMuted,
    bool? cameraOff,
    bool? leaving,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return VideoCallServiceState(
      engine: clearEngine
          ? null
          : engine ?? this.engine,
      remoteUid: clearRemoteUid
          ? null
          : remoteUid ?? this.remoteUid,
      initializing:
      initializing ?? this.initializing,
      joined:
      joined ?? this.joined,
      microphoneMuted:
      microphoneMuted ?? this.microphoneMuted,
      cameraOff:
      cameraOff ?? this.cameraOff,
      leaving:
      leaving ?? this.leaving,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

// ============================================================
// SERVICE
// ============================================================

class VideoCallService extends ChangeNotifier {
  VideoCallService();

  VideoCallServiceState _state =
  const VideoCallServiceState.initial();

  RtcEngineEventHandler? _eventHandler;

  String _channelName = '';
  String _token = '';

  bool _disposed = false;

  VideoCallServiceState get state =>
      _state;

  RtcEngine? get engine =>
      _state.engine;

  int? get remoteUid =>
      _state.remoteUid;

  bool get joined =>
      _state.joined;

  bool get microphoneMuted =>
      _state.microphoneMuted;

  bool get cameraOff =>
      _state.cameraOff;

  bool get leaving =>
      _state.leaving;

  String? get errorMessage =>
      _state.errorMessage;

  String get channelName =>
      _channelName;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize({
    required String channelName,
    required String token,
  }) async {
    if (_state.initializing) {
      return;
    }

    await _disposeEngine();

    final String cleanChannelName =
    channelName.trim();

    final String cleanToken =
    token.trim();

    if (cleanChannelName.isEmpty) {
      throw const VideoCallServiceException(
        'Video call channel is unavailable.',
      );
    }

    if (cleanToken.isEmpty) {
      throw const VideoCallServiceException(
        'Video call token is unavailable.',
      );
    }

    if (VideoCallConfig.agoraAppId
        .trim()
        .isEmpty) {
      throw const VideoCallServiceException(
        'Agora video calling is not configured.',
      );
    }

    _channelName =
        cleanChannelName;

    _token =
        cleanToken;

    _setState(
      _state.copyWith(
        initializing: true,
        joined: false,
        microphoneMuted: false,
        cameraOff: false,
        leaving: false,
        clearRemoteUid: true,
        clearErrorMessage: true,
      ),
    );

    RtcEngine? createdEngine;

    try {
      await _requestPermissions();

      final RtcEngine engine =
      createAgoraRtcEngine();

      createdEngine =
          engine;

      await engine.initialize(
        RtcEngineContext(
          appId:
          VideoCallConfig.agoraAppId,
        ),
      );

      final RtcEngineEventHandler handler =
      _buildEventHandler();

      _eventHandler =
          handler;

      engine.registerEventHandler(
        handler,
      );

      await engine.enableAudio();

      await engine.enableVideo();

      await engine.startPreview();

      await engine.joinChannel(
        token:
        _token,
        channelId:
        _channelName,
        uid:
        0,
        options:
        const ChannelMediaOptions(
          channelProfile:
          ChannelProfileType
              .channelProfileCommunication,
          clientRoleType:
          ClientRoleType
              .clientRoleBroadcaster,
          publishCameraTrack:
          true,
          publishMicrophoneTrack:
          true,
          autoSubscribeAudio:
          true,
          autoSubscribeVideo:
          true,
        ),
      );

      if (_disposed) {
        await _releaseEngine(
          engine,
          handler:
          handler,
        );

        return;
      }

      _setState(
        _state.copyWith(
          engine:
          engine,
          initializing:
          false,
          leaving:
          false,
          clearErrorMessage:
          true,
        ),
      );
    } on VideoCallServiceException catch (
    error
    ) {
      if (createdEngine != null) {
        await _releaseEngine(
          createdEngine,
          handler:
          _eventHandler,
        );
      }

      _eventHandler =
      null;

      _setState(
        _state.copyWith(
          initializing:
          false,
          joined:
          false,
          leaving:
          false,
          clearEngine:
          true,
          clearRemoteUid:
          true,
          errorMessage:
          error.message,
        ),
      );

      rethrow;
    } catch (error) {
      if (createdEngine != null) {
        await _releaseEngine(
          createdEngine,
          handler:
          _eventHandler,
        );
      }

      _eventHandler =
      null;

      final String message =
      _friendlyError(
        error,
      );

      _setState(
        _state.copyWith(
          initializing:
          false,
          joined:
          false,
          leaving:
          false,
          clearEngine:
          true,
          clearRemoteUid:
          true,
          errorMessage:
          message,
        ),
      );

      throw VideoCallServiceException(
        message,
      );
    }
  }

  // ============================================================
  // PERMISSIONS
  // ============================================================

  Future<void> _requestPermissions() async {
    final Map<Permission, PermissionStatus>
    permissions =
    await <Permission>[
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
      throw const VideoCallServiceException(
        'Camera and microphone permissions are required for video calls.',
      );
    }
  }

  // ============================================================
  // EVENT HANDLER
  // ============================================================

  RtcEngineEventHandler _buildEventHandler() {
    return RtcEngineEventHandler(
      onError: (
          ErrorCodeType error,
          String message,
          ) {
        if (_disposed) {
          return;
        }

        final String cleanMessage =
        message.trim();

        _setState(
          _state.copyWith(
            errorMessage:
            cleanMessage.isEmpty
                ? 'Agora error: $error'
                : cleanMessage,
          ),
        );
      },
      onJoinChannelSuccess: (
          RtcConnection connection,
          int elapsed,
          ) {
        if (_disposed) {
          return;
        }

        _setState(
          _state.copyWith(
            joined:
            true,
            initializing:
            false,
            clearErrorMessage:
            true,
          ),
        );
      },
      onUserJoined: (
          RtcConnection connection,
          int remoteUid,
          int elapsed,
          ) {
        if (_disposed) {
          return;
        }

        _setState(
          _state.copyWith(
            remoteUid:
            remoteUid,
          ),
        );
      },
      onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
          ) {
        if (_disposed) {
          return;
        }

        if (_state.remoteUid !=
            remoteUid) {
          return;
        }

        _setState(
          _state.copyWith(
            clearRemoteUid:
            true,
          ),
        );
      },
      onLeaveChannel: (
          RtcConnection connection,
          RtcStats stats,
          ) {
        if (_disposed) {
          return;
        }

        _setState(
          _state.copyWith(
            joined:
            false,
            clearRemoteUid:
            true,
          ),
        );
      },
    );
  }

  // ============================================================
  // MICROPHONE
  // ============================================================

  Future<void> toggleMicrophone() async {
    final RtcEngine? engine =
        _state.engine;

    if (engine == null) {
      throw const VideoCallServiceException(
        'Video call is not ready yet.',
      );
    }

    final bool nextMuted =
    !_state.microphoneMuted;

    try {
      await engine.muteLocalAudioStream(
        nextMuted,
      );

      _setState(
        _state.copyWith(
          microphoneMuted:
          nextMuted,
        ),
      );
    } catch (_) {
      throw const VideoCallServiceException(
        'Microphone could not be updated.',
      );
    }
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void> toggleCamera() async {
    final RtcEngine? engine =
        _state.engine;

    if (engine == null) {
      throw const VideoCallServiceException(
        'Video call is not ready yet.',
      );
    }

    final bool nextCameraOff =
    !_state.cameraOff;

    try {
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

      _setState(
        _state.copyWith(
          cameraOff:
          nextCameraOff,
        ),
      );
    } catch (_) {
      throw const VideoCallServiceException(
        'Camera could not be updated.',
      );
    }
  }

  // ============================================================
  // SWITCH CAMERA
  // ============================================================

  Future<void> switchCamera() async {
    final RtcEngine? engine =
        _state.engine;

    if (engine == null) {
      throw const VideoCallServiceException(
        'Video call is not ready yet.',
      );
    }

    if (_state.cameraOff) {
      throw const VideoCallServiceException(
        'Turn your camera on before switching cameras.',
      );
    }

    try {
      await engine.switchCamera();
    } catch (_) {
      throw const VideoCallServiceException(
        'Camera could not be switched.',
      );
    }
  }

  // ============================================================
  // LEAVE
  // ============================================================

  Future<void> leaveCall() async {
    if (_state.leaving) {
      return;
    }

    _setState(
      _state.copyWith(
        leaving:
        true,
      ),
    );

    final RtcEngine? engine =
        _state.engine;

    if (engine != null) {
      try {
        await engine.leaveChannel();
      } catch (_) {
        // Continue cleanup even if Agora leave fails.
      }
    }

    _setState(
      _state.copyWith(
        joined:
        false,
        clearRemoteUid:
        true,
      ),
    );
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<void> retry() async {
    final String channelName =
        _channelName;

    final String token =
        _token;

    if (channelName.isEmpty ||
        token.isEmpty) {
      throw const VideoCallServiceException(
        'Video call details are unavailable.',
      );
    }

    await initialize(
      channelName:
      channelName,
      token:
      token,
    );
  }

  // ============================================================
  // CLOSE
  // ============================================================

  Future<void> close() async {
    await _disposeEngine();

    _channelName = '';
    _token = '';

    _setState(
      const VideoCallServiceState.initial(),
    );
  }

  // ============================================================
  // ENGINE CLEANUP
  // ============================================================

  Future<void> _disposeEngine() async {
    final RtcEngine? engine =
        _state.engine;

    final RtcEngineEventHandler? handler =
        _eventHandler;

    _eventHandler =
    null;

    _state =
        _state.copyWith(
          clearEngine:
          true,
          joined:
          false,
          leaving:
          false,
          clearRemoteUid:
          true,
        );

    if (engine == null) {
      return;
    }

    await _releaseEngine(
      engine,
      handler:
      handler,
    );
  }

  Future<void> _releaseEngine(
      RtcEngine engine, {
        RtcEngineEventHandler? handler,
      }) async {
    if (handler != null) {
      try {
        engine.unregisterEventHandler(
          handler,
        );
      } catch (_) {
        // Ignore handler cleanup errors.
      }
    }

    try {
      await engine.leaveChannel();
    } catch (_) {
      // Ignore leave cleanup errors.
    }

    try {
      await engine.release();
    } catch (_) {
      // Ignore release cleanup errors.
    }
  }

  // ============================================================
  // ERROR TEXT
  // ============================================================

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

  // ============================================================
  // STATE
  // ============================================================

  void _setState(
      VideoCallServiceState nextState,
      ) {
    if (_disposed) {
      return;
    }

    _state =
        nextState;

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    final RtcEngine? engine =
        _state.engine;

    final RtcEngineEventHandler? handler =
        _eventHandler;

    _disposed =
    true;

    _eventHandler =
    null;

    if (engine != null) {
      unawaited(
        _releaseEngine(
          engine,
          handler:
          handler,
        ),
      );
    }

    super.dispose();
  }
}