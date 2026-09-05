import 'package:flutter/material.dart';

import '../model/repositories/app_settings_repository.dart';
import '../services/app_settings_service.dart';
import '../theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _settingsService.initialize();

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
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
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingNotifications = false;
      });

      _showError(
        'Could not save notification preference.',
      );
    }
  }

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
                const Text(
                  'App Language',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'Choose the language preference TubiLearn should use.',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                    AppTheme.mutedText,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                RadioGroup<
                    AppLanguagePreference>(
                  groupValue:
                  current,
                  onChanged:
                      (
                      AppLanguagePreference?
                      value,
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
                  child: const Column(
                    children: <Widget>[
                      RadioListTile<
                          AppLanguagePreference>(
                        contentPadding:
                        EdgeInsets.zero,
                        title:
                        Text(
                          'English',
                        ),
                        subtitle:
                        Text(
                          'Use English throughout the app.',
                        ),
                        value:
                        AppLanguagePreference
                            .english,
                      ),
                      RadioListTile<
                          AppLanguagePreference>(
                        contentPadding:
                        EdgeInsets.zero,
                        title:
                        Text(
                          'Filipino',
                        ),
                        subtitle:
                        Text(
                          'Save Filipino as your preferred app language.',
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
                Container(
                  width:
                  double.infinity,
                  padding:
                  const EdgeInsets.all(
                    12,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    AppTheme.primary
                        .withValues(
                      alpha: 0.06,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),
                  child:
                  const Text(
                    'Language preference is saved locally. Full app text translation will be connected in a later localization phase.',
                    style:
                    TextStyle(
                      fontSize: 13,
                      color:
                      AppTheme
                          .mutedText,
                      height: 1.4,
                    ),
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
            _settingsService.language) {
      return;
    }

    setState(() {
      _isSavingLanguage = true;
    });

    try {
      await _settingsService
          .setLanguage(
        selected,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingLanguage = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingLanguage = false;
      });

      _showError(
        'Could not save language preference.',
      );
    }
  }

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
                const Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'Choose how TubiLearn should look on this device.',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                    AppTheme.mutedText,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                RadioGroup<
                    AppThemePreference>(
                  groupValue:
                  current,
                  onChanged:
                      (
                      AppThemePreference?
                      value,
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
                  child: const Column(
                    children: <Widget>[
                      RadioListTile<
                          AppThemePreference>(
                        contentPadding:
                        EdgeInsets.zero,
                        title:
                        Text(
                          'System',
                        ),
                        subtitle:
                        Text(
                          'Follow your phone appearance.',
                        ),
                        value:
                        AppThemePreference
                            .system,
                      ),
                      RadioListTile<
                          AppThemePreference>(
                        contentPadding:
                        EdgeInsets.zero,
                        title:
                        Text(
                          'Light',
                        ),
                        subtitle:
                        Text(
                          'Always use light mode.',
                        ),
                        value:
                        AppThemePreference
                            .light,
                      ),
                      RadioListTile<
                          AppThemePreference>(
                        contentPadding:
                        EdgeInsets.zero,
                        title:
                        Text(
                          'Dark',
                        ),
                        subtitle:
                        Text(
                          'Always use dark mode.',
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
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingTheme = false;
      });

      _showError(
        'Could not save appearance preference.',
      );
    }
  }

  void _showAboutDialog() {
    showDialog<void>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          title:
          const Text(
            'About TubiLearn',
          ),
          content:
          const Text(
            'TubiLearn is a skill exchange platform designed to help people teach what they know and learn new skills from others.',
          ),
          actions:
          <Widget>[
            TextButton(
              onPressed:
                  () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
              const Text(
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
          title:
          const Text(
            'Privacy',
          ),
          content:
          const Text(
            'This version of TubiLearn currently stores prototype data locally on this device. A full privacy policy and secure backend data handling will be added before production release.',
          ),
          actions:
          <Widget>[
            TextButton(
              onPressed:
                  () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
              const Text(
                'CLOSE',
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAccountSecurityInfo() {
    showDialog<void>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          title:
          const Text(
            'Password & Security',
          ),
          content:
          const Text(
            'TubiLearn is still using a local prototype session. Real password changes, secure login sessions, logout, account recovery, and account deletion will be connected during the authentication and backend phase.',
          ),
          actions:
          <Widget>[
            TextButton(
              onPressed:
                  () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
              const Text(
                'GOT IT',
              ),
            ),
          ],
        );
      },
    );
  }

  void _showError(
      String message,
      ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
        Text(
          message,
        ),
      ),
    );
  }

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

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      Theme.of(
        context,
      ).scaffoldBackgroundColor,
      appBar:
      AppBar(
        title:
        const Text(
          'Settings',
        ),
      ),
      body:
      _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child:
        Padding(
          padding:
          const EdgeInsets.all(
            24,
          ),
          child:
          Column(
            mainAxisSize:
            MainAxisSize.min,
            children:
            <Widget>[
              const Icon(
                Icons
                    .error_outline_rounded,
                size: 48,
                color:
                AppTheme.mutedText,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                _errorMessage!,
                textAlign:
                TextAlign.center,
              ),
              const SizedBox(
                height: 16,
              ),
              ElevatedButton(
                onPressed:
                _loadSettings,
                child:
                const Text(
                  'RETRY',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation:
      _settingsService,
      builder: (
          BuildContext context,
          Widget? child,
          ) {
        return ListView(
          padding:
          const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            32,
          ),
          children:
          <Widget>[
            _sectionTitle(
              'APP PREFERENCES',
            ),
            const SizedBox(
              height: 8,
            ),
            _settingsCard(
              children:
              <Widget>[
                SwitchListTile(
                  contentPadding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  secondary:
                  const Icon(
                    Icons
                        .notifications_outlined,
                  ),
                  title:
                  const Text(
                    'Notifications',
                  ),
                  subtitle:
                  Text(
                    _settingsService
                        .notificationsEnabled
                        ? 'Enabled'
                        : 'Disabled',
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
                  leading:
                  const Icon(
                    Icons
                        .language_rounded,
                  ),
                  title:
                  const Text(
                    'Language',
                  ),
                  subtitle:
                  Text(
                    _languageLabel(),
                  ),
                  trailing:
                  _isSavingLanguage
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                    ),
                  )
                      : const Icon(
                    Icons
                        .chevron_right_rounded,
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
                  leading:
                  const Icon(
                    Icons
                        .palette_outlined,
                  ),
                  title:
                  const Text(
                    'Appearance',
                  ),
                  subtitle:
                  Text(
                    _themeLabel(),
                  ),
                  trailing:
                  _isSavingTheme
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                    ),
                  )
                      : const Icon(
                    Icons
                        .chevron_right_rounded,
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
              'ACCOUNT',
            ),
            const SizedBox(
              height: 8,
            ),
            _settingsCard(
              children:
              <Widget>[
                const ListTile(
                  leading:
                  Icon(
                    Icons
                        .person_outline_rounded,
                  ),
                  title:
                  Text(
                    'Account Status',
                  ),
                  subtitle:
                  Text(
                    'Local prototype session',
                  ),
                ),
                const Divider(
                  height: 1,
                ),
                ListTile(
                  leading:
                  const Icon(
                    Icons
                        .lock_outline_rounded,
                  ),
                  title:
                  const Text(
                    'Password & Security',
                  ),
                  subtitle:
                  const Text(
                    'Authentication phase required',
                  ),
                  trailing:
                  const Icon(
                    Icons
                        .chevron_right_rounded,
                  ),
                  onTap:
                  _showAccountSecurityInfo,
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
              children:
              <Widget>[
                ListTile(
                  leading:
                  const Icon(
                    Icons
                        .info_outline_rounded,
                  ),
                  title:
                  const Text(
                    'About TubiLearn',
                  ),
                  trailing:
                  const Icon(
                    Icons
                        .chevron_right_rounded,
                  ),
                  onTap:
                  _showAboutDialog,
                ),
                const Divider(
                  height: 1,
                ),
                ListTile(
                  leading:
                  const Icon(
                    Icons
                        .privacy_tip_outlined,
                  ),
                  title:
                  const Text(
                    'Privacy',
                  ),
                  subtitle:
                  const Text(
                    'Prototype data is stored locally',
                  ),
                  trailing:
                  const Icon(
                    Icons
                        .chevron_right_rounded,
                  ),
                  onTap:
                  _showPrivacyDialog,
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Container(
              padding:
              const EdgeInsets.all(
                16,
              ),
              decoration:
              BoxDecoration(
                color:
                AppTheme.primary
                    .withValues(
                  alpha: 0.06,
                ),
                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),
              child:
              const Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children:
                <Widget>[
                  Icon(
                    Icons
                        .construction_rounded,
                    size: 20,
                    color:
                    AppTheme.primary,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child:
                    Text(
                      'TubiLearn is still under active development. Real authentication, cloud sync, account security, and production notifications will be added in later phases.',
                      style:
                      TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color:
                        AppTheme
                            .mutedText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(
      String title,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      child:
      Text(
        title,
        style:
        const TextStyle(
          fontSize: 12,
          fontWeight:
          FontWeight.w700,
          letterSpacing: 0.8,
          color:
          AppTheme.mutedText,
        ),
      ),
    );
  }

  Widget _settingsCard({
    required List<Widget> children,
  }) {
    return Container(
      decoration:
      BoxDecoration(
        color:
        Theme.of(
          context,
        ).cardColor,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color:
          AppTheme.border,
        ),
      ),
      child:
      Column(
        children:
        children,
      ),
    );
  }
}