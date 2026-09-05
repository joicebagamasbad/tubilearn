import 'package:flutter/material.dart';

import '../model/repositories/wanted_skills_repository.dart';
import '../services/current_user_service.dart';
import '../theme/app_theme.dart';

class EditWantedSkillScreen extends StatefulWidget {
  final ManagedWantedSkill managedWantedSkill;

  const EditWantedSkillScreen({
    super.key,
    required this.managedWantedSkill,
  });

  @override
  State<EditWantedSkillScreen> createState() =>
      _EditWantedSkillScreenState();
}

class _EditWantedSkillScreenState
    extends State<EditWantedSkillScreen> {
  final WantedSkillsRepository _repository =
      WantedSkillsRepository.instance;

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  late final TextEditingController _skillNameController;
  late final TextEditingController _descriptionController;

  late String _selectedCategory;
  late String _level;
  late String _availability;

  bool _saving = false;

  bool get _canEditMetadata {
    try {
      final String currentUserId =
      _currentUserService.requireUserId();

      return widget.managedWantedSkill
          .metadataCanBeEditedBy(
        currentUserId,
      );
    } on CurrentUserServiceException {
      return false;
    }
  }

  bool get _isDarkMode =>
      Theme.of(context).brightness == Brightness.dark;

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

  Color get _lockedFieldColor =>
      _isDarkMode
          ? _surfaceVariantColor
          : const Color(
        0xFFF5F5FA,
      );

  static const List<String> _categories =
  <String>[
    'Design & Creative',
    'Technology',
    'Photography',
    'Video & Media',
    'Music',
    'Language',
    'Education',
    'Lifestyle',
  ];

  static const List<String> _availabilityOptions =
  <String>[
    'Weekdays',
    'Weekends',
    'Mornings',
    'Afternoons',
    'Evenings',
    'Flexible',
  ];

  @override
  void initState() {
    super.initState();

    final skill =
        widget.managedWantedSkill.skill;

    final userSkill =
        widget.managedWantedSkill.userSkill;

    _skillNameController =
        TextEditingController(
          text: skill.title,
        );

    _descriptionController =
        TextEditingController(
          text: skill.description,
        );

    _selectedCategory =
        skill.category;

    _level =
        userSkill.level;

    _availability =
        userSkill.availability;
  }

  @override
  void dispose() {
    _skillNameController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return PopScope(
      canPop: !_saving,
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
            'Edit Learning Interest',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.w800,
              color: _textColor,
            ),
          ),
        ),
        body: SafeArea(
          child:
          SingleChildScrollView(
            physics:
            const BouncingScrollPhysics(),
            padding:
            const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              32,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                _buildIntro(),

                const SizedBox(
                  height: 24,
                ),

                if (!_canEditMetadata) ...[
                  _buildSharedSkillNotice(),

                  const SizedBox(
                    height: 20,
                  ),
                ],

                _buildLabel(
                  'Skill name',
                ),

                const SizedBox(
                  height: 8,
                ),

                _buildSkillNameField(),

                const SizedBox(
                  height: 20,
                ),

                _buildLabel(
                  'Category',
                ),

                const SizedBox(
                  height: 8,
                ),

                _buildCategoryField(),

                const SizedBox(
                  height: 20,
                ),

                _buildLabel(
                  'What do you want to learn?',
                ),

                const SizedBox(
                  height: 8,
                ),

                _buildDescriptionField(),

                const SizedBox(
                  height: 20,
                ),

                _buildLabel(
                  'Current level',
                ),

                const SizedBox(
                  height: 10,
                ),

                _buildLevelSelector(),

                const SizedBox(
                  height: 20,
                ),

                _buildLabel(
                  'Availability',
                ),

                const SizedBox(
                  height: 8,
                ),

                _buildAvailabilitySelector(),

                const SizedBox(
                  height: 28,
                ),

                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        16,
      ),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Update your learning goal',
                  style:
                  AppTextStyles.cardTitle
                      .copyWith(
                    color:
                    _textColor,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Keep your current level and availability accurate so future matches stay useful.',
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

          const SizedBox(
            width: 12,
          ),

          Image.asset(
            'assets/images/mascot/tubi_planning.png',
            width: 68,
            height: 68,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SHARED SKILL NOTICE
  // ============================================================

  Widget _buildSharedSkillNotice() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        13,
      ),
      decoration: BoxDecoration(
        color:
        AppTheme.primary
            .withValues(
          alpha:
          _isDarkMode
              ? 0.14
              : 0.06,
        ),
        borderRadius:
        BorderRadius.circular(
          13,
        ),
        border: Border.all(
          color:
          AppTheme.primary
              .withValues(
            alpha:
            _isDarkMode
                ? 0.28
                : 0.12,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons
                .info_outline_rounded,
            size: 18,
            color:
            AppTheme.primary,
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Text(
              'This is a shared skill from the TubiLearn catalog. You can update your current level and availability, but the skill name, category, and description stay unchanged.',
              style:
              TextStyle(
                fontSize: 12,
                height: 1.4,
                color:
                _mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(
      String text,
      ) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight:
        FontWeight.w700,
        color: _textColor,
      ),
    );
  }

  // ============================================================
  // SKILL NAME
  // ============================================================

  Widget _buildSkillNameField() {
    return TextField(
      controller:
      _skillNameController,
      enabled:
      !_saving &&
          _canEditMetadata,
      maxLength: 80,
      textCapitalization:
      TextCapitalization.words,
      style: TextStyle(
        color: _textColor,
      ),
      decoration:
      InputDecoration(
        hintText:
        'Skill name',
        counterText: '',
        hintStyle:
        TextStyle(
          color:
          _mutedColor,
        ),
        prefixIcon:
        const Icon(
          Icons
              .lightbulb_outline_rounded,
          color:
          AppTheme.primary,
        ),
        filled: true,
        fillColor:
        _canEditMetadata
            ? _surfaceColor
            : _lockedFieldColor,
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius
              .circular(
            13,
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
          BorderRadius
              .circular(
            13,
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
          BorderRadius
              .circular(
            13,
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
          BorderRadius
              .circular(
            13,
          ),
          borderSide:
          const BorderSide(
            color:
            AppTheme
                .primary,
            width: 1.3,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  Widget _buildCategoryField() {
    final List<String> categories =
    <String>[
      ..._categories,
    ];

    if (!categories.contains(
      _selectedCategory,
    )) {
      categories.add(
        _selectedCategory,
      );
    }

    return DropdownButtonFormField<String>(
      initialValue:
      _selectedCategory,
      isExpanded: true,
      dropdownColor:
      _surfaceColor,
      decoration:
      InputDecoration(
        prefixIcon:
        const Icon(
          Icons
              .grid_view_rounded,
          color:
          AppTheme.primary,
        ),
        filled: true,
        fillColor:
        _canEditMetadata
            ? _surfaceColor
            : _lockedFieldColor,
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius
              .circular(
            13,
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
          BorderRadius
              .circular(
            13,
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
          BorderRadius
              .circular(
            13,
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
          BorderRadius
              .circular(
            13,
          ),
          borderSide:
          const BorderSide(
            color:
            AppTheme
                .primary,
          ),
        ),
      ),
      items:
      categories
          .map(
            (
            String category,
            ) =>
            DropdownMenuItem<
                String
            >(
              value:
              category,
              child: Text(
                category,
                overflow:
                TextOverflow
                    .ellipsis,
                style:
                TextStyle(
                  color:
                  _textColor,
                ),
              ),
            ),
      )
          .toList(),
      onChanged:
      !_canEditMetadata ||
          _saving
          ? null
          : (
          String? value,
          ) {
        if (value ==
            null) {
          return;
        }

        setState(() {
          _selectedCategory =
              value;
        });
      },
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _buildDescriptionField() {
    return Stack(
      children: [
        TextField(
          controller:
          _descriptionController,
          enabled:
          !_saving &&
              _canEditMetadata,
          maxLines: 5,
          maxLength: 200,
          textCapitalization:
          TextCapitalization
              .sentences,
          style: TextStyle(
            color: _textColor,
          ),
          decoration:
          InputDecoration(
            hintText:
            'Describe what you want to learn...',
            counterText: '',
            hintStyle:
            TextStyle(
              color:
              _mutedColor,
            ),
            filled: true,
            fillColor:
            _canEditMetadata
                ? _surfaceColor
                : _lockedFieldColor,
            contentPadding:
            const EdgeInsets
                .fromLTRB(
              14,
              14,
              14,
              28,
            ),
            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius
                  .circular(
                13,
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
              BorderRadius
                  .circular(
                13,
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
              BorderRadius
                  .circular(
                13,
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
              BorderRadius
                  .circular(
                13,
              ),
              borderSide:
              const BorderSide(
                color:
                AppTheme
                    .primary,
                width:
                1.3,
              ),
            ),
          ),
          onChanged:
          _canEditMetadata
              ? (_) {
            setState(() {});
          }
              : null,
        ),

        Positioned(
          right: 12,
          bottom: 10,
          child: Text(
            '${_descriptionController.text.length}/200',
            style:
            AppTextStyles.caption
                .copyWith(
              color:
              _mutedColor,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LEVEL
  // ============================================================

  Widget _buildLevelSelector() {
    const List<String> levels =
    <String>[
      'Beginner',
      'Intermediate',
      'Advanced',
    ];

    return Row(
      children:
      levels
          .map(
            (
            String level,
            ) {
          final bool selected =
              _level ==
                  level;

          return Expanded(
            child: Padding(
              padding:
              EdgeInsets.only(
                right:
                level ==
                    levels
                        .last
                    ? 0
                    : 8,
              ),
              child: SizedBox(
                height: 42,
                child:
                OutlinedButton(
                  onPressed:
                  _saving
                      ? null
                      : () {
                    setState(
                          () {
                        _level =
                            level;
                      },
                    );
                  },
                  style:
                  OutlinedButton.styleFrom(
                    backgroundColor:
                    selected
                        ? AppTheme
                        .primary
                        : _surfaceColor,
                    foregroundColor:
                    selected
                        ? Colors
                        .white
                        : _textColor,
                    side:
                    BorderSide(
                      color:
                      selected
                          ? AppTheme
                          .primary
                          : _borderColor,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                    ),
                    padding:
                    EdgeInsets
                        .zero,
                  ),
                  child: Text(
                    level,
                    style:
                    TextStyle(
                      fontSize:
                      9,
                      fontWeight:
                      selected
                          ? FontWeight
                          .w700
                          : FontWeight
                          .w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      )
          .toList(),
    );
  }

  // ============================================================
  // AVAILABILITY
  // ============================================================

  Widget _buildAvailabilitySelector() {
    return InkWell(
      borderRadius:
      BorderRadius.circular(
        13,
      ),
      onTap:
      _saving
          ? null
          : _showAvailabilitySheet,
      child: Container(
        height: 50,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration:
        BoxDecoration(
          color:
          _surfaceColor,
          borderRadius:
          BorderRadius.circular(
            13,
          ),
          border: Border.all(
            color:
            _borderColor,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons
                  .calendar_month_outlined,
              color:
              AppTheme.primary,
              size: 20,
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Text(
                _availability,
                style:
                TextStyle(
                  fontSize:
                  12,
                  color:
                  _textColor,
                ),
              ),
            ),

            Icon(
              Icons
                  .keyboard_arrow_down_rounded,
              color:
              _mutedColor,
            ),
          ],
        ),
      ),
    );
  }

  Future<void>
  _showAvailabilitySheet() async {
    final List<String> options =
    <String>[
      ..._availabilityOptions,
    ];

    if (!options.contains(
      _availability,
    )) {
      options.add(
        _availability,
      );
    }

    final String? selected =
    await showModalBottomSheet<
        String
    >(
      context: context,
      backgroundColor:
      _surfaceColor,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top:
          Radius.circular(
            22,
          ),
        ),
      ),
      builder: (
          BuildContext sheetContext,
          ) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets
                .fromLTRB(
              20,
              16,
              20,
              24,
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration:
                    BoxDecoration(
                      color:
                      _borderColor,
                      borderRadius:
                      BorderRadius
                          .circular(
                        10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                Text(
                  'Choose availability',
                  style:
                  AppTextStyles
                      .cardTitle
                      .copyWith(
                    color:
                    _textColor,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                ...options.map(
                      (
                      String option,
                      ) {
                    return ListTile(
                      contentPadding:
                      EdgeInsets
                          .zero,
                      title: Text(
                        option,
                        style:
                        TextStyle(
                          color:
                          _textColor,
                        ),
                      ),
                      trailing:
                      _availability ==
                          option
                          ? const Icon(
                        Icons
                            .check_circle_rounded,
                        color:
                        AppTheme
                            .primary,
                      )
                          : null,
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                          option,
                        );
                      },
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
        selected == null) {
      return;
    }

    setState(() {
      _availability =
          selected;
    });
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child:
      ElevatedButton.icon(
        onPressed:
        _saving
            ? null
            : _save,
        icon:
        _saving
            ? const SizedBox(
          width: 18,
          height: 18,
          child:
          CircularProgressIndicator(
            strokeWidth:
            2,
            color:
            Colors
                .white,
          ),
        )
            : const Icon(
          Icons
              .save_outlined,
          size: 19,
        ),
        label: Text(
          _saving
              ? 'SAVING...'
              : 'SAVE CHANGES',
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
            BorderRadius
                .circular(
              13,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    final String skillName =
    _skillNameController.text
        .trim();

    final String description =
    _descriptionController.text
        .trim();

    if (skillName.isEmpty) {
      _showMessage(
        'Skill name is required.',
      );
      return;
    }

    if (skillName.length > 80) {
      _showMessage(
        'Skill name must be 80 characters or less.',
      );
      return;
    }

    if (_selectedCategory
        .trim()
        .isEmpty) {
      _showMessage(
        'Category is required.',
      );
      return;
    }

    if (description.isEmpty) {
      _showMessage(
        'Description is required.',
      );
      return;
    }

    if (description.length > 200) {
      _showMessage(
        'Description must be 200 characters or less.',
      );
      return;
    }

    FocusScope.of(
      context,
    ).unfocus();

    setState(() {
      _saving = true;
    });

    try {
      final String userId =
      _currentUserService
          .requireUserId();

      await _repository
          .updateWantedSkill(
        userId: userId,
        userSkillId:
        widget
            .managedWantedSkill
            .userSkill
            .id,
        title: skillName,
        category:
        _selectedCategory,
        description:
        description,
        level: _level,
        availability:
        _availability,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } on CurrentUserServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    } on WantedSkillsRepositoryException catch (error) {
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
        'Could not save the learning interest. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
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
          SnackBarBehavior
              .floating,
        ),
      );
  }
}