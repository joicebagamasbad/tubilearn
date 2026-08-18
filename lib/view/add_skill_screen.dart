import 'package:flutter/material.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({super.key});

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  static const Color primary = Color(0xFF5B5FEF);
  static const Color darkText = Color(0xFF171A2B);
  static const Color mutedText = Color(0xFF8A8FA3);
  static const Color background = Color(0xFFF9F9FF);
  static const Color border = Color(0xFFE8E8F2);

  final TextEditingController _skillNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedCategory;
  String _experienceLevel = 'Intermediate';
  String _availability = 'Weekends';

  final List<String> _categories = [
    'Design & Creative',
    'Technology',
    'Photography',
    'Video & Media',
    'Music',
    'Language',
  ];

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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntro(),

                    const SizedBox(height: 22),

                    _buildLabel('Skill Name'),

                    const SizedBox(height: 8),

                    _buildTextField(
                      controller: _skillNameController,
                      hintText: 'e.g. Photography',
                      icon: Icons.lightbulb_outline_rounded,
                    ),

                    const SizedBox(height: 20),

                    _buildLabel('Category'),

                    const SizedBox(height: 8),

                    _buildCategoryDropdown(),

                    const SizedBox(height: 20),

                    _buildLabel('Description'),

                    const SizedBox(height: 8),

                    _buildDescriptionField(),

                    const SizedBox(height: 20),

                    _buildLabel('Experience Level'),

                    const SizedBox(height: 10),

                    _buildExperienceSelector(),

                    const SizedBox(height: 20),

                    _buildLabel('Availability'),

                    const SizedBox(height: 8),

                    _buildAvailabilitySelector(),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Skill added successfully!'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'ADD SKILL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
                'Add Skill',
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

  Widget _buildIntro() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 12,
        color: darkText,
      ),
      decoration: InputDecoration(
        hintText: hintText,
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

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
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
      ),
      items: _categories.map((category) {
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
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
    );
  }

  Widget _buildDescriptionField() {
    return Stack(
      children: [
        TextField(
          controller: _descriptionController,
          maxLines: 5,
          maxLength: 200,
          style: const TextStyle(
            fontSize: 12,
            color: darkText,
          ),
          decoration: InputDecoration(
            hintText: 'Tell others what they can learn from you...',
            hintStyle: const TextStyle(
              fontSize: 11,
              color: mutedText,
            ),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              28,
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

  Widget _buildExperienceSelector() {
    final levels = [
      'Beginner',
      'Intermediate',
      'Advanced',
    ];

    return Row(
      children: levels.map((level) {
        final isSelected = _experienceLevel == level;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: level == 'Advanced' ? 0 : 8,
            ),
            child: SizedBox(
              height: 42,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _experienceLevel = level;
                  });
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                  isSelected ? primary : Colors.white,
                  foregroundColor:
                  isSelected ? Colors.white : darkText,
                  side: BorderSide(
                    color: isSelected
                        ? primary
                        : border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvailabilitySelector() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        _showAvailabilitySheet();
      },
      child: Container(
        height: 48,
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
    final options = [
      'Weekdays',
      'Weekends',
      'Evenings',
      'Flexible',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 18),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose Availability',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              ...options.map(
                    (option) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  trailing: _availability == option
                      ? const Icon(
                    Icons.check_circle_rounded,
                    color: primary,
                  )
                      : null,
                  onTap: () {
                    setState(() {
                      _availability = option;
                    });

                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}