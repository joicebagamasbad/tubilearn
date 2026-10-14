// ============================================================
// THEME PREFERENCE
// ============================================================

enum AppThemePreference {
  system,
  light,
  dark,
}

// ============================================================
// LANGUAGE PREFERENCE
// ============================================================

enum AppLanguagePreference {
  english,
  filipino,
}

// ============================================================
// APP SETTINGS MODEL
// ============================================================

class AppSettings {
  final bool notificationsEnabled;

  final AppLanguagePreference language;

  final AppThemePreference theme;

  final bool onboardingSeen;

  const AppSettings({
    required this.notificationsEnabled,
    required this.language,
    required this.theme,
    this.onboardingSeen = false,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    AppLanguagePreference? language,
    AppThemePreference? theme,
    bool? onboardingSeen,
  }) {
    return AppSettings(
      notificationsEnabled:
      notificationsEnabled ??
          this.notificationsEnabled,
      language:
      language ??
          this.language,
      theme:
      theme ??
          this.theme,
      onboardingSeen:
      onboardingSeen ??
          this.onboardingSeen,
    );
  }
}