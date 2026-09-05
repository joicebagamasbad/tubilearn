import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

class AppSettingsRepositoryException implements Exception {
  final String message;

  const AppSettingsRepositoryException(
      this.message,
      );

  @override
  String toString() => message;
}

enum AppThemePreference {
  system,
  light,
  dark,
}

enum AppLanguagePreference {
  english,
  filipino,
}

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

class AppSettingsRepository {
  AppSettingsRepository._();

  static final AppSettingsRepository instance =
  AppSettingsRepository._();

  static const String _notificationsKey =
      'notifications_enabled';

  static const String _languageKey =
      'language';

  static const String _themeKey =
      'theme';

  static const AppSettings _defaults =
  AppSettings(
    notificationsEnabled:
    true,
    language:
    AppLanguagePreference.english,
    theme:
    AppThemePreference.system,
  );

  Future<AppSettings> loadSettings() async {
    try {
      final Database db =
      await AppDatabase.instance.database;

      await _ensureSettingsTable(
        db,
      );

      final List<Map<String, Object?>> rows =
      await db.query(
        'app_settings',
        columns:
        const <String>[
          'setting_key',
          'setting_value',
        ],
      );

      final Map<String, String> values =
      <String, String>{};

      for (final Map<String, Object?> row
      in rows) {
        final Object? rawKey =
        row['setting_key'];

        final Object? rawValue =
        row['setting_value'];

        if (rawKey is! String ||
            rawValue is! String) {
          continue;
        }

        final String key =
        rawKey.trim();

        if (key.isEmpty) {
          continue;
        }

        values[key] =
            rawValue.trim();
      }

      return AppSettings(
        notificationsEnabled:
        _parseBoolean(
          values[_notificationsKey],
          fallback:
          _defaults.notificationsEnabled,
        ),
        language:
        _parseLanguage(
          values[_languageKey],
        ),
        theme:
        _parseTheme(
          values[_themeKey],
        ),
      );
    } on DatabaseException {
      throw const AppSettingsRepositoryException(
        'Could not load app settings.',
      );
    } catch (_) {
      throw const AppSettingsRepositoryException(
        'Could not load app settings.',
      );
    }
  }

  Future<AppSettings> setNotificationsEnabled(
      bool enabled,
      ) async {
    await _saveSetting(
      key:
      _notificationsKey,
      value:
      enabled
          ? '1'
          : '0',
    );

    return loadSettings();
  }

  Future<AppSettings> setLanguage(
      AppLanguagePreference language,
      ) async {
    await _saveSetting(
      key:
      _languageKey,
      value:
      language.name,
    );

    return loadSettings();
  }

  Future<AppSettings> setTheme(
      AppThemePreference theme,
      ) async {
    await _saveSetting(
      key:
      _themeKey,
      value:
      theme.name,
    );

    return loadSettings();
  }

  Future<void> _saveSetting({
    required String key,
    required String value,
  }) async {
    final String cleanKey =
    key.trim();

    final String cleanValue =
    value.trim();

    if (cleanKey.isEmpty) {
      throw const AppSettingsRepositoryException(
        'Setting key is required.',
      );
    }

    try {
      final Database db =
      await AppDatabase.instance.database;

      await _ensureSettingsTable(
        db,
      );

      await db.insert(
        'app_settings',
        <String, Object?>{
          'setting_key':
          cleanKey,
          'setting_value':
          cleanValue,
        },
        conflictAlgorithm:
        ConflictAlgorithm.replace,
      );
    } on DatabaseException {
      throw const AppSettingsRepositoryException(
        'Could not save app settings.',
      );
    } catch (_) {
      throw const AppSettingsRepositoryException(
        'Could not save app settings.',
      );
    }
  }

  Future<void> _ensureSettingsTable(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE TABLE IF NOT EXISTS app_settings (
        setting_key TEXT PRIMARY KEY NOT NULL,
        setting_value TEXT NOT NULL
      )
      ''',
    );
  }

  bool _parseBoolean(
      String? value, {
        required bool fallback,
      }) {
    if (value == '1') {
      return true;
    }

    if (value == '0') {
      return false;
    }

    return fallback;
  }

  AppLanguagePreference _parseLanguage(
      String? value,
      ) {
    switch (value) {
      case 'filipino':
        return AppLanguagePreference.filipino;

      case 'english':
        return AppLanguagePreference.english;

      default:
        return _defaults.language;
    }
  }

  AppThemePreference _parseTheme(
      String? value,
      ) {
    switch (value) {
      case 'light':
        return AppThemePreference.light;

      case 'dark':
        return AppThemePreference.dark;

      case 'system':
        return AppThemePreference.system;

      default:
        return _defaults.theme;
    }
  }
}