import 'dart:io';

import 'package:flutter/material.dart';

import '../model/repositories/explore_repository.dart';
import '../model/user.dart';
import '../services/current_user_service.dart';
import '../services/profile_image_service.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final ExploreRepository _repository =
      ExploreRepository.instance;

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  final ProfileImageService _profileImageService =
      ProfileImageService.instance;

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _cityController =
  TextEditingController();

  final TextEditingController _bioController =
  TextEditingController();

  final TextEditingController _availabilityController =
  TextEditingController();

  final TextEditingController _languageController =
  TextEditingController();

  final TextEditingController _preferredModeController =
  TextEditingController();

  final TextEditingController _teachingStyleController =
  TextEditingController();

  User? _currentUser;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUpdatingProfileImage = false;
  bool _isExitDialogOpen = false;

  String? _loadError;

  String _originalName = '';
  String _originalCity = '';
  String _originalBio = '';
  String _originalAvailability = '';
  String _originalLanguage = '';
  String _originalPreferredMode = '';
  String _originalTeachingStyle = '';

  Color get _surfaceColor =>
      Theme.of(context).colorScheme.surface;

  Color get _surfaceVariantColor =>
      Theme.of(context)
          .colorScheme
          .surfaceContainerHighest;

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

  Color get _primaryColor =>
      Theme.of(context).colorScheme.primary;

  bool get _isBusy =>
      _isSaving ||
          _isUpdatingProfileImage;

  bool get _hasUnsavedChanges {
    if (_currentUser == null ||
        _isLoading) {
      return false;
    }

    return _nameController.text.trim() !=
        _originalName ||
        _cityController.text.trim() !=
            _originalCity ||
        _bioController.text.trim() !=
            _originalBio ||
        _availabilityController.text.trim() !=
            _originalAvailability ||
        _languageController.text.trim() !=
            _originalLanguage ||
        _preferredModeController.text.trim() !=
            _originalPreferredMode ||
        _teachingStyleController.text.trim() !=
            _originalTeachingStyle;
  }

  @override
  void initState() {
    super.initState();

    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _availabilityController.dispose();
    _languageController.dispose();
    _preferredModeController.dispose();
    _teachingStyleController.dispose();

    super.dispose();
  }

  // ============================================================
  // ORIGINAL FORM SNAPSHOT
  // ============================================================

  void _captureOriginalValues(
      User user,
      ) {
    _originalName =
        user.name.trim();

    _originalCity =
        user.city.trim();

    _originalBio =
        user.bio.trim();

    _originalAvailability =
        user.availability.trim();

    _originalLanguage =
        user.language.trim();

    _originalPreferredMode =
        user.preferredMode.trim();

    _originalTeachingStyle =
        user.teachingStyle.trim();
  }

  void _populateControllers(
      User user,
      ) {
    _nameController.text =
        user.name;

    _cityController.text =
        user.city;

    _bioController.text =
        user.bio;

    _availabilityController.text =
        user.availability;

    _languageController.text =
        user.language;

    _preferredModeController.text =
        user.preferredMode;

    _teachingStyleController.text =
        user.teachingStyle;
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadCurrentProfile() async {
    try {
      await _repository.initialize();

      final String userId =
      _currentUserService.requireUserId();

      final User? user =
      _repository.findUserById(
        userId,
      );

      if (user == null) {
        throw const ExploreRepositoryException(
          'Your profile could not be found.',
        );
      }

      if (!mounted) {
        return;
      }

      _currentUser =
          user;

      _populateControllers(
        user,
      );

      _captureOriginalValues(
        user,
      );

      setState(() {
        _isLoading = false;
        _loadError = null;
      });
    } on CurrentUserServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.message;
      });
    } on ExploreRepositoryException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError =
        'Your profile could not be loaded. Please try again.';
      });
    }
  }

  // ============================================================
  // UNSAVED CHANGES
  // ============================================================

  void _handlePopAttempt(
      bool didPop,
      ) {
    if (didPop ||
        _isBusy ||
        _isExitDialogOpen) {
      return;
    }

    _confirmDiscardChanges();
  }

  Future<void> _confirmDiscardChanges() async {
    if (!mounted ||
        _isBusy ||
        _isExitDialogOpen) {
      return;
    }

    if (!_hasUnsavedChanges) {
      Navigator.pop(
        context,
      );

      return;
    }

    FocusScope.of(
      context,
    ).unfocus();

    _isExitDialogOpen = true;

    final bool? discard =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          _surfaceColor,
          title: Text(
            'Discard unsaved changes?',
            style: TextStyle(
              color:
              _textColor,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          content: Text(
            'You changed some profile details but have not saved them yet. '
                'Leaving now will discard those edits. '
                'Profile photo changes are saved separately when applied.',
            style: TextStyle(
              color:
              _mutedColor,
              height:
              1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: Text(
                'KEEP EDITING',
                style:
                AppTextStyles.button.copyWith(
                  color:
                  _primaryColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'DISCARD',
                style: TextStyle(
                  color:
                  AppTheme.error,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    _isExitDialogOpen = false;

    if (!mounted ||
        discard != true) {
      return;
    }

    Navigator.pop(
      context,
    );
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    if (_isBusy ||
        _isLoading) {
      return;
    }

    final FormState? form =
        _formKey.currentState;

    if (form == null ||
        !form.validate()) {
      return;
    }

    FocusScope.of(
      context,
    ).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final User updatedUser =
      await _repository.updateCurrentUserProfile(
        name:
        _nameController.text,
        city:
        _cityController.text,
        bio:
        _bioController.text,
        availability:
        _availabilityController.text,
        language:
        _languageController.text,
        preferredMode:
        _preferredModeController.text,
        teachingStyle:
        _teachingStyleController.text,
      );

      _currentUser =
          updatedUser;

      _populateControllers(
        updatedUser,
      );

      _captureOriginalValues(
        updatedUser,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } on ExploreRepositoryException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Your profile could not be saved. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // PROFILE IMAGE OPTIONS
  // ============================================================

  Future<void> _openProfileImageOptions() async {
    if (_isBusy) {
      return;
    }

    final User? user =
        _currentUser;

    if (user == null) {
      return;
    }

    final bool hasPhoto =
    _hasUsableProfileImage(
      user,
    );

    final String? action =
    await showModalBottomSheet<String>(
      context: context,
      backgroundColor:
      _surfaceColor,
      showDragHandle:
      true,
      builder: (
          BuildContext sheetContext,
          ) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              14,
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.photo_library_outlined,
                    color:
                    _primaryColor,
                  ),
                  title: Text(
                    hasPhoto
                        ? 'Change profile photo'
                        : 'Choose profile photo',
                    style: TextStyle(
                      color:
                      _textColor,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Select a photo from your gallery',
                    style: TextStyle(
                      color:
                      _mutedColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      'choose',
                    );
                  },
                ),
                if (hasPhoto)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color:
                      AppTheme.error,
                    ),
                    title: const Text(
                      'Remove profile photo',
                      style: TextStyle(
                        color:
                        AppTheme.error,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                        'remove',
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted ||
        action == null) {
      return;
    }

    if (action == 'choose') {
      await _pickProfileImage();
      return;
    }

    if (action == 'remove') {
      await _confirmRemoveProfileImage();
    }
  }

  Future<void> _pickProfileImage() async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isUpdatingProfileImage = true;
    });

    try {
      final User? updatedUser =
      await _profileImageService
          .pickAndSaveCurrentUserProfileImage();

      if (!mounted) {
        return;
      }

      if (updatedUser == null) {
        return;
      }

      setState(() {
        _currentUser =
            updatedUser;
      });

      _showMessage(
        'Profile photo updated.',
      );
    } on ProfileImageServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Profile photo could not be updated. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfileImage = false;
        });
      }
    }
  }

  Future<void> _confirmRemoveProfileImage() async {
    if (_isBusy) {
      return;
    }

    final bool? confirmed =
    await showDialog<bool>(
      context:
      context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          _surfaceColor,
          title: Text(
            'Remove profile photo?',
            style: TextStyle(
              color:
              _textColor,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          content: Text(
            'Your initials will be shown instead.',
            style: TextStyle(
              color:
              _mutedColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: Text(
                'CANCEL',
                style:
                AppTextStyles.button.copyWith(
                  color:
                  _mutedColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'REMOVE',
                style: TextStyle(
                  color:
                  AppTheme.error,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    await _removeProfileImage();
  }

  Future<void> _removeProfileImage() async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isUpdatingProfileImage = true;
    });

    try {
      final User updatedUser =
      await _profileImageService
          .removeCurrentUserProfileImage();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser =
            updatedUser;
      });

      _showMessage(
        'Profile photo removed.',
      );
    } on ProfileImageServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Profile photo could not be removed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfileImage = false;
        });
      }
    }
  }

  // ============================================================
  // PROFILE IMAGE DISPLAY
  // ============================================================

  bool _hasUsableProfileImage(
      User user,
      ) {
    final String? path =
    user.profileImagePath?.trim();

    if (path == null ||
        path.isEmpty) {
      return false;
    }

    try {
      return File(
        path,
      ).existsSync();
    } catch (_) {
      return false;
    }
  }

  Widget _buildProfileAvatar({
    required double size,
  }) {
    final User? user =
        _currentUser;

    final String previewName =
    _nameController.text
        .trim()
        .isEmpty
        ? user?.name ??
        'Your Profile'
        : _nameController.text.trim();

    final String initials =
    _buildPreviewInitials(
      previewName,
    );

    final String? path =
    user?.profileImagePath?.trim();

    final bool hasImage =
        user != null &&
            path != null &&
            path.isNotEmpty &&
            _hasUsableProfileImage(
              user,
            );

    return Stack(
      clipBehavior:
      Clip.none,
      children: [
        ClipOval(
          child: SizedBox(
            width:
            size,
            height:
            size,
            child: hasImage
                ? Image.file(
              File(
                path,
              ),
              width:
              size,
              height:
              size,
              fit:
              BoxFit.cover,
              errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                  ) {
                return _buildInitialAvatar(
                  initials,
                  size:
                  size,
                );
              },
            )
                : _buildInitialAvatar(
              initials,
              size:
              size,
            ),
          ),
        ),
        Positioned(
          right:
          -2,
          bottom:
          -2,
          child: Material(
            color:
            _primaryColor,
            shape:
            const CircleBorder(),
            elevation:
            2,
            child: InkWell(
              customBorder:
              const CircleBorder(),
              onTap:
              _isBusy
                  ? null
                  : _openProfileImageOptions,
              child: SizedBox(
                width:
                28,
                height:
                28,
                child: Center(
                  child: _isUpdatingProfileImage
                      ? const SizedBox(
                    width:
                    13,
                    height:
                    13,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.camera_alt_rounded,
                    size:
                    15,
                    color:
                    Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialAvatar(
      String initials, {
        required double size,
      }) {
    return Container(
      width:
      size,
      height:
      size,
      color:
      AppTheme.accent,
      alignment:
      Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize:
          size >= 58
              ? 17
              : 14,
          fontWeight:
          FontWeight.w800,
          color:
          Colors.white,
        ),
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
    return PopScope(
      canPop:
      !_isBusy &&
          !_hasUnsavedChanges,
      onPopInvokedWithResult: (
          bool didPop,
          Object? result,
          ) {
        _handlePopAttempt(
          didPop,
        );
      },
      child: Scaffold(
        backgroundColor:
        Theme.of(context)
            .scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,
          surfaceTintColor:
          Colors.transparent,
          elevation:
          0,
          title: Text(
            'Edit Profile',
            style: TextStyle(
              fontSize:
              19,
              fontWeight:
              FontWeight.w800,
              color:
              _textColor,
            ),
          ),
        ),
        body:
        _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_loadError != null) {
      return _buildErrorState();
    }

    return SafeArea(
      child: Form(
        key:
        _formKey,
        child: SingleChildScrollView(
          physics:
          const BouncingScrollPhysics(),
          padding:
          const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            32,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),

              const SizedBox(
                height:
                14,
              ),

              _buildEditingHint(),

              const SizedBox(
                height:
                24,
              ),

              Text(
                'Basic information',
                style:
                AppTextStyles.sectionTitle
                    .copyWith(
                  color:
                  _textColor,
                ),
              ),

              const SizedBox(
                height:
                12,
              ),

              _buildTextField(
                controller:
                _nameController,
                label:
                'Name',
                hint:
                'Enter your name',
                icon:
                Icons.person_outline_rounded,
                maxLength:
                80,
              ),

              const SizedBox(
                height:
                14,
              ),

              _buildTextField(
                controller:
                _cityController,
                label:
                'City',
                hint:
                'Enter your city',
                icon:
                Icons.location_on_outlined,
                maxLength:
                100,
              ),

              const SizedBox(
                height:
                14,
              ),

              _buildTextField(
                controller:
                _bioController,
                label:
                'Bio',
                hint:
                'Tell people a little about yourself',
                icon:
                Icons.notes_rounded,
                maxLength:
                500,
                maxLines:
                4,
              ),

              const SizedBox(
                height:
                24,
              ),

              Text(
                'Learning preferences',
                style:
                AppTextStyles.sectionTitle
                    .copyWith(
                  color:
                  _textColor,
                ),
              ),

              const SizedBox(
                height:
                12,
              ),

              _buildTextField(
                controller:
                _availabilityController,
                label:
                'Availability',
                hint:
                'Example: Weekends, 2 PM–6 PM',
                icon:
                Icons.schedule_rounded,
                maxLength:
                120,
              ),

              const SizedBox(
                height:
                14,
              ),

              _buildTextField(
                controller:
                _languageController,
                label:
                'Language',
                hint:
                'Example: English, Filipino',
                icon:
                Icons.language_rounded,
                maxLength:
                120,
              ),

              const SizedBox(
                height:
                14,
              ),

              _buildTextField(
                controller:
                _preferredModeController,
                label:
                'Preferred mode',
                hint:
                'Example: Online or in person',
                icon:
                Icons.devices_rounded,
                maxLength:
                120,
              ),

              const SizedBox(
                height:
                14,
              ),

              _buildTextField(
                controller:
                _teachingStyleController,
                label:
                'Teaching style',
                hint:
                'Example: Step-by-step and practical',
                icon:
                Icons.school_outlined,
                maxLength:
                160,
              ),

              const SizedBox(
                height:
                28,
              ),

              SizedBox(
                width:
                double.infinity,
                height:
                48,
                child:
                ElevatedButton.icon(
                  onPressed:
                  _isBusy
                      ? null
                      : _saveProfile,
                  icon:
                  _isSaving
                      ? const SizedBox(
                    width:
                    18,
                    height:
                    18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.save_outlined,
                    size:
                    19,
                  ),
                  label:
                  Text(
                    _isSaving
                        ? 'SAVING...'
                        : 'SAVE PROFILE',
                    style:
                    AppTextStyles.button,
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    AppTheme.primary,
                    foregroundColor:
                    Colors.white,
                    disabledBackgroundColor:
                    _surfaceVariantColor,
                    disabledForegroundColor:
                    _mutedColor,
                    elevation:
                    0,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeaderCard() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        18,
      ),
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
      Row(
        children: [
          _buildProfileAvatar(
            size:
            62,
          ),

          const SizedBox(
            width:
            16,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep your profile useful',
                  style:
                  AppTextStyles.cardTitle
                      .copyWith(
                    color:
                    _textColor,
                  ),
                ),

                const SizedBox(
                  height:
                  4,
                ),

                Text(
                  'Tap your photo to change it, then update any profile details below.',
                  style:
                  AppTextStyles.bodyMuted
                      .copyWith(
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

  // ============================================================
  // EDITING HINT
  // ============================================================

  Widget _buildEditingHint() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        14,
        vertical:
        11,
      ),
      decoration:
      BoxDecoration(
        color:
        _primaryColor.withValues(
          alpha:
          0.10,
        ),
        borderRadius:
        BorderRadius.circular(
          13,
        ),
        border:
        Border.all(
          color:
          _primaryColor.withValues(
            alpha:
            0.25,
          ),
        ),
      ),
      child:
      Row(
        children: [
          Icon(
            Icons.edit_rounded,
            size:
            18,
            color:
            _primaryColor,
          ),

          const SizedBox(
            width:
            9,
          ),

          Expanded(
            child:
            Text(
              'Tap any field below to edit your information.',
              style:
              AppTextStyles.secondary
                  .copyWith(
                color:
                _textColor,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required int maxLength,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller:
      controller,
      enabled:
      !_isBusy,
      maxLength:
      maxLength,
      maxLines:
      maxLines,
      minLines:
      maxLines > 1
          ? 3
          : 1,
      cursorColor:
      _primaryColor,
      style:
      TextStyle(
        color:
        _textColor,
        fontWeight:
        FontWeight.w500,
      ),
      textCapitalization:
      TextCapitalization.sentences,
      decoration:
      InputDecoration(
        labelText:
        label,
        hintText:
        hint,
        floatingLabelBehavior:
        FloatingLabelBehavior.always,
        labelStyle:
        TextStyle(
          color:
          _primaryColor,
          fontWeight:
          FontWeight.w600,
        ),
        hintStyle:
        TextStyle(
          color:
          _mutedColor,
        ),
        prefixIcon:
        Icon(
          icon,
          color:
          _primaryColor,
          size:
          20,
        ),
        suffixIcon:
        Icon(
          Icons.edit_outlined,
          color:
          _mutedColor,
          size:
          18,
        ),
        alignLabelWithHint:
        maxLines > 1,
        filled:
        true,
        fillColor:
        _surfaceColor,
        counterStyle:
        AppTextStyles.caption.copyWith(
          color:
          _mutedColor,
        ),
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            _borderColor,
          ),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            _borderColor,
            width:
            1.2,
          ),
        ),
        disabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            _borderColor,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            _primaryColor,
            width:
            2,
          ),
        ),
        errorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          const BorderSide(
            color:
            AppTheme.error,
          ),
        ),
        focusedErrorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          const BorderSide(
            color:
            AppTheme.error,
            width:
            2,
          ),
        ),
      ),
      validator: (
          String? value,
          ) {
        final String cleaned =
            value?.trim() ??
                '';

        if (cleaned.isEmpty) {
          return '$label is required.';
        }

        if (cleaned.length >
            maxLength) {
          return '$label is too long.';
        }

        return null;
      },
      onChanged: (
          String value,
          ) {
        if (!mounted) {
          return;
        }

        setState(() {});
      },
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
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
          children: [
            Icon(
              Icons.error_outline_rounded,
              size:
              42,
              color:
              _mutedColor,
            ),

            const SizedBox(
              height:
              12,
            ),

            Text(
              _loadError ??
                  'Your profile could not be loaded.',
              textAlign:
              TextAlign.center,
              style:
              AppTextStyles.bodyMuted.copyWith(
                color:
                _mutedColor,
              ),
            ),

            const SizedBox(
              height:
              16,
            ),

            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading =
                  true;

                  _loadError =
                  null;
                });

                _loadCurrentProfile();
              },
              icon:
              const Icon(
                Icons.refresh_rounded,
              ),
              label:
              const Text(
                'TRY AGAIN',
                style:
                AppTextStyles.button,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INITIALS
  // ============================================================

  String _buildPreviewInitials(
      String name,
      ) {
    final List<String> parts =
    name
        .trim()
        .split(
      RegExp(
        r'\s+',
      ),
    )
        .where(
          (
          String part,
          ) =>
      part.isNotEmpty,
    )
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      final String part =
          parts.first;

      if (part.length == 1) {
        return part.toUpperCase();
      }

      return part
          .substring(
        0,
        2,
      )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
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
}