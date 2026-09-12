class VideoCallConfig {
  VideoCallConfig._();

  static const String agoraAppId =
  String.fromEnvironment(
    'AGORA_APP_ID',
  );

  static const String agoraTempToken =
  String.fromEnvironment(
    'AGORA_TEMP_TOKEN',
  );

  static const String agoraChannel =
  String.fromEnvironment(
    'AGORA_CHANNEL',
    defaultValue:
    'tubilearn_test_room',
  );

  static bool get isConfigured =>
      agoraAppId.trim().isNotEmpty &&
          agoraTempToken.trim().isNotEmpty &&
          agoraChannel.trim().isNotEmpty;
}