import 'package:flutter/material.dart';

import '../model/repositories/app_settings_repository.dart';

class AppSettingsService extends ChangeNotifier {
  AppSettingsService._();

  static final AppSettingsService instance =
  AppSettingsService._();

  final AppSettingsRepository _repository =
      AppSettingsRepository.instance;

  AppSettings _settings =
  const AppSettings(
    notificationsEnabled:
    true,
    language:
    AppLanguagePreference.english,
    theme:
    AppThemePreference.system,
  );

  bool _isInitialized = false;
  bool _isLoading = false;

  AppSettings get settings => _settings;

  bool get isInitialized =>
      _isInitialized;

  bool get isLoading =>
      _isLoading;

  bool get notificationsEnabled =>
      _settings.notificationsEnabled;

  AppLanguagePreference get language =>
      _settings.language;

  AppThemePreference get theme =>
      _settings.theme;

  ThemeMode get themeMode {
    switch (_settings.theme) {
      case AppThemePreference.light:
        return ThemeMode.light;

      case AppThemePreference.dark:
        return ThemeMode.dark;

      case AppThemePreference.system:
        return ThemeMode.system;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized ||
        _isLoading) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _settings =
      await _repository.loadSettings();

      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setNotificationsEnabled(
      bool enabled,
      ) async {
    final AppSettings previous =
        _settings;

    _settings =
        _settings.copyWith(
          notificationsEnabled:
          enabled,
        );

    notifyListeners();

    try {
      _settings =
      await _repository
          .setNotificationsEnabled(
        enabled,
      );

      notifyListeners();
    } catch (_) {
      _settings =
          previous;

      notifyListeners();

      rethrow;
    }
  }

  Future<void> setLanguage(
      AppLanguagePreference language,
      ) async {
    final AppSettings previous =
        _settings;

    _settings =
        _settings.copyWith(
          language:
          language,
        );

    notifyListeners();

    try {
      _settings =
      await _repository.setLanguage(
        language,
      );

      notifyListeners();
    } catch (_) {
      _settings =
          previous;

      notifyListeners();

      rethrow;
    }
  }

  Future<void> setTheme(
      AppThemePreference theme,
      ) async {
    final AppSettings previous =
        _settings;

    _settings =
        _settings.copyWith(
          theme:
          theme,
        );

    notifyListeners();

    try {
      _settings =
      await _repository.setTheme(
        theme,
      );

      notifyListeners();
    } catch (_) {
      _settings =
          previous;

      notifyListeners();

      rethrow;
    }
  }
}
