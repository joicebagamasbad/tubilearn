import 'package:flutter/material.dart';

import '../model/repositories/wanted_skills_repository.dart';
import '../services/current_user_service.dart';
import '../theme/app_theme.dart';

class AddWantedSkillScreen extends StatefulWidget {
  const AddWantedSkillScreen({
    super.key,
  });

  @override
  State<AddWantedSkillScreen> createState() =>
      _AddWantedSkillScreenState();
}

class _AddWantedSkillScreenState
    extends State<AddWantedSkillScreen> {
  final WantedSkillsRepository _repository =
      WantedSkillsRepository.instance;

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  final TextEditingController _skillNameController =
  TextEditingController();

  final TextEditingController _descriptionController =
  TextEditingController();

  String? _selectedCategory;

  String _level = 'Beginner';

  String _availability = 'Flexible';

  bool _saving = false;

  static const List<String> _categories = <String>[
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

  bool get _isDarkMode =>
      Theme.of(context).brightness ==
          Brightness.dark;

  Color get _primaryColor =>
      Theme.of(context).colorScheme.primary;

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

  Color get _primaryForeground =>
      _isDarkMode
          ? const Color(
        0xFF092E31,
      )
          : Colors.white;

  @override
  void dispose() {
    _skillNameController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return PopScope(
      canPop:
      !_saving,
      child:
      Scaffold(
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
            'Add Learning Interest',
            style:
            TextStyle(
              fontSize:
              18,
              fontWeight:
              FontWeight.w800,
              color:
              _textColor,
            ),
          ),
        ),
        body:
        SafeArea(
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
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                _buildIntro(),

                const SizedBox(
                  height:
                  24,
                ),

                _buildLabel(
                  'Skill name',
                ),

                const SizedBox(
                  height:
                  8,
                ),

                _buildSkillNameField(),

                const SizedBox(
                  height:
                  20,
                ),

                _buildLabel(
                  'Category',
                ),

                const SizedBox(
                  height:
                  8,
                ),

                _buildCategoryField(),

                const SizedBox(
                  height:
                  20,
                ),

                _buildLabel(
                  'What do you want to learn?',
                ),

                const SizedBox(
                  height:
                  8,
                ),

                _buildDescriptionField(),

                const SizedBox(
                  height:
                  20,
                ),

                _buildLabel(
                  'Current level',
                ),

                const SizedBox(
                  height:
                  10,
                ),

                _buildLevelSelector(),

                const SizedBox(
                  height:
                  20,
                ),

                _buildLabel(
                  'Availability',
                ),

                const SizedBox(
                  height:
                  8,
                ),

                _buildAvailabilitySelector(),

                const SizedBox(
                  height:
                  28,
                ),

                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
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
          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'What would you like to learn?',
                  style:
                  AppTextStyles.cardTitle
                      .copyWith(
                    color:
                    _textColor,
                  ),
                ),
                const SizedBox(
                  height:
                  5,
                ),
                Text(
                  'Add skills you want to learn so TubiLearn can better understand your learning goals.',
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
            width:
            12,
          ),
          Image.asset(
            'assets/images/mascot/tubi_studying.png',
            width:
            68,
            height:
            68,
            fit:
            BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(
      String text,
      ) {
    return Text(
      text,
      style:
      TextStyle(
        fontSize:
        12,
        fontWeight:
        FontWeight.w700,
        color:
        _textColor,
      ),
    );
  }

  Widget _buildSkillNameField() {
    return TextField(
      controller:
      _skillNameController,
      enabled:
      !_saving,
      maxLength:
      80,
      textCapitalization:
      TextCapitalization.words,
      style:
      TextStyle(
        color:
        _textColor,
      ),
      decoration:
      InputDecoration(
        hintText:
        'e.g. UI/UX Design',
        counterText:
        '',
        hintStyle:
        TextStyle(
          color:
          _mutedColor,
        ),
        prefixIcon:
        Icon(
          Icons.lightbulb_outline_rounded,
          color:
          _primaryColor,
        ),
        filled:
        true,
        fillColor:
        _surfaceColor,
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
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
          BorderRadius.circular(
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
          BorderRadius.circular(
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
          BorderRadius.circular(
            13,
          ),
          borderSide:
          BorderSide(
            color:
            _primaryColor,
            width:
            1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      initialValue:
      _selectedCategory,
      isExpanded:
      true,
      dropdownColor:
      _surfaceColor,
      decoration:
      InputDecoration(
        prefixIcon:
        Icon(
          Icons.grid_view_rounded,
          color:
          _primaryColor,
        ),
        filled:
        true,
        fillColor:
        _surfaceColor,
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
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
          BorderRadius.circular(
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
          BorderRadius.circular(
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
          BorderRadius.circular(
            13,
          ),
          borderSide:
          BorderSide(
            color:
            _primaryColor,
            width:
            1.3,
          ),
        ),
      ),
      hint:
      Text(
        'Select category',
        style:
        TextStyle(
          color:
          _mutedColor,
        ),
      ),
      items:
      _categories.map(
            (
            String category,
            ) =>
            DropdownMenuItem<String>(
              value:
              category,
              child:
              Text(
                category,
                overflow:
                TextOverflow.ellipsis,
                style:
                TextStyle(
                  color:
                  _textColor,
                ),
              ),
            ),
      ).toList(),
      onChanged:
      _saving
          ? null
          : (
          String? value,
          ) {
        setState(() {
          _selectedCategory =
              value;
        });
      },
    );
  }

  Widget _buildDescriptionField() {
    return Stack(
      children: [
        TextField(
          controller:
          _descriptionController,
          enabled:
          !_saving,
          maxLines:
          5,
          maxLength:
          200,
          textCapitalization:
          TextCapitalization.sentences,
          style:
          TextStyle(
            color:
            _textColor,
          ),
          decoration:
          InputDecoration(
            hintText:
            'Describe what you want to learn or improve...',
            counterText:
            '',
            hintStyle:
            TextStyle(
              color:
              _mutedColor,
            ),
            filled:
            true,
            fillColor:
            _surfaceColor,
            contentPadding:
            const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              28,
            ),
            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
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
              BorderRadius.circular(
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
              BorderRadius.circular(
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
              BorderRadius.circular(
                13,
              ),
              borderSide:
              BorderSide(
                color:
                _primaryColor,
                width:
                1.3,
              ),
            ),
          ),
          onChanged: (_) {
            setState(() {});
          },
        ),
        Positioned(
          right:
          12,
          bottom:
          10,
          child:
          Text(
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

  Widget _buildLevelSelector() {
    const List<String> levels =
    <String>[
      'Beginner',
      'Intermediate',
      'Advanced',
    ];

    return Row(
      children:
      levels.map(
            (
            String level,
            ) {
          final bool selected =
              _level ==
                  level;

          return Expanded(
            child:
            Padding(
              padding:
              EdgeInsets.only(
                right:
                level == levels.last
                    ? 0
                    : 8,
              ),
              child:
              SizedBox(
                height:
                42,
                child:
                OutlinedButton(
                  onPressed:
                  _saving
                      ? null
                      : () {
                    setState(() {
                      _level =
                          level;
                    });
                  },
                  style:
                  OutlinedButton.styleFrom(
                    backgroundColor:
                    selected
                        ? _primaryColor
                        : _surfaceColor,
                    foregroundColor:
                    selected
                        ? _primaryForeground
                        : _textColor,
                    side:
                    BorderSide(
                      color:
                      selected
                          ? _primaryColor
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
                    EdgeInsets.zero,
                  ),
                  child:
                  Text(
                    level,
                    style:
                    TextStyle(
                      fontSize:
                      9,
                      fontWeight:
                      selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ).toList(),
    );
  }

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
      child:
      Container(
        height:
        50,
        padding:
        const EdgeInsets.symmetric(
          horizontal:
          14,
        ),
        decoration:
        BoxDecoration(
          color:
          _surfaceColor,
          borderRadius:
          BorderRadius.circular(
            13,
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
            Icon(
              Icons.calendar_month_outlined,
              color:
              _primaryColor,
              size:
              20,
            ),
            const SizedBox(
              width:
              10,
            ),
            Expanded(
              child:
              Text(
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
              Icons.keyboard_arrow_down_rounded,
              color:
              _mutedColor,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAvailabilitySheet() async {
    final String? selected =
    await showModalBottomSheet<String>(
      context:
      context,
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
      builder:
          (
          BuildContext sheetContext,
          ) {
        return SafeArea(
          child:
          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              24,
            ),
            child:
            Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Center(
                  child:
                  Container(
                    width:
                    40,
                    height:
                    4,
                    decoration:
                    BoxDecoration(
                      color:
                      _borderColor,
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height:
                  18,
                ),
                Text(
                  'Choose availability',
                  style:
                  AppTextStyles.cardTitle
                      .copyWith(
                    color:
                    _textColor,
                  ),
                ),
                const SizedBox(
                  height:
                  8,
                ),
                ..._availabilityOptions.map(
                      (
                      String option,
                      ) {
                    return ListTile(
                      contentPadding:
                      EdgeInsets.zero,
                      title:
                      Text(
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
                          ? Icon(
                        Icons.check_circle_rounded,
                        color:
                        _primaryColor,
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

  Widget _buildSaveButton() {
    return SizedBox(
      width:
      double.infinity,
      height:
      48,
      child:
      ElevatedButton.icon(
        onPressed:
        _saving
            ? null
            : _save,
        icon:
        _saving
            ? SizedBox(
          width:
          18,
          height:
          18,
          child:
          CircularProgressIndicator(
            strokeWidth:
            2,
            color:
            _primaryForeground,
          ),
        )
            : const Icon(
          Icons.add_rounded,
          size:
          20,
        ),
        label:
        Text(
          _saving
              ? 'ADDING...'
              : 'ADD LEARNING INTEREST',
          style:
          AppTextStyles.button,
        ),
        style:
        ElevatedButton.styleFrom(
          backgroundColor:
          _primaryColor,
          foregroundColor:
          _primaryForeground,
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
    );
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    final String skillName =
    _skillNameController.text.trim();

    final String description =
    _descriptionController.text.trim();

    final String? category =
        _selectedCategory;

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

    if (category == null ||
        category.trim().isEmpty) {
      _showMessage(
        'Please select a category.',
      );
      return;
    }

    if (description.isEmpty) {
      _showMessage(
        'Please describe what you want to learn.',
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
      _saving =
      true;
    });

    try {
      final String userId =
      _currentUserService.requireUserId();

      await _repository.addWantedSkill(
        userId:
        userId,
        title:
        skillName,
        category:
        category,
        description:
        description,
        level:
        _level,
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
        'Could not add the learning interest. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving =
          false;
        });
      }
    }
  }

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