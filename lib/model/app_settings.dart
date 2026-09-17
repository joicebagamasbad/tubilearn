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

  const AppSettings({
    required this.notificationsEnabled,
    required this.language,
    required this.theme,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    AppLanguagePreference? language,
    AppThemePreference? theme,
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
    );
  }
}