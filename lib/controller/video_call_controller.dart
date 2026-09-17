import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

import '../services/video_call_config.dart';
import '../services/video_call_service.dart';

// ============================================================
// EXCEPTION
// ============================================================

class VideoCallControllerException
    implements Exception {
  final String message;

  const VideoCallControllerException(
      this.message,
      );

  @override
  String toString() => message;
}

// ============================================================
// SNAPSHOT
// ============================================================

class VideoCallSnapshot {
  final RtcEngine? engine;
  final int? remoteUid;

  final String channelName;

  final bool initializing;
  final bool joined;

  final bool microphoneMuted;
  final bool cameraOff;

  final bool leaving;

  final String? errorMessage;

  const VideoCallSnapshot({
    required this.engine,
    required this.remoteUid,
    required this.channelName,
    required this.initializing,
    required this.joined,
    required this.microphoneMuted,
    required this.cameraOff,
    required this.leaving,
    required this.errorMessage,
  });

  bool get hasRemoteUser =>
      remoteUid != null;

  bool get callReady =>
      engine != null;

  bool get hasFatalError =>
      !initializing &&
          engine == null &&
          errorMessage != null;

  String get connectionLabel {
    if (remoteUid != null) {
      return 'Connected';
    }

    if (joined) {
      return 'Waiting for partner';
    }

    return 'Connecting';
  }
}

// ============================================================
// CONTROLLER
// ============================================================

class VideoCallController
    extends ChangeNotifier {
  final VideoCallService _service;

  final bool _ownsService;

  String? _controllerError;

  bool _disposed = false;

  VideoCallController({
    VideoCallService? service,
  })  : _service =
      service ??
          VideoCallService(),
        _ownsService =
            service == null {
    _service.addListener(
      _handleServiceChanged,
    );
  }

  VideoCallSnapshot get snapshot {
    final VideoCallServiceState state =
        _service.state;

    return VideoCallSnapshot(
      engine:
      state.engine,
      remoteUid:
      state.remoteUid,
      channelName:
      _service.channelName,
      initializing:
      state.initializing,
      joined:
      state.joined,
      microphoneMuted:
      state.microphoneMuted,
      cameraOff:
      state.cameraOff,
      leaving:
      state.leaving,
      errorMessage:
      _controllerError ??
          state.errorMessage,
    );
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize({
    String? channelName,
    String? token,
  }) async {
    _controllerError =
    null;

    _notifySafely();

    try {
      final String resolvedChannel =
      _resolveChannelName(
        channelName,
      );

      final String resolvedToken =
      _resolveToken(
        token,
      );

      await _service.initialize(
        channelName:
        resolvedChannel,
        token:
        resolvedToken,
      );

      _controllerError =
      null;

      _notifySafely();
    } on VideoCallControllerException {
      rethrow;
    } on VideoCallServiceException catch (error) {
      _controllerError =
          error.message;

      _notifySafely();

      throw VideoCallControllerException(
        error.message,
      );
    } catch (_) {
      const String message =
          'Video call could not be started. Please try again.';

      _controllerError =
          message;

      _notifySafely();

      throw const VideoCallControllerException(
        message,
      );
    }
  }

  // ============================================================
  // MICROPHONE
  // ============================================================

  Future<void> toggleMicrophone() async {
    try {
      await _service.toggleMicrophone();
    } on VideoCallServiceException catch (error) {
      throw VideoCallControllerException(
        error.message,
      );
    } catch (_) {
      throw const VideoCallControllerException(
        'Microphone could not be updated.',
      );
    }
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void> toggleCamera() async {
    try {
      await _service.toggleCamera();
    } on VideoCallServiceException catch (error) {
      throw VideoCallControllerException(
        error.message,
      );
    } catch (_) {
      throw const VideoCallControllerException(
        'Camera could not be updated.',
      );
    }
  }

  // ============================================================
  // SWITCH CAMERA
  // ============================================================

  Future<void> switchCamera() async {
    try {
      await _service.switchCamera();
    } on VideoCallServiceException catch (error) {
      throw VideoCallControllerException(
        error.message,
      );
    } catch (_) {
      throw const VideoCallControllerException(
        'Camera could not be switched.',
      );
    }
  }

  // ============================================================
  // LEAVE
  // ============================================================

  Future<void> leaveCall() async {
    try {
      await _service.leaveCall();
    } on VideoCallServiceException catch (error) {
      throw VideoCallControllerException(
        error.message,
      );
    } catch (_) {
      throw const VideoCallControllerException(
        'Video call could not be closed normally.',
      );
    }
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<void> retry() async {
    _controllerError =
    null;

    _notifySafely();

    try {
      await _service.retry();

      _controllerError =
      null;

      _notifySafely();
    } on VideoCallServiceException catch (error) {
      _controllerError =
          error.message;

      _notifySafely();

      throw VideoCallControllerException(
        error.message,
      );
    } catch (_) {
      const String message =
          'Video call could not be restarted. Please try again.';

      _controllerError =
          message;

      _notifySafely();

      throw const VideoCallControllerException(
        message,
      );
    }
  }

  // ============================================================
  // CLOSE
  // ============================================================

  Future<void> close() async {
    try {
      await _service.close();
    } catch (_) {
      // Cleanup failure should not block navigation.
    }
  }

  // ============================================================
  // CONFIG
  // ============================================================

  String _resolveChannelName(
      String? supplied,
      ) {
    final String cleanSupplied =
        supplied?.trim() ??
            '';

    if (cleanSupplied.isNotEmpty) {
      return cleanSupplied;
    }

    final String configured =
    VideoCallConfig.agoraChannel
        .trim();

    if (configured.isEmpty) {
      throw const VideoCallControllerException(
        'Video call channel is unavailable.',
      );
    }

    return configured;
  }

  String _resolveToken(
      String? supplied,
      ) {
    final String cleanSupplied =
        supplied?.trim() ??
            '';

    if (cleanSupplied.isNotEmpty) {
      return cleanSupplied;
    }

    final String configured =
    VideoCallConfig.agoraTempToken
        .trim();

    if (configured.isEmpty) {
      throw const VideoCallControllerException(
        'Video call token is unavailable.',
      );
    }

    return configured;
  }

  // ============================================================
  // LISTENER
  // ============================================================

  void _handleServiceChanged() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  void _notifySafely() {
    if (_disposed) {
      return;
    }

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

    _disposed =
    true;

    _service.removeListener(
      _handleServiceChanged,
    );

    if (_ownsService) {
      _service.dispose();
    }

    super.dispose();
  }
}