import 'package:flutter/material.dart';

import '../controller/my_skills_controller.dart';
import '../theme/app_theme.dart';
import 'widgets/availability_picker.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({
    super.key,
  });

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final MySkillsController _controller = MySkillsController();

  final TextEditingController _skillNameController =
  TextEditingController();

  final TextEditingController _descriptionController =
  TextEditingController();

  String? _selectedCategory;

  String _experienceLevel = 'Intermediate';

  String _availability = 'Weekends';

  bool _saving = false;
  bool _isExitDialogOpen = false;
  bool _allowPop = false;

  final List<String> _categories = [
    'Design & Creative',
    'Technology',
    'Photography',
    'Video & Media',
    'Music',
    'Language',
    'Education',
    'Lifestyle',
  ];

  bool get _isDarkMode =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _primaryColor =>
      Theme.of(context).colorScheme.primary;

  Color get _surfaceColor =>
      Theme.of(context).colorScheme.surface;

  Color get _surfaceVariantColor =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  Color get _textColor =>
      Theme.of(context).colorScheme.onSurface;

  Color get _mutedColor =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  Color get _borderColor =>
      Theme.of(context).colorScheme.outlineVariant;

  Color get _primaryForeground =>
      _isDarkMode
          ? const Color(0xFF092E31)
          : Colors.white;

  bool get _hasDraft {
    return _skillNameController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _selectedCategory != null ||
        _experienceLevel != 'Intermediate' ||
        _availability != 'Weekends';
  }

  @override
  void dispose() {
    _skillNameController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // BACK / DRAFT PROTECTION
  // ============================================================

  void _handlePopAttempt(bool didPop) {
    if (didPop ||
        _saving ||
        _isExitDialogOpen) {
      return;
    }

    _confirmDiscardDraft();
  }

  Future<void> _confirmDiscardDraft() async {
    if (!mounted ||
        _saving ||
        _isExitDialogOpen) {
      return;
    }

    if (!_hasDraft) {
      setState(() {
        _allowPop = true;
      });

      Navigator.pop(context);
      return;
    }

    FocusScope.of(context).unfocus();

    _isExitDialogOpen = true;

    final bool? discard = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          title: Text(
            'Discard offered skill?',
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'You have an unfinished offered skill. '
                'Leaving now will discard the details you entered.',
            style: TextStyle(
              color: _mutedColor,
              height: 1.45,
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
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
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
                  color: AppTheme.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    _isExitDialogOpen = false;

    if (!mounted || discard != true) {
      return;
    }

    setState(() {
      _allowPop = true;
    });

    Navigator.pop(context);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
      !_saving &&
          (_allowPop || !_hasDraft),
      onPopInvokedWithResult: (
          bool didPop,
          Object? result,
          ) {
        _handlePopAttempt(didPop);
      },
      child: Scaffold(
        backgroundColor:
        Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics:
                  const BouncingScrollPhysics(),
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      _buildIntro(),

                      const SizedBox(height: 22),

                      _buildLabel(
                        'Skill Name',
                      ),

                      const SizedBox(height: 8),

                      _buildSkillNameField(),

                      const SizedBox(height: 20),

                      _buildLabel(
                        'Category',
                      ),

                      const SizedBox(height: 8),

                      _buildCategoryDropdown(),

                      const SizedBox(height: 20),

                      _buildLabel(
                        'Description',
                      ),

                      const SizedBox(height: 8),

                      _buildDescriptionField(),

                      const SizedBox(height: 20),

                      _buildLabel(
                        'Experience Level',
                      ),

                      const SizedBox(height: 10),

                      _buildExperienceSelector(),

                      const SizedBox(height: 20),

                      _buildLabel(
                        'Availability',
                      ),

                      const SizedBox(height: 8),

                      _buildAvailabilityField(),

                      const SizedBox(height: 28),

                      _buildAddButton(),
                    ],
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
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: _borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed:
            _saving
                ? null
                : _confirmDiscardDraft,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color:
              _saving
                  ? _mutedColor
                  : _primaryColor,
            ),
          ),

          Expanded(
            child: Center(
              child: Text(
                'Add Skill',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _textColor,
                ),
              ),
            ),
          ),

          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _buildIntro() {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Share what you can teach with the community.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: _mutedColor,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Image.asset(
          'assets/images/mascot/tubi_explaining.png',
          width: 66,
          height: 66,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _textColor,
      ),
    );
  }

  // ============================================================
  // SKILL NAME
  // ============================================================

  Widget _buildSkillNameField() {
    return TextField(
      controller: _skillNameController,
      enabled: !_saving,
      maxLength: 80,
      textCapitalization:
      TextCapitalization.words,
      style: TextStyle(
        fontSize: 14,
        color: _textColor,
      ),
      onChanged: (
          String value,
          ) {
        if (!mounted) {
          return;
        }

        setState(() {});
      },
      decoration: InputDecoration(
        hintText:
        'e.g. Digital Illustration',
        counterText: '',
        hintStyle: TextStyle(
          fontSize: 13,
          color: _mutedColor,
        ),
        prefixIcon: Icon(
          Icons.lightbulb_outline_rounded,
          size: 19,
          color: _primaryColor,
        ),
        filled: true,
        fillColor: _surfaceColor,
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _borderColor,
          ),
        ),
        disabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _borderColor,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _primaryColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      isExpanded: true,
      dropdownColor: _surfaceColor,
      hint: Text(
        'Select category',
        style: TextStyle(
          fontSize: 13,
          color: _mutedColor,
        ),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: _mutedColor,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.grid_view_rounded,
          size: 18,
          color: _primaryColor,
        ),
        filled: true,
        fillColor: _surfaceColor,
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _borderColor,
          ),
        ),
        disabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _borderColor,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _primaryColor,
          ),
        ),
      ),
      items:
      _categories.map(
            (
            String category,
            ) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(
              category,
              overflow:
              TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: _textColor,
              ),
            ),
          );
        },
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

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _buildDescriptionField() {
    return Stack(
      children: [
        TextField(
          controller:
          _descriptionController,
          enabled: !_saving,
          maxLines: 5,
          maxLength: 200,
          textCapitalization:
          TextCapitalization.sentences,
          style: TextStyle(
            fontSize: 14,
            color: _textColor,
          ),
          decoration: InputDecoration(
            hintText:
            'Tell others what they can learn from you...',
            hintStyle: TextStyle(
              fontSize: 13,
              color: _mutedColor,
            ),
            counterText: '',
            filled: true,
            fillColor: _surfaceColor,
            contentPadding:
            const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              28,
            ),
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide: BorderSide(
                color: _borderColor,
              ),
            ),
            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide: BorderSide(
                color: _borderColor,
              ),
            ),
            disabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide: BorderSide(
                color: _borderColor,
              ),
            ),
            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide: BorderSide(
                color: _primaryColor,
              ),
            ),
          ),
          onChanged: (
              String value,
              ) {
            setState(() {});
          },
        ),

        Positioned(
          right: 12,
          bottom: 10,
          child: Text(
            '${_descriptionController.text.length}/200',
            style: TextStyle(
              fontSize: 11,
              color: _mutedColor,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EXPERIENCE
  // ============================================================

  Widget _buildExperienceSelector() {
    final List<String> levels = [
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
          final bool isSelected =
              _experienceLevel == level;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right:
                level == 'Advanced'
                    ? 0
                    : 8,
              ),
              child: SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed:
                  _saving
                      ? null
                      : () {
                    setState(() {
                      _experienceLevel =
                          level;
                    });
                  },
                  style:
                  OutlinedButton.styleFrom(
                    backgroundColor:
                    isSelected
                        ? _primaryColor
                        : _surfaceColor,
                    foregroundColor:
                    isSelected
                        ? _primaryForeground
                        : _textColor,
                    side: BorderSide(
                      color:
                      isSelected
                          ? _primaryColor
                          : _borderColor,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius
                          .circular(
                        10,
                      ),
                    ),
                    padding:
                    EdgeInsets.zero,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      level,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                        isSelected
                            ? FontWeight
                            .w700
                            : FontWeight
                            .w500,
                      ),
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

  // ============================================================
  // AVAILABILITY
  // ============================================================

  Widget _buildAvailabilityField() {
    return AvailabilityPicker(
      initialValue: _availability,
      enabled: !_saving,
      surfaceColor: _surfaceColor,
      textColor: _textColor,
      primaryColor: _primaryColor,
      mutedColor: _mutedColor,
      borderColor: _borderColor,
      onChanged: (
          String value,
          ) {
        setState(() {
          _availability = value;
        });
      },
    );
  }

  // ============================================================
  // ADD BUTTON
  // ============================================================

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed:
        _saving
            ? null
            : _saveSkill,
        style: ElevatedButton.styleFrom(
          backgroundColor:
          _primaryColor,
          foregroundColor:
          _primaryForeground,
          disabledBackgroundColor:
          _surfaceVariantColor,
          disabledForegroundColor:
          _mutedColor,
          elevation: 0,
          minimumSize:
          const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
        ),
        child:
        _saving
            ? SizedBox(
          width: 20,
          height: 20,
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
            color:
            _primaryForeground,
          ),
        )
            : const Text(
          'ADD SKILL',
          style: TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveSkill() async {
    if (_saving) {
      return;
    }

    final String? selectedCategory =
        _selectedCategory;

    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
    });

    try {
      await _controller.addOfferedSkill(
        title:
        _skillNameController.text,
        category:
        selectedCategory ?? '',
        description:
        _descriptionController.text,
        level:
        _experienceLevel,
        availability:
        _availability,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _allowPop = true;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Skill added successfully!',
            ),
          ),
        );

      Navigator.pop(
        context,
        true,
      );
    } on MySkillsControllerException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showMessage(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showMessage(
        'Could not add the skill. Please try again.',
      );
    }
  }

  // ============================================================
  // FEEDBACK
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }
}