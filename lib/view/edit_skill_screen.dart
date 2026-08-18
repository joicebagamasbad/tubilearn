import 'package:flutter/material.dart';

class EditSkillScreen extends StatefulWidget {
  final String skillName;
  final String category;
  final String description;
  final String experienceLevel;
  final String availability;

  const EditSkillScreen({
    super.key,
    required this.skillName,
    required this.category,
    required this.description,
    required this.experienceLevel,
    required this.availability,
  });

  @override
  State<EditSkillScreen> createState() => _EditSkillScreenState();
}

class _EditSkillScreenState extends State<EditSkillScreen> {
  static const Color primary = Color(0xFF5B5FEF);
  static const Color darkText = Color(0xFF171A2B);
  static const Color mutedText = Color(0xFF8A8FA3);
  static const Color background = Color(0xFFF9F9FF);
  static const Color border = Color(0xFFE8E8F2);

  final TextEditingController _skillNameController =
  TextEditingController();

  final TextEditingController _descriptionController =
  TextEditingController();

  late String _category;
  late String _experienceLevel;
  late String _availability;

  final List<String> _categories = [
    'Design & Creative',
    'Photography',
    'Video & Media',
    'Technology',
    'Education',
    'Music',
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

    _category = widget.category;
    _experienceLevel = widget.experienceLevel;
    _availability = widget.availability;

    if (!_categories.contains(_category)) {
      _categories.insert(0, _category);
    }

    if (!_availabilityOptions.contains(_availability)) {
      _availabilityOptions.insert(0, _availability);
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

                    _buildLabel('Experience Level'),

                    const SizedBox(height: 10),

                    _buildExperienceLevel(),

                    const SizedBox(height: 18),

                    _buildLabel('Availability'),

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
            onPressed: () {
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
  // TUBI INTRO
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
                'Update the details of the skill you want to improve.',
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

  // ============================================================
  // LABEL
  // ============================================================

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
  // SKILL NAME
  // ============================================================

  Widget _buildSkillNameField() {
    return TextField(
      controller: _skillNameController,

      // EDITABLE
      readOnly: false,

      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: darkText,
      ),

      decoration: InputDecoration(
        // EXISTING NAME = PLACEHOLDER ONLY
        hintText: widget.skillName,

        hintStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: mutedText,
        ),

        prefixIcon: const Icon(
          Icons.lightbulb_outline_rounded,
          size: 19,
          color: primary,
        ),

        filled: true,
        fillColor: Colors.white,

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
    return Container(
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
            Icons.grid_view_rounded,
            size: 18,
            color: primary,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _category,
                isExpanded: true,

                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: mutedText,
                ),

                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: darkText,
                ),

                items: _categories.map(
                      (category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(
                        category,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ).toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _category = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
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

          // EDITABLE
          readOnly: false,

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
            // EXISTING DESCRIPTION = PLACEHOLDER ONLY
            hintText: widget.description,

            hintStyle: const TextStyle(
              fontSize: 11,
              height: 1.5,
              color: mutedText,
            ),

            counterText: '',

            filled: true,
            fillColor: Colors.white,

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
                width: 1.3,
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
    final levels = [
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
                right:
                index == levels.length - 1
                    ? 0
                    : 5,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  10,
                ),

                onTap: () {
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
                    color:
                    selected
                        ? primary
                        : Colors.white,

                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),

                    border: Border.all(
                      color:
                      selected
                          ? primary
                          : border,
                    ),
                  ),

                  child: Text(
                    level,
                    style: TextStyle(
                      fontSize: 9,

                      fontWeight:
                      selected
                          ? FontWeight.w700
                          : FontWeight.w500,

                      color:
                      selected
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

      onTap: _showAvailabilitySheet,

      child: Container(
        height: 50,

        padding: const EdgeInsets.symmetric(
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

  // ============================================================
  // UPDATE BUTTON
  // ============================================================

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,

      child: ElevatedButton(
        onPressed: () {
          // If user didn't type a new value,
          // keep the old placeholder value.
          final String updatedSkillName =
          _skillNameController.text.trim().isEmpty
              ? widget.skillName
              : _skillNameController.text.trim();

          final String updatedDescription =
          _descriptionController.text.trim().isEmpty
              ? widget.description
              : _descriptionController.text.trim();

          // Temporary preview until database is connected.
          debugPrint(
            'Updated Skill: $updatedSkillName',
          );

          debugPrint(
            'Updated Description: $updatedDescription',
          );

          debugPrint(
            'Category: $_category',
          );

          debugPrint(
            'Level: $_experienceLevel',
          );

          debugPrint(
            'Availability: $_availability',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Skill updated successfully!',
              ),
              duration: Duration(seconds: 1),
            ),
          );

          Future.delayed(
            const Duration(
              milliseconds: 500,
            ),
                () {
              if (mounted) {
                Navigator.pop(context);
              }
            },
          );
        },

        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,

          minimumSize: const Size(
            0,
            48,
          ),

          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
        ),

        child: const Text(
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
  // AVAILABILITY BOTTOM SHEET
  // ============================================================

  void _showAvailabilitySheet() {
    showModalBottomSheet(
      context: context,

      backgroundColor:
      Colors.transparent,

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

            borderRadius:
            BorderRadius.vertical(
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

                  borderRadius:
                  BorderRadius.circular(20),
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
                    contentPadding:
                    EdgeInsets.zero,

                    title: Text(
                      option,

                      style: TextStyle(
                        fontSize: 12,

                        fontWeight:
                        selected
                            ? FontWeight.w700
                            : FontWeight.w500,

                        color: darkText,
                      ),
                    ),

                    trailing:
                    selected
                        ? const Icon(
                      Icons
                          .check_circle_rounded,
                      color: primary,
                    )
                        : null,

                    onTap: () {
                      setState(() {
                        _availability = option;
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
}