import 'package:flutter/material.dart';

import '../controller/auth_controller.dart';
import '../controller/settings_controller.dart';
import '../model/app_settings.dart';

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
  final AuthController _authController = AuthController();
  final SettingsController _controller =
  SettingsController();

  bool _isLoading = true;
  bool _isSavingNotifications = false;
  bool _isSavingLanguage = false;
  bool _isSavingTheme = false;
  bool _isSigningOut = false;

  bool _notificationsEnabled = true;

  AppLanguagePreference _language =
      AppLanguagePreference.english;

  AppThemePreference _theme =
      AppThemePreference.system;

  String? _errorMessage;

  bool get _isDarkMode =>
      Theme.of(context).brightness ==
          Brightness.dark;

  Color get _primaryColor =>
      Theme.of(context)
          .colorScheme
          .primary;

  Color get _surfaceColor =>
      Theme.of(context)
          .colorScheme
          .surface;

  Color get _surfaceVariantColor =>
      Theme.of(context)
          .colorScheme
          .surfaceContainerHighest;

  Color get _textColor =>
      Theme.of(context)
          .colorScheme
          .onSurface;

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

  Color get _successColor =>
      _isDarkMode
          ? const Color(
        0xFF75B88D,
      )
          : const Color(
        0xFF3F7D59,
      );

  Color get _softSuccessColor =>
      _successColor.withValues(
        alpha:
        _isDarkMode
            ? 0.15
            : 0.09,
      );

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadSettings();
  }

  // ============================================================
  // SNAPSHOT
  // ============================================================

  void _applySnapshot(
      SettingsSnapshot snapshot,
      ) {
    _notificationsEnabled =
        snapshot.notificationsEnabled;

    _language =
        snapshot.language;

    _theme =
        snapshot.theme;
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
      final SettingsSnapshot snapshot =
      await _controller
          .loadSettings();

      if (!mounted) {
        return;
      }

      setState(() {
        _applySnapshot(
          snapshot,
        );

        _isLoading = false;
        _errorMessage = null;
      });
    } on SettingsControllerException catch (
    error
    ) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            error.message;
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
  // NOTIFICATIONS
  // ============================================================

  Future<void> _toggleNotifications(
      bool enabled,
      ) async {
    if (_isSavingNotifications) {
      return;
    }

    setState(() {
      _isSavingNotifications =
      true;
    });

    try {
      final SettingsSnapshot snapshot =
      await _controller
          .setNotificationsEnabled(
        enabled,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _applySnapshot(
          snapshot,
        );

        _isSavingNotifications =
        false;
      });

      _showMessage(
        enabled
            ? 'Notification preference saved as On.'
            : 'Notification preference saved as Off.',
      );
    } on SettingsControllerException catch (
    error
    ) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingNotifications =
        false;
      });

      _showMessage(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingNotifications =
        false;
      });

      _showMessage(
        'Could not save notification preference.',
      );
    }
  }

  String _notificationSubtitle() {
    if (_isSavingNotifications) {
      return 'Saving preference...';
    }

    if (_notificationsEnabled) {
      return 'On • push notifications are not connected yet';
    }

    return 'Off • preference saved locally';
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  Future<void> _showLanguagePicker() async {
    if (_isSavingLanguage) {
      return;
    }

    final AppLanguagePreference current =
        _language;

    final AppLanguagePreference? selected =
    await showModalBottomSheet<
        AppLanguagePreference>(
      context:
      context,
      backgroundColor:
      _surfaceColor,
      showDragHandle:
      true,
      isScrollControlled:
      true,
      builder: (
          BuildContext sheetContext,
          ) {
        return SafeArea(
          child:
          SingleChildScrollView(
            padding:
            const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child:
            Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children:
              <Widget>[
                Text(
                  'Language preference',
                  style:
                  TextStyle(
                    fontSize:
                    20,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    _textColor,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Choose your preferred TubiLearn language.',
                  style:
                  TextStyle(
                    fontSize:
                    14,
                    height:
                    1.4,
                    color:
                    _mutedColor,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                RadioGroup<
                    AppLanguagePreference>(
                  groupValue:
                  current,
                  onChanged: (
                      AppLanguagePreference?
                      value,
                      ) {
                    if (value ==
                        null) {
                      return;
                    }

                    Navigator.of(
                      sheetContext,
                    ).pop(
                      value,
                    );
                  },
                  child:
                  Column(
                    children:
                    <Widget>[
                      RadioListTile<
                          AppLanguagePreference>(
                        contentPadding:
                        EdgeInsets.zero,
                        title:
                        Text(
                          'English',
                          style:
                          TextStyle(
                            color:
                            _textColor,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                        subtitle:
                        Text(
                          'Save English as your preferred language.',
                          style:
                          TextStyle(
                            color:
                            _mutedColor,
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
                        title:
                        Text(
                          'Filipino',
                          style:
                          TextStyle(
                            color:
                            _textColor,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                        subtitle:
                        Text(
                          'Save Filipino as your preferred language.',
                          style:
                          TextStyle(
                            color:
                            _mutedColor,
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

                _buildInfoNotice(
                  icon:
                  Icons.translate_rounded,
                  title:
                  'Preference only',
                  text:
                  'This choice is saved on this device. Full English and Filipino interface translation will be connected during the localization phase.',
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null ||
        selected == _language) {
      return;
    }

    setState(() {
      _isSavingLanguage =
      true;
    });

    try {
      final SettingsSnapshot snapshot =
      await _controller
          .setLanguage(
        selected,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _applySnapshot(
          snapshot,
        );

        _isSavingLanguage =
        false;
      });

      _showMessage(
        'Language preference saved.',
      );
    } on SettingsControllerException catch (
    error
    ) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingLanguage =
        false;
      });

      _showMessage(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingLanguage =
        false;
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
        _theme;

    final AppThemePreference? selected =
    await showModalBottomSheet<
        AppThemePreference>(
      context:
      context,
      backgroundColor:
      _surfaceColor,
      showDragHandle:
      true,
      isScrollControlled:
      true,
      builder: (
          BuildContext sheetContext,
          ) {
        return SafeArea(
          child:
          SingleChildScrollView(
            padding:
            const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child:
            Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children:
              <Widget>[
                Text(
                  'Appearance',
                  style:
                  TextStyle(
                    fontSize:
                    20,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    _textColor,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Choose how TubiLearn should look on this device.',
                  style:
                  TextStyle(
                    fontSize:
                    14,
                    height:
                    1.4,
                    color:
                    _mutedColor,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                RadioGroup<
                    AppThemePreference>(
                  groupValue:
                  current,
                  onChanged: (
                      AppThemePreference?
                      value,
                      ) {
                    if (value ==
                        null) {
                      return;
                    }

                    Navigator.of(
                      sheetContext,
                    ).pop(
                      value,
                    );
                  },
                  child:
                  Column(
                    children:
                    <Widget>[
                      RadioListTile<
                          AppThemePreference>(
                        contentPadding:
                        EdgeInsets.zero,
                        secondary:
                        const Icon(
                          Icons
                              .settings_suggest_outlined,
                        ),
                        title:
                        Text(
                          'System',
                          style:
                          TextStyle(
                            color:
                            _textColor,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                        subtitle:
                        Text(
                          'Follow your device appearance.',
                          style:
                          TextStyle(
                            color:
                            _mutedColor,
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
                        secondary:
                        const Icon(
                          Icons
                              .light_mode_outlined,
                        ),
                        title:
                        Text(
                          'Light',
                          style:
                          TextStyle(
                            color:
                            _textColor,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                        subtitle:
                        Text(
                          'Always use light mode.',
                          style:
                          TextStyle(
                            color:
                            _mutedColor,
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
                        secondary:
                        const Icon(
                          Icons
                              .dark_mode_outlined,
                        ),
                        title:
                        Text(
                          'Dark',
                          style:
                          TextStyle(
                            color:
                            _textColor,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                        subtitle:
                        Text(
                          'Always use dark mode.',
                          style:
                          TextStyle(
                            color:
                            _mutedColor,
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
        selected == _theme) {
      return;
    }

    setState(() {
      _isSavingTheme =
      true;
    });

    try {
      final SettingsSnapshot snapshot =
      await _controller.setTheme(
        selected,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _applySnapshot(
          snapshot,
        );

        _isSavingTheme =
        false;
      });

      _showMessage(
        'Appearance updated.',
      );
    } on SettingsControllerException catch (
    error
    ) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingTheme =
        false;
      });

      _showMessage(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingTheme =
        false;
      });

      _showMessage(
        'Could not save appearance preference.',
      );
    }
  }

  // ============================================================
  // LOCAL DATA
  // ============================================================

  void _showLocalDataDialog() {
    _showInformationDialog(
      icon:
      Icons.storage_outlined,
      title:
      'On-device data',
      children:
      <Widget>[
        _dialogParagraph(
          'TubiLearn uses cloud sync for your profile, My Skills, and Explore data. Some features still store data only on this device.',
        ),
        _dialogPoint(
          icon:
          Icons.school_outlined,
          title:
          'Skills and preferences',
          text:
          'Your profile, offered skills, and learning interests are connected to your signed-in account. App preferences remain on this device.',
        ),
        _dialogPoint(
          icon:
          Icons.swap_horiz_rounded,
          title:
          'Swaps and sessions',
          text:
          'Swap requests and scheduled-session information are stored in the local app database.',
        ),
        _dialogPoint(
          icon:
          Icons.chat_bubble_outline_rounded,
          title:
          'Messages',
          text:
          'Prototype conversations and messages remain on this device unless the app data is removed.',
        ),
        _dialogPoint(
          icon:
          Icons.cloud_off_outlined,
          title:
          'Partial cloud sync',
          text:
          'Chats, swaps and sessions, reviews, app preferences, and profile photos are not included in cloud sync.',
        ),
      ],
    );
  }

  void _showProfilePhotoStorageDialog() {
    _showInformationDialog(
      icon:
      Icons.photo_outlined,
      title:
      'Profile photo storage',
      children:
      <Widget>[
        _dialogParagraph(
          'Profile photos selected in this prototype are copied into TubiLearn-managed storage on this device.',
        ),
        _dialogPoint(
          icon:
          Icons.smartphone_rounded,
          title:
          'Local file',
          text:
          'The current profile stores a local image path, so the photo belongs to this device installation.',
        ),
        _dialogPoint(
          icon:
          Icons.sync_disabled_rounded,
          title:
          'Not cross-device',
          text:
          'The image is not uploaded to remote storage and will not automatically appear on another device.',
        ),
        _dialogPoint(
          icon:
          Icons.cloud_upload_outlined,
          title:
          'Not cloud synced',
          text:
          'Profile photos remain on this device and are not included in account cloud sync.',
        ),
      ],
    );
  }

  // ============================================================
  // PROTOTYPE ACCOUNT
  // ============================================================

  void _showPrototypeAccountDialog() {
    _showInformationDialog(
      icon:
      Icons.person_outline_rounded,
      title:
      'Account and data',
      children:
      <Widget>[
        _dialogParagraph(
          'Your Firebase account is your TubiLearn identity. Profile, My Skills, and Explore data use cloud sync, while some features remain on this device.',
        ),
        _dialogPoint(
          icon:
          Icons.check_circle_outline_rounded,
          title:
          'Cloud-backed data',
          text:
          'Your profile, offered skills, learning interests, and Explore candidate data are connected to your signed-in account.',
        ),
        _dialogPoint(
          icon:
          Icons.lock_outline_rounded,
          title:
          'Stored on this device',
          text:
          'Chats, swaps and sessions, reviews, app preferences, and profile photos remain local to this device.',
        ),
        _dialogPoint(
          icon:
          Icons.devices_outlined,
          title:
          'Partial cloud sync',
          text:
          'Cloud-backed data can follow your account, while local-only data remains on this device.',
        ),
      ],
    );
  }

  // ============================================================
  // ABOUT / PRIVACY
  // ============================================================

  void _showAboutDialog() {
    _showInformationDialog(
      icon:
      Icons.info_outline_rounded,
      title:
      'About TubiLearn',
      children:
      <Widget>[
        _dialogParagraph(
          'TubiLearn is a skill-exchange platform designed to help people teach what they know and learn practical skills from others.',
        ),
        _dialogPoint(
          icon:
          Icons.swap_horiz_rounded,
          title:
          'Skill exchange',
          text:
          'Learners can offer their own skills while requesting skills they want to learn.',
        ),
        _dialogPoint(
          icon:
          Icons.auto_awesome_outlined,
          title:
          'Smart matching',
          text:
          'Smart Match compares skills and preferences from the current cloud-backed Explore candidates.',
        ),
        _dialogPoint(
          icon:
          Icons.phone_android_rounded,
          title:
          'Current build',
          text:
          'This build combines cloud-backed account, profile, skills, and Explore data with device-only features.',
        ),
      ],
    );
  }

  void _showPrivacyDialog() {
    _showInformationDialog(
      icon:
      Icons.privacy_tip_outlined,
      title:
      'Privacy',
      children:
      <Widget>[
        _dialogParagraph(
          'TubiLearn uses cloud services for authentication, profiles, skills, and Explore. Chats, swaps, reviews, app preferences, and profile photos remain on this device.',
        ),
        _dialogPoint(
          icon:
          Icons.storage_rounded,
          title:
          'Local-only data',
          text:
          'Chats, swaps, reviews, app preferences, and profile photos remain in this app installation unless they are changed or removed.',
        ),
        _dialogPoint(
          icon:
          Icons.cloud_off_rounded,
          title:
          'Account and cloud data',
          text:
          'Firebase Authentication identifies your account, and cloud sync supports your profile, My Skills, and Explore data.',
        ),
        _dialogPoint(
          icon:
          Icons.policy_outlined,
          title:
          'What stays local',
          text:
          'Chats, swaps, reviews, app preferences, and profile photos are not included in cloud sync.',
        ),
      ],
    );
  }

  void _showInformationDialog({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    showDialog<void>(
      context:
      context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          _surfaceColor,
          titlePadding:
          const EdgeInsets.fromLTRB(
            24,
            22,
            24,
            0,
          ),
          contentPadding:
          const EdgeInsets.fromLTRB(
            24,
            16,
            24,
            8,
          ),
          actionsPadding:
          const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            12,
          ),
          title:
          Row(
            children:
            <Widget>[
              Container(
                width:
                40,
                height:
                40,
                decoration:
                BoxDecoration(
                  color:
                  _softPrimaryColor,
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child:
                Icon(
                  icon,
                  color:
                  _primaryColor,
                  size:
                  21,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                Text(
                  title,
                  style:
                  TextStyle(
                    color:
                    _textColor,
                    fontSize:
                    19,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content:
          SingleChildScrollView(
            child:
            Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children:
              children,
            ),
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

  Widget _dialogParagraph(
      String text,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 14,
      ),
      child:
      Text(
        text,
        style:
        TextStyle(
          color:
          _mutedColor,
          fontSize:
          13.5,
          height:
          1.5,
        ),
      ),
    );
  }

  Widget _dialogPoint({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 14,
      ),
      child:
      Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children:
        <Widget>[
          Container(
            width:
            34,
            height:
            34,
            decoration:
            BoxDecoration(
              color:
              _surfaceVariantColor,
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
            child:
            Icon(
              icon,
              size:
              18,
              color:
              _primaryColor,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children:
              <Widget>[
                Text(
                  title,
                  style:
                  TextStyle(
                    color:
                    _textColor,
                    fontSize:
                    13,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  text,
                  style:
                  TextStyle(
                    color:
                    _mutedColor,
                    fontSize:
                    12.5,
                    height:
                    1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LABELS
  // ============================================================

  String _languageLabel() {
    switch (_language) {
      case AppLanguagePreference.english:
        return 'English';

      case AppLanguagePreference.filipino:
        return 'Filipino';
    }
  }

  String _themeLabel() {
    switch (_theme) {
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
          content:
          Text(
            message,
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await _authController.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
      }
    } on AuthControllerException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not sign out. Please try again.');
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
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
      appBar:
      AppBar(
        backgroundColor:
        Theme.of(context)
            .scaffoldBackgroundColor,
        surfaceTintColor:
        Colors.transparent,
        elevation:
        0,
        title:
        Text(
          'Settings',
          style:
          TextStyle(
            color:
            _textColor,
            fontWeight:
            FontWeight.w800,
          ),
        ),
      ),
      body:
      _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child:
        CircularProgressIndicator(
          color:
          _primaryColor,
        ),
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
              Container(
                width:
                58,
                height:
                58,
                decoration:
                BoxDecoration(
                  color:
                  _softPrimaryColor,
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                ),
                child:
                Icon(
                  Icons.error_outline_rounded,
                  size:
                  30,
                  color:
                  _primaryColor,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              Text(
                'Settings unavailable',
                style:
                TextStyle(
                  color:
                  _textColor,
                  fontSize:
                  17,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                _errorMessage!,
                textAlign:
                TextAlign.center,
                style:
                TextStyle(
                  color:
                  _mutedColor,
                  height:
                  1.4,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              ElevatedButton.icon(
                onPressed:
                _loadSettings,
                icon:
                const Icon(
                  Icons.refresh_rounded,
                ),
                label:
                const Text(
                  'RETRY',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics:
      const BouncingScrollPhysics(),
      padding:
      const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        32,
      ),
      children:
      <Widget>[
        _buildIntroCard(),

        const SizedBox(
          height: 24,
        ),

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
              const EdgeInsets.symmetric(
                horizontal:
                16,
                vertical:
                6,
              ),
              secondary:
              _settingsIcon(
                Icons.notifications_outlined,
              ),
              title:
              Text(
                'Notifications',
                style:
                TextStyle(
                  fontWeight:
                  FontWeight.w700,
                  color:
                  _textColor,
                ),
              ),
              subtitle:
              Text(
                _notificationSubtitle(),
                style:
                TextStyle(
                  color:
                  _mutedColor,
                  fontSize:
                  12.5,
                ),
              ),
              value:
              _notificationsEnabled,
              onChanged:
              _isSavingNotifications
                  ? null
                  : _toggleNotifications,
            ),

            _divider(),

            _actionTile(
              icon:
              Icons.language_rounded,
              title:
              'Language',
              subtitle:
              _isSavingLanguage
                  ? 'Saving preference...'
                  : '${_languageLabel()} • preference only',
              isBusy:
              _isSavingLanguage,
              onTap:
              _isSavingLanguage
                  ? null
                  : _showLanguagePicker,
            ),

            _divider(),

            _actionTile(
              icon:
              Icons.palette_outlined,
              title:
              'Appearance',
              subtitle:
              _isSavingTheme
                  ? 'Applying appearance...'
                  : '${_themeLabel()} • active now',
              isBusy:
              _isSavingTheme,
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
          'LOCAL DATA & PRIVACY',
        ),

        const SizedBox(
          height: 8,
        ),

        _settingsCard(
          children:
          <Widget>[
            _actionTile(
              icon:
              Icons.storage_outlined,
              title:
              'Data storage',
              subtitle:
              'Cloud-backed and device-only data',
              onTap:
              _showLocalDataDialog,
            ),

            _divider(),

            _actionTile(
              icon:
              Icons.photo_outlined,
              title:
              'Profile photo storage',
              subtitle:
              'Stored locally on this device',
              onTap:
              _showProfilePhotoStorageDialog,
            ),

            _divider(),

            _actionTile(
              icon:
              Icons.privacy_tip_outlined,
              title:
              'Privacy',
              subtitle:
              'How TubiLearn handles your data',
              onTap:
              _showPrivacyDialog,
            ),
          ],
        ),

        const SizedBox(
          height: 24,
        ),

        _sectionTitle(
          'ACCOUNT STATUS',
        ),

        const SizedBox(
          height: 8,
        ),

        _settingsCard(
          children:
          <Widget>[
            _actionTile(
              icon:
              Icons.person_outline_rounded,
              title:
              'Signed-in account',
              subtitle:
              _authController.currentSession?.email ?? 'Signed in',
              trailing:
              _buildStatusBadge(
                label:
                'ACTIVE',
                positive:
                true,
              ),
              onTap:
              _showPrototypeAccountDialog,
            ),

            _divider(),

            _actionTile(
              icon: Icons.logout_rounded,
              title: 'Log out',
              subtitle: _isSigningOut ? 'Signing out...' : 'Return to login',
              isBusy: _isSigningOut,
              onTap: _isSigningOut ? null : _signOut,
            ),

            _divider(),

            ListTile(
              contentPadding:
              const EdgeInsets.symmetric(
                horizontal:
                16,
                vertical:
                8,
              ),
              leading:
              _settingsIcon(
                Icons.cloud_off_outlined,
              ),
              title:
              Text(
                'Cloud sync',
                style:
                TextStyle(
                  color:
                  _textColor,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
              subtitle:
              Text(
                'Profile, My Skills, and Explore use cloud sync',
                style:
                TextStyle(
                  color:
                  _mutedColor,
                  fontSize:
                  12.5,
                ),
              ),
              trailing:
              _buildStatusBadge(
                label:
                'PARTIAL',
                positive:
                false,
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
          children:
          <Widget>[
            _actionTile(
              icon:
              Icons.info_outline_rounded,
              title:
              'About TubiLearn',
              subtitle:
              'Skill exchange with partial cloud sync',
              onTap:
              _showAboutDialog,
            ),
          ],
        ),

        const SizedBox(
          height: 20,
        ),

        _buildInfoNotice(
          icon:
          Icons.construction_rounded,
          title:
          'Data availability',
          text:
          'Your account, profile, My Skills, and Explore data use cloud services. Chats, swaps and sessions, reviews, app preferences, and profile photos remain on this device.',
        ),
      ],
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _buildIntroCard() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      BoxDecoration(
        color:
        _softPrimaryColor,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color:
          _primaryColor.withValues(
            alpha:
            _isDarkMode
                ? 0.24
                : 0.12,
          ),
        ),
      ),
      child:
      Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children:
        <Widget>[
          Container(
            width:
            46,
            height:
            46,
            decoration:
            BoxDecoration(
              color:
              _surfaceColor,
              borderRadius:
              BorderRadius.circular(
                14,
              ),
              border:
              Border.all(
                color:
                _borderColor,
              ),
            ),
            child:
            Icon(
              Icons.tune_rounded,
              color:
              _primaryColor,
              size:
              23,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children:
              <Widget>[
                Text(
                  'Your TubiLearn preferences',
                  style:
                  TextStyle(
                    color:
                    _textColor,
                    fontSize:
                    15,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  'Manage working app preferences and see clearly which features are local-only in this prototype.',
                  style:
                  TextStyle(
                    color:
                    _mutedColor,
                    fontSize:
                    12.5,
                    height:
                    1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        horizontal:
        4,
      ),
      child:
      Text(
        title,
        style:
        TextStyle(
          fontSize:
          11.5,
          fontWeight:
          FontWeight.w700,
          letterSpacing:
          0.9,
          color:
          _mutedColor,
        ),
      ),
    );
  }

  Widget _settingsCard({
    required List<Widget> children,
  }) {
    return Container(
      clipBehavior:
      Clip.antiAlias,
      decoration:
      BoxDecoration(
        color:
        _surfaceColor,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color:
          _borderColor,
        ),
      ),
      child:
      Column(
        children:
        children,
      ),
    );
  }

  Widget _settingsIcon(
      IconData icon,
      ) {
    return Container(
      width:
      40,
      height:
      40,
      decoration:
      BoxDecoration(
        color:
        _softPrimaryColor,
        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),
      child:
      Icon(
        icon,
        size:
        20,
        color:
        _primaryColor,
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool isBusy = false,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal:
        16,
        vertical:
        7,
      ),
      leading:
      _settingsIcon(
        icon,
      ),
      title:
      Text(
        title,
        style:
        TextStyle(
          color:
          _textColor,
          fontWeight:
          FontWeight.w700,
        ),
      ),
      subtitle:
      Text(
        subtitle,
        style:
        TextStyle(
          color:
          _mutedColor,
          fontSize:
          12.5,
        ),
      ),
      trailing:
      isBusy
          ? SizedBox(
        width:
        20,
        height:
        20,
        child:
        CircularProgressIndicator(
          strokeWidth:
          2,
          color:
          _primaryColor,
        ),
      )
          : trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color:
            _mutedColor,
          ),
      onTap:
      isBusy
          ? null
          : onTap,
    );
  }

  Widget _divider() {
    return Divider(
      height:
      1,
      indent:
      68,
      endIndent:
      16,
      color:
      _borderColor,
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required bool positive,
  }) {
    final Color foreground =
    positive
        ? _successColor
        : _mutedColor;

    final Color background =
    positive
        ? _softSuccessColor
        : _surfaceVariantColor;

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        9,
        vertical:
        5,
      ),
      decoration:
      BoxDecoration(
        color:
        background,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child:
      Text(
        label,
        style:
        TextStyle(
          color:
          foreground,
          fontSize:
          9.5,
          fontWeight:
          FontWeight.w800,
          letterSpacing:
          0.4,
        ),
      ),
    );
  }

  Widget _buildInfoNotice({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        _softPrimaryColor,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border:
        Border.all(
          color:
          _primaryColor.withValues(
            alpha:
            _isDarkMode
                ? 0.24
                : 0.12,
          ),
        ),
      ),
      child:
      Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children:
        <Widget>[
          Icon(
            icon,
            size:
            20,
            color:
            _primaryColor,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children:
              <Widget>[
                Text(
                  title,
                  style:
                  TextStyle(
                    color:
                    _textColor,
                    fontSize:
                    12.5,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  text,
                  style:
                  TextStyle(
                    fontSize:
                    12.5,
                    height:
                    1.45,
                    color:
                    _mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
