import 'package:flutter/material.dart';

import '../model/repositories/explore_repository.dart';
import '../model/user.dart';
import '../services/current_user_service.dart';
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

  bool _isLoading = true;
  bool _isSaving = false;

  String? _loadError;

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
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    if (_isSaving ||
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
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return PopScope(
      canPop:
      !_isSaving,
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
          elevation: 0,
          title: Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 19,
              fontWeight:
              FontWeight.w800,
              color: _textColor,
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
        key: _formKey,
        child:
        SingleChildScrollView(
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
                height: 24,
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
                height: 12,
              ),

              _buildTextField(
                controller:
                _nameController,
                label:
                'Name',
                hint:
                'Enter your name',
                icon:
                Icons
                    .person_outline_rounded,
                maxLength:
                80,
              ),

              const SizedBox(
                height: 14,
              ),

              _buildTextField(
                controller:
                _cityController,
                label:
                'City',
                hint:
                'Enter your city',
                icon:
                Icons
                    .location_on_outlined,
                maxLength:
                100,
              ),

              const SizedBox(
                height: 14,
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
                height: 24,
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
                height: 12,
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
                height: 14,
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
                height: 14,
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
                height: 14,
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
                height: 28,
              ),

              SizedBox(
                width:
                double.infinity,
                height: 48,
                child:
                ElevatedButton.icon(
                  onPressed:
                  _isSaving
                      ? null
                      : _saveProfile,
                  icon:
                  _isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons
                        .save_outlined,
                    size: 19,
                  ),
                  label: Text(
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
                    elevation: 0,
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
    final String previewName =
    _nameController.text
        .trim()
        .isEmpty
        ? 'Your Profile'
        : _nameController.text.trim();

    final String initials =
    _buildPreviewInitials(
      previewName,
    );

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
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration:
            const BoxDecoration(
              color:
              Color(
                0xFFFFAA45,
              ),
              shape:
              BoxShape.circle,
            ),
            alignment:
            Alignment.center,
            child: Text(
              initials,
              style:
              const TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.w800,
                color:
                Colors.white,
              ),
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
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
                  height: 4,
                ),

                Text(
                  'Clear profile details help other learners understand how and when you prefer to exchange skills.',
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
      !_isSaving,
      maxLength:
      maxLength,
      maxLines:
      maxLines,
      minLines:
      maxLines > 1
          ? 3
          : 1,
      style: TextStyle(
        color:
        _textColor,
      ),
      textCapitalization:
      TextCapitalization.sentences,
      decoration:
      InputDecoration(
        labelText:
        label,
        hintText:
        hint,
        labelStyle:
        TextStyle(
          color:
          _mutedColor,
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
          AppTheme.primary,
          size: 20,
        ),
        alignLabelWithHint:
        maxLines > 1,
        filled:
        true,
        fillColor:
        _surfaceColor,
        counterStyle:
        AppTextStyles.caption
            .copyWith(
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
          const BorderSide(
            color:
            AppTheme.primary,
            width:
            1.4,
          ),
        ),
      ),
      validator:
          (
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
      onChanged:
      label ==
          'Name'
          ? (_) {
        setState(() {});
      }
          : null,
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons
                  .error_outline_rounded,
              size: 42,
              color:
              _mutedColor,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              _loadError ??
                  'Your profile could not be loaded.',
              textAlign:
              TextAlign.center,
              style:
              AppTextStyles.bodyMuted
                  .copyWith(
                color:
                _mutedColor,
              ),
            ),

            const SizedBox(
              height: 16,
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
  // PREVIEW INITIALS
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
        return part
            .toUpperCase();
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