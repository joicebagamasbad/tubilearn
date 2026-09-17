import '../model/app_settings.dart';
import '../services/app_settings_service.dart';

class SettingsControllerException
    implements Exception {
  final String message;

  const SettingsControllerException(
      this.message,
      );

  @override
  String toString() => message;
}

// ============================================================
// SNAPSHOT
// ============================================================

class SettingsSnapshot {
  final bool notificationsEnabled;

  final AppLanguagePreference language;

  final AppThemePreference theme;

  const SettingsSnapshot({
    required this.notificationsEnabled,
    required this.language,
    required this.theme,
  });
}

// ============================================================
// CONTROLLER
// ============================================================

class SettingsController {
  final AppSettingsService _settingsService;

  SettingsController({
    AppSettingsService? settingsService,
  }) : _settingsService =
      settingsService ??
          AppSettingsService.instance;

  // ============================================================
  // LOAD
  // ============================================================

  Future<SettingsSnapshot>
  loadSettings() async {
    try {
      await _settingsService.initialize();

      return _buildSnapshot();
    } catch (_) {
      throw const SettingsControllerException(
        'Could not load settings.',
      );
    }
  }

  // ============================================================
  // CURRENT
  // ============================================================

  SettingsSnapshot currentSnapshot() {
    try {
      return _buildSnapshot();
    } catch (_) {
      throw const SettingsControllerException(
        'Settings could not be prepared.',
      );
    }
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<SettingsSnapshot>
  setNotificationsEnabled(
      bool enabled,
      ) async {
    try {
      await _settingsService
          .setNotificationsEnabled(
        enabled,
      );

      return _buildSnapshot();
    } catch (_) {
      throw const SettingsControllerException(
        'Could not save notification preference.',
      );
    }
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  Future<SettingsSnapshot> setLanguage(
      AppLanguagePreference language,
      ) async {
    try {
      await _settingsService.setLanguage(
        language,
      );

      return _buildSnapshot();
    } catch (_) {
      throw const SettingsControllerException(
        'Could not save language preference.',
      );
    }
  }

  // ============================================================
  // THEME
  // ============================================================

  Future<SettingsSnapshot> setTheme(
      AppThemePreference theme,
      ) async {
    try {
      await _settingsService.setTheme(
        theme,
      );

      return _buildSnapshot();
    } catch (_) {
      throw const SettingsControllerException(
        'Could not save appearance preference.',
      );
    }
  }

  // ============================================================
  // SNAPSHOT
  // ============================================================

  SettingsSnapshot _buildSnapshot() {
    return SettingsSnapshot(
      notificationsEnabled:
      _settingsService.notificationsEnabled,
      language:
      _settingsService.language,
      theme:
      _settingsService.theme,
    );
  }
}