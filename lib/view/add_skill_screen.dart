import 'package:flutter/material.dart';

import '../model/repositories/my_skills_repository.dart';
import '../services/current_user_service.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({
    super.key,
  });

  @override
  State<AddSkillScreen> createState() =>
      _AddSkillScreenState();
}

class _AddSkillScreenState
    extends State<AddSkillScreen> {
  static const Color primary =
  Color(0xFF5B5FEF);

  static const Color darkText =
  Color(0xFF171A2B);

  static const Color mutedText =
  Color(0xFF8A8FA3);

  static const Color background =
  Color(0xFFF9F9FF);

  static const Color border =
  Color(0xFFE8E8F2);

  final MySkillsRepository _repository =
      MySkillsRepository.instance;

  final CurrentUserService _currentUser =
      CurrentUserService.instance;

  final TextEditingController
  _skillNameController =
  TextEditingController();

  final TextEditingController
  _descriptionController =
  TextEditingController();

  String? _selectedCategory;

  String _experienceLevel =
      'Intermediate';

  String _availability =
      'Weekends';

  bool _saving = false;

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

  final List<String>
  _availabilityOptions = [
    'Weekdays',
    'Weekends',
    'Mornings',
    'Afternoons',
    'Evenings',
    'Flexible',
  ];

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
    return Scaffold(
      backgroundColor: background,
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

                    _buildAvailabilitySelector(),

                    const SizedBox(height: 28),

                    _buildAddButton(),
                  ],
                ),
              ),
            ),
          ],
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: border,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _saving
                ? null
                : () {
              Navigator.pop(
                context,
              );
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: primary,
            ),
          ),

          const Expanded(
            child: Center(
              child: Text(
                'Add Skill',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w800,
                  color: darkText,
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
        const Expanded(
          child: Text(
            'Share what you can teach with the community.',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: mutedText,
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

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(
      String text,
      ) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: darkText,
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
      enabled: !_saving,
      maxLength: 80,
      style: const TextStyle(
        fontSize: 12,
        color: darkText,
      ),
      decoration: InputDecoration(
        hintText:
        'e.g. Digital Illustration',
        counterText: '',
        hintStyle: const TextStyle(
          fontSize: 11,
          color: mutedText,
        ),
        prefixIcon: const Icon(
          Icons.lightbulb_outline_rounded,
          size: 19,
          color: primary,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide:
          const BorderSide(
            color: border,
          ),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide:
          const BorderSide(
            color: border,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide:
          const BorderSide(
            color: primary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<
        String>(
      initialValue:
      _selectedCategory,
      hint: const Text(
        'Select category',
        style: TextStyle(
          fontSize: 11,
          color: mutedText,
        ),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: mutedText,
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.grid_view_rounded,
          size: 18,
          color: primary,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide:
          const BorderSide(
            color: border,
          ),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide:
          const BorderSide(
            color: border,
          ),
        ),
      ),
      items: _categories.map(
            (category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 11,
                color: darkText,
              ),
            ),
          );
        },
      ).toList(),
      onChanged: _saving
          ? null
          : (value) {
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
          style: const TextStyle(
            fontSize: 12,
            color: darkText,
          ),
          decoration: InputDecoration(
            hintText:
            'Tell others what they can learn from you...',
            hintStyle:
            const TextStyle(
              fontSize: 11,
              color: mutedText,
            ),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
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
                12,
              ),
              borderSide:
              const BorderSide(
                color: border,
              ),
            ),
            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              const BorderSide(
                color: border,
              ),
            ),
            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              const BorderSide(
                color: primary,
              ),
            ),
          ),
          onChanged: (_) {
            setState(() {});
          },
        ),

        Positioned(
          right: 12,
          bottom: 10,
          child: Text(
            '${_descriptionController.text.length}/200',
            style: const TextStyle(
              fontSize: 9,
              color: mutedText,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EXPERIENCE LEVEL
  // ============================================================

  Widget _buildExperienceSelector() {
    final List<String> levels = [
      'Beginner',
      'Intermediate',
      'Advanced',
    ];

    return Row(
      children: levels.map(
            (level) {
          final bool isSelected =
              _experienceLevel ==
                  level;

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
                  onPressed: _saving
                      ? null
                      : () {
                    setState(() {
                      _experienceLevel =
                          level;
                    });
                  },
                  style:
                  OutlinedButton
                      .styleFrom(
                    backgroundColor:
                    isSelected
                        ? primary
                        : Colors.white,
                    foregroundColor:
                    isSelected
                        ? Colors.white
                        : darkText,
                    side: BorderSide(
                      color:
                      isSelected
                          ? primary
                          : border,
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
                  child: Text(
                    level,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight:
                      isSelected
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

  // ============================================================
  // AVAILABILITY
  // ============================================================

  Widget _buildAvailabilitySelector() {
    return InkWell(
      borderRadius:
      BorderRadius.circular(12),
      onTap: _saving
          ? null
          : _showAvailabilitySheet,
      child: Container(
        height: 48,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(12),
          border: Border.all(
            color: border,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 19,
              color: primary,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                _availability,
                style: const TextStyle(
                  fontSize: 11,
                  color: darkText,
                ),
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: mutedText,
            ),
          ],
        ),
      ),
    );
  }

  void _showAvailabilitySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
      Colors.white,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (
          sheetContext,
          ) {
        return Padding(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            28,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              const Align(
                alignment:
                Alignment.centerLeft,
                child: Text(
                  'Choose Availability',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w800,
                    color: darkText,
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              ..._availabilityOptions.map(
                    (option) {
                  return ListTile(
                    contentPadding:
                    EdgeInsets.zero,
                    title: Text(
                      option,
                      style:
                      const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    trailing:
                    _availability ==
                        option
                        ? const Icon(
                      Icons
                          .check_circle_rounded,
                      color:
                      primary,
                    )
                        : null,
                    onTap: () {
                      setState(() {
                        _availability =
                            option;
                      });

                      Navigator.pop(
                        sheetContext,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // BUTTON
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
        style:
        ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor:
          Colors.white,
          elevation: 0,
          minimumSize:
          const Size(
            0,
            48,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              12,
            ),
          ),
        ),
        child: _saving
            ? const SizedBox(
          width: 20,
          height: 20,
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text(
          'ADD SKILL',
          style: TextStyle(
            fontSize: 11,
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
    final String title =
    _skillNameController.text
        .trim();

    final String description =
    _descriptionController.text
        .trim();

    if (title.isEmpty) {
      _showMessage(
        'Please enter a skill name.',
      );

      return;
    }

    if (_selectedCategory ==
        null) {
      _showMessage(
        'Please select a category.',
      );

      return;
    }

    if (description.isEmpty) {
      _showMessage(
        'Please add a short description.',
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _repository
          .addOfferedSkill(
        userId:
        _currentUser.userId,
        title: title,
        category:
        _selectedCategory!,
        description:
        description,
        level:
        _experienceLevel,
        availability:
        _availability,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
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
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showMessage(
        error.toString(),
      );
    }
  }

  void _showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }
}