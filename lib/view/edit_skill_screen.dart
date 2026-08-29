import 'package:flutter/material.dart';

import '../model/repositories/my_skills_repository.dart';
import '../services/current_user_service.dart';

class EditSkillScreen extends StatefulWidget {
  final ManagedSkill managedSkill;

  const EditSkillScreen({
    super.key,
    required this.managedSkill,
  });

  @override
  State<EditSkillScreen> createState() =>
      _EditSkillScreenState();
}

class _EditSkillScreenState extends State<EditSkillScreen> {
  static const Color primary = Color(0xFF5B5FEF);
  static const Color darkText = Color(0xFF171A2B);
  static const Color mutedText = Color(0xFF8A8FA3);
  static const Color background = Color(0xFFF9F9FF);
  static const Color border = Color(0xFFE8E8F2);

  final MySkillsRepository _repository =
      MySkillsRepository.instance;

  final CurrentUserService _currentUser =
      CurrentUserService.instance;

  late final TextEditingController _skillNameController;
  late final TextEditingController _descriptionController;

  late String _category;
  late String _experienceLevel;
  late String _availability;
  late bool _canEditMetadata;

  bool _saving = false;

  final List<String> _categories = [
    'Design & Creative',
    'Photography',
    'Video & Media',
    'Technology',
    'Education',
    'Music',
    'Language',
    'Lifestyle',
  ];

  final List<String> _availabilityOptions = [
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

    final skill = widget.managedSkill.skill;
    final userSkill = widget.managedSkill.userSkill;

    _skillNameController = TextEditingController(
      text: skill.title,
    );

    _descriptionController = TextEditingController(
      text: skill.description,
    );

    _category = skill.category;
    _experienceLevel = userSkill.level;
    _availability = userSkill.availability;

    _canEditMetadata =
        widget.managedSkill.metadataCanBeEditedBy(
          _currentUser.userId,
        );

    if (!_categories.contains(_category)) {
      _categories.insert(
        0,
        _category,
      );
    }

    if (!_availabilityOptions.contains(_availability)) {
      _availabilityOptions.insert(
        0,
        _availability,
      );
    }
  }

  @override
  void dispose() {
    _skillNameController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntro(),

                    if (!_canEditMetadata)
                      _buildSharedSkillNotice(),

                    const SizedBox(height: 20),

                    _buildLabel('Skill Name'),
                    const SizedBox(height: 8),
                    _buildSkillNameField(),

                    const SizedBox(height: 18),

                    _buildLabel('Category'),
                    const SizedBox(height: 8),
                    _buildCategoryField(),

                    const SizedBox(height: 18),

                    _buildLabel('Description'),
                    const SizedBox(height: 8),
                    _buildDescriptionField(),

                    const SizedBox(height: 18),

                    _buildLabel('Your Experience Level'),
                    const SizedBox(height: 10),
                    _buildExperienceLevel(),

                    const SizedBox(height: 18),

                    _buildLabel('Your Availability'),
                    const SizedBox(height: 8),
                    _buildAvailabilityField(),

                    const SizedBox(height: 24),

                    _buildUpdateButton(),
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
      height: 64,
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
              Navigator.pop(context);
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
                'Edit Skill',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update your skill',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Keep your teaching details accurate and up to date.',
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.4,
                  color: mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Image.asset(
          'assets/images/mascot/tubi_planning.png',
          width: 68,
          height: 68,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Widget _buildSharedSkillNotice() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 14,
      ),
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE3DEFF),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: primary,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'This is a shared TubiLearn skill. Its name, category, and description are shared with other users, so you can only update your level and availability.',
              style: TextStyle(
                fontSize: 9.5,
                height: 1.45,
                color: darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
    );
  }

  // ============================================================
  // NAME
  // ============================================================

  Widget _buildSkillNameField() {
    return TextField(
      controller: _skillNameController,
      readOnly: !_canEditMetadata || _saving,
      maxLength: 80,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: darkText,
      ),
      decoration: InputDecoration(
        counterText: '',
        prefixIcon: const Icon(
          Icons.lightbulb_outline_rounded,
          size: 19,
          color: primary,
        ),
        suffixIcon: !_canEditMetadata
            ? const Icon(
          Icons.lock_outline_rounded,
          size: 16,
          color: mutedText,
        )
            : null,
        filled: true,
        fillColor: _canEditMetadata
            ? Colors.white
            : const Color(0xFFF5F5FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      isExpanded: true,
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
        fillColor: _canEditMetadata
            ? Colors.white
            : const Color(0xFFF5F5FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
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
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: darkText,
              ),
            ),
          );
        },
      ).toList(),
      onChanged: !_canEditMetadata || _saving
          ? null
          : (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _category = value;
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
          controller: _descriptionController,
          readOnly: !_canEditMetadata || _saving,
          maxLines: 5,
          maxLength: 200,
          style: const TextStyle(
            fontSize: 11,
            height: 1.5,
            color: darkText,
          ),
          onChanged: (_) {
            setState(() {});
          },
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: _canEditMetadata
                ? Colors.white
                : const Color(0xFFF5F5FA),
            contentPadding: const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              30,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: primary,
              ),
            ),
          ),
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

  Widget _buildExperienceLevel() {
    final List<String> levels = [
      'Beginner',
      'Intermediate',
      'Advanced',
    ];

    return Row(
      children: List.generate(
        levels.length,
            (index) {
          final String level = levels[index];
          final bool selected =
              _experienceLevel == level;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 5,
                right: index == levels.length - 1 ? 0 : 5,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _saving
                    ? null
                    : () {
                  setState(() {
                    _experienceLevel = level;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? primary
                          : border,
                    ),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : darkText,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // AVAILABILITY
  // ============================================================

  Widget _buildAvailabilityField() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _saving
          ? null
          : _showAvailabilitySheet,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: border,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _availability,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: darkText,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
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
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            28,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose availability',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ..._availabilityOptions.map(
                    (option) {
                  final bool selected =
                      _availability == option;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: darkText,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                      Icons.check_circle_rounded,
                      color: primary,
                    )
                        : null,
                    onTap: () {
                      setState(() {
                        _availability = option;
                      });

                      Navigator.pop(sheetContext);
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
  // UPDATE BUTTON
  // ============================================================

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _saving
            ? null
            : _updateSkill,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(
            0,
            48,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _saving
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text(
          'UPDATE SKILL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> _updateSkill() async {
    final String title =
    _skillNameController.text.trim();

    final String description =
    _descriptionController.text.trim();

    if (title.isEmpty) {
      _showMessage(
        'Skill name is required.',
      );

      return;
    }

    if (description.isEmpty) {
      _showMessage(
        'Description is required.',
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _repository.updateOfferedSkill(
        userId: _currentUser.userId,
        userSkillId:
        widget.managedSkill.userSkill.id,
        title: title,
        category: _category,
        description: description,
        level: _experienceLevel,
        availability: _availability,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Skill updated successfully!',
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}