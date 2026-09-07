import 'package:flutter/material.dart';

import '../model/repositories/app_settings_repository.dart';
import '../services/app_settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  final AppSettingsService _settingsService =
      AppSettingsService.instance;

  bool _isLoading = true;
  bool _isSavingNotifications = false;
  bool _isSavingLanguage = false;
  bool _isSavingTheme = false;

  String? _errorMessage;

  bool get _isDarkMode =>
      Theme.of(context).brightness ==
          Brightness.dark;

  Color get _primaryColor =>
      Theme.of(context).colorScheme.primary;

  Color get _surfaceColor =>
      Theme.of(context).colorScheme.surface;

  Color get _textColor =>
      Theme.of(context).colorScheme.onSurface;

  Color get _mutedColor =>
      Theme.of(context)
          .colorScheme
          .onSurfaceVariant;

  Color get _borderColor =>
      Theme.of(context)
          .colorScheme
          .outlineVariant;

  Color get _softPrimaryColor =>
      _isDarkMode
          ? _primaryColor.withValues(
        alpha: 0.14,
      )
          : _primaryColor.withValues(
        alpha: 0.07,
      );

  @override
  void initState() {
    super.initState();

    _loadSettings();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadSettings() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await _settingsService.initialize();

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
        'Could not load settings.';
      });
    }
  }

  // ============================================================
  // NOTIFICATION PREFERENCE
  // ============================================================

  Future<void> _toggleNotifications(
      bool enabled,
      ) async {
    if (_isSavingNotifications) {
      return;
    }

    setState(() {
      _isSavingNotifications = true;
    });

    try {
      await _settingsService
          .setNotificationsEnabled(
        enabled,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingNotifications = false;
      });

      _showMessage(
        enabled
            ? 'Notification preference saved as On.'
            : 'Notification preference saved as Off.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingNotifications = false;
      });

      _showMessage(
        'Could not save notification preference.',
      );
    }
  }

  String _notificationSubtitle() {
    if (_settingsService.notificationsEnabled) {
      return 'Preferred on • real alerts are not active yet';
    }

    return 'Preferred off • saved locally';
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  Future<void> _showLanguagePicker() async {
    if (_isSavingLanguage) {
      return;
    }

    final AppLanguagePreference current =
        _settingsService.language;

    final AppLanguagePreference? selected =
    await showModalBottomSheet<
        AppLanguagePreference>(
      context: context,
      backgroundColor: _surfaceColor,
      showDragHandle: true,
      builder: (
          BuildContext sheetContext,
          ) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Language preference',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textColor,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Choose the language you want TubiLearn to use when localization is connected.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: _mutedColor,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                RadioGroup<
                    AppLanguagePreference>(
                  groupValue: current,
                  onChanged: (
                      AppLanguagePreference? value,
                      ) {
                    if (value == null) {
                      return;
                    }

                    Navigator.of(
                      sheetContext,
                    ).pop(
                      value,
                    );
                  },
                  child: Column(
                    children: <Widget>[
                      RadioListTile<
                          AppLanguagePreference>(
                        contentPadding:
                        EdgeInsets.zero,
                        title: Text(
                          'English',
                          style: TextStyle(
                            color: _textColor,
                          ),
                        ),
                        subtitle: Text(
                          'Save English as your preferred app language.',
                          style: TextStyle(
                            color: _mutedColor,
                          ),
                        ),
                        value:
                        AppLanguagePreference
                            .english,
                      ),

                      RadioListTile<
                          AppLanguagePreference>(
                        contentPadding:
                        EdgeInsets.zero,
                        title: Text(
                          'Filipino',
                          style: TextStyle(
                            color: _textColor,
                          ),
                        ),
                        subtitle: Text(
                          'Save Filipino as your preferred app language.',
                          style: TextStyle(
                            color: _mutedColor,
                          ),
                        ),
                        value:
                        AppLanguagePreference
                            .filipino,
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                _buildDevelopmentNotice(
                  icon: Icons.translate_rounded,
                  text:
                  'This setting is saved locally. Full English/Filipino text translation is part of the later localization phase.',
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null ||
        selected ==
            _settingsService.language) {
      return;
    }

    setState(() {
      _isSavingLanguage = true;
    });

    try {
      await _settingsService.setLanguage(
        selected,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingLanguage = false;
      });

      _showMessage(
        'Language preference saved.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingLanguage = false;
      });

      _showMessage(
        'Could not save language preference.',
      );
    }
  }

  // ============================================================
  // THEME
  // ============================================================

  Future<void> _showThemePicker() async {
    if (_isSavingTheme) {
      return;
    }

    final AppThemePreference current =
        _settingsService.theme;

    final AppThemePreference? selected =
    await showModalBottomSheet<
        AppThemePreference>(
      context: context,
      backgroundColor: _surfaceColor,
      showDragHandle: true,
      builder: (
          BuildContext sheetContext,
          ) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textColor,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Choose how TubiLearn should look on this device.',
                  style: TextStyle(
                    fontSize: 14,
                    color: _mutedColor,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                RadioGroup<AppThemePreference>(
                  groupValue: current,
                  onChanged: (
                      AppThemePreference? value,
                      ) {
                    if (value == null) {
                      return;
                    }

                    Navigator.of(
                      sheetContext,
                    ).pop(
                      value,
                    );
                  },
                  child: Column(
                    children: <Widget>[
                      RadioListTile<
                          AppThemePreference>(
                        contentPadding:
                        EdgeInsets.zero,
                        title: Text(
                          'System',
                          style: TextStyle(
                            color: _textColor,
                          ),
                        ),
                        subtitle: Text(
                          'Follow your device appearance.',
                          style: TextStyle(
                            color: _mutedColor,
                          ),
                        ),
                        value:
                        AppThemePreference
                            .system,
                      ),

                      RadioListTile<
                          AppThemePreference>(
                        contentPadding:
                        EdgeInsets.zero,
                        title: Text(
                          'Light',
                          style: TextStyle(
                            color: _textColor,
                          ),
                        ),
                        subtitle: Text(
                          'Always use light mode.',
                          style: TextStyle(
                            color: _mutedColor,
                          ),
                        ),
                        value:
                        AppThemePreference
                            .light,
                      ),

                      RadioListTile<
                          AppThemePreference>(
                        contentPadding:
                        EdgeInsets.zero,
                        title: Text(
                          'Dark',
                          style: TextStyle(
                            color: _textColor,
                          ),
                        ),
                        subtitle: Text(
                          'Always use dark mode.',
                          style: TextStyle(
                            color: _mutedColor,
                          ),
                        ),
                        value:
                        AppThemePreference
                            .dark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null ||
        selected ==
            _settingsService.theme) {
      return;
    }

    setState(() {
      _isSavingTheme = true;
    });

    try {
      await _settingsService.setTheme(
        selected,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingTheme = false;
      });

      _showMessage(
        'Appearance updated.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingTheme = false;
      });

      _showMessage(
        'Could not save appearance preference.',
      );
    }
  }

  // ============================================================
  // ABOUT
  // ============================================================

  void _showAboutDialog() {
    showDialog<void>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          title: Text(
            'About TubiLearn',
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'TubiLearn is a skill exchange platform designed to help people teach what they know and learn new skills from others.',
            style: TextStyle(
              color: _mutedColor,
              height: 1.45,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'CLOSE',
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyDialog() {
    showDialog<void>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          title: Text(
            'Privacy',
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'This local version of TubiLearn stores prototype data on this device. A full privacy policy and secure backend data handling will be required before production release.',
            style: TextStyle(
              color: _mutedColor,
              height: 1.45,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'CLOSE',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LABELS
  // ============================================================

  String _languageLabel() {
    switch (_settingsService.language) {
      case AppLanguagePreference.english:
        return 'English';

      case AppLanguagePreference.filipino:
        return 'Filipino';
    }
  }

  String _themeLabel() {
    switch (_settingsService.theme) {
      case AppThemePreference.system:
        return 'System';

      case AppThemePreference.light:
        return 'Light';

      case AppThemePreference.dark:
        return 'Dark';
    }
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
          content: Text(
            message,
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      Theme.of(context)
          .scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
        Theme.of(context)
            .scaffoldBackgroundColor,
        surfaceTintColor:
        Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: _primaryColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: _mutedColor,
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                _errorMessage!,
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color: _textColor,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              ElevatedButton(
                onPressed: _loadSettings,
                child: const Text(
                  'RETRY',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _settingsService,
      builder: (
          BuildContext context,
          Widget? child,
          ) {
        return ListView(
          physics:
          const BouncingScrollPhysics(),
          padding:
          const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            32,
          ),
          children: <Widget>[
            _sectionTitle(
              'APP PREFERENCES',
            ),

            const SizedBox(
              height: 8,
            ),

            _settingsCard(
              children: <Widget>[
                SwitchListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  secondary: Icon(
                    Icons
                        .notifications_outlined,
                    color: _primaryColor,
                  ),
                  title: Text(
                    'Notification preference',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w700,
                      color: _textColor,
                    ),
                  ),
                  subtitle: Text(
                    _notificationSubtitle(),
                    style: TextStyle(
                      color: _mutedColor,
                    ),
                  ),
                  value:
                  _settingsService
                      .notificationsEnabled,
                  onChanged:
                  _isSavingNotifications
                      ? null
                      : _toggleNotifications,
                ),

                const Divider(
                  height: 1,
                ),

                ListTile(
                  leading: Icon(
                    Icons.language_rounded,
                    color: _primaryColor,
                  ),
                  title: Text(
                    'Language preference',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w700,
                      color: _textColor,
                    ),
                  ),
                  subtitle: Text(
                    '${_languageLabel()} • translation not active yet',
                    style: TextStyle(
                      color: _mutedColor,
                    ),
                  ),
                  trailing:
                  _isSavingLanguage
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                      _primaryColor,
                    ),
                  )
                      : Icon(
                    Icons
                        .chevron_right_rounded,
                    color:
                    _mutedColor,
                  ),
                  onTap:
                  _isSavingLanguage
                      ? null
                      : _showLanguagePicker,
                ),

                const Divider(
                  height: 1,
                ),

                ListTile(
                  leading: Icon(
                    Icons.palette_outlined,
                    color: _primaryColor,
                  ),
                  title: Text(
                    'Appearance',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w700,
                      color: _textColor,
                    ),
                  ),
                  subtitle: Text(
                    _themeLabel(),
                    style: TextStyle(
                      color: _mutedColor,
                    ),
                  ),
                  trailing:
                  _isSavingTheme
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                      _primaryColor,
                    ),
                  )
                      : Icon(
                    Icons
                        .chevron_right_rounded,
                    color:
                    _mutedColor,
                  ),
                  onTap:
                  _isSavingTheme
                      ? null
                      : _showThemePicker,
                ),
              ],
            ),

            const SizedBox(
              height: 24,
            ),

            _sectionTitle(
              'LOCAL APP STATUS',
            ),

            const SizedBox(
              height: 8,
            ),

            _settingsCard(
              children: <Widget>[
                ListTile(
                  leading: Icon(
                    Icons.smartphone_rounded,
                    color: _primaryColor,
                  ),
                  title: Text(
                    'Local prototype session',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w700,
                      color: _textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Account authentication and cloud sync are not connected yet.',
                    style: TextStyle(
                      color: _mutedColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 24,
            ),

            _sectionTitle(
              'ABOUT',
            ),

            const SizedBox(
              height: 8,
            ),

            _settingsCard(
              children: <Widget>[
                ListTile(
                  leading: Icon(
                    Icons.info_outline_rounded,
                    color: _primaryColor,
                  ),
                  title: Text(
                    'About TubiLearn',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w700,
                      color: _textColor,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: _mutedColor,
                  ),
                  onTap: _showAboutDialog,
                ),

                const Divider(
                  height: 1,
                ),

                ListTile(
                  leading: Icon(
                    Icons
                        .privacy_tip_outlined,
                    color: _primaryColor,
                  ),
                  title: Text(
                    'Privacy',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w700,
                      color: _textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Prototype data is stored locally',
                    style: TextStyle(
                      color: _mutedColor,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: _mutedColor,
                  ),
                  onTap: _showPrivacyDialog,
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            _buildDevelopmentNotice(
              icon:
              Icons.construction_rounded,
              text:
              'Real authentication, account security, cloud sync, realtime chat, push notifications, and remote profile photos belong to the production/backend phase.',
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // COMMON WIDGETS
  // ============================================================

  Widget _sectionTitle(
      String title,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: _mutedColor,
        ),
      ),
    );
  }

  Widget _settingsCard({
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDevelopmentNotice({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: _softPrimaryColor,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color:
          _primaryColor.withValues(
            alpha:
            _isDarkMode
                ? 0.24
                : 0.12,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            size: 20,
            color: _primaryColor,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: _mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}