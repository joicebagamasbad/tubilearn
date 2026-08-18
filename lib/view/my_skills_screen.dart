import 'package:flutter/material.dart';
import 'add_skill_screen.dart';
import 'edit_skill_screen.dart';

class MySkillsScreen extends StatefulWidget {
  const MySkillsScreen({super.key});

  @override
  State<MySkillsScreen> createState() => _MySkillsScreenState();
}

class _MySkillsScreenState extends State<MySkillsScreen> {
  static const Color primary = Color(0xFF5B5FEF);
  static const Color darkText = Color(0xFF171A2B);
  static const Color mutedText = Color(0xFF8A8FA3);
  static const Color background = Color(0xFFF9F9FF);
  static const Color border = Color(0xFFE8E8F2);

  final List<Map<String, dynamic>> _skills = [
    {
      'icon': Icons.design_services_outlined,
      'title': 'Graphic Design',
      'level': 'Intermediate',
      'availability': 'Weekends',
      'category': 'Design & Creative',
      'description':
      'Learn the basics of graphic design, layout, color, and typography.',
    },
    {
      'icon': Icons.camera_alt_outlined,
      'title': 'Photography',
      'level': 'Advanced',
      'availability': 'Evenings',
      'category': 'Photography',
      'description':
      'Learn photography basics, composition, lighting, and camera techniques.',
    },
    {
      'icon': Icons.movie_creation_outlined,
      'title': 'Video Editing',
      'level': 'Intermediate',
      'availability': 'Afternoons',
      'category': 'Video & Media',
      'description':
      'Learn basic video editing, transitions, storytelling, and visual effects.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _skills.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: Column(
                  children: [
                    _buildTubiIntro(),
                    const SizedBox(height: 16),

                    ...List.generate(
                      _skills.length,
                          (index) {
                        final skill = _skills[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildSkillCard(
                            index: index,
                            icon: skill['icon'] as IconData,
                            title: skill['title'] as String,
                            level: skill['level'] as String,
                            availability:
                            skill['availability'] as String,
                            category: skill['category'] as String,
                            description:
                            skill['description'] as String,
                          ),
                        );
                      },
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
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: border),
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
                'My Skills',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
            ),
          ),

          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddSkillScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.add_rounded,
              size: 15,
              color: primary,
            ),
            label: const Text(
              'ADD SKILL',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTubiIntro() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage your skills',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Update, add, or review the skills you share.',
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
          'assets/images/mascot/tubi_checking.png',
          width: 66,
          height: 66,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Widget _buildSkillCard({
    required int index,
    required IconData icon,
    required String title,
    required String level,
    required String availability,
    required String category,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: primary,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.bar_chart_rounded,
                          size: 14,
                          color: primary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Level:',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: mutedText,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          level,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: primary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Availability:',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: mutedText,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          availability,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: border),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditSkillScreen(
                        skillName: title,
                        category: category,
                        description: description,
                        experienceLevel: level,
                        availability: availability,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: primary,
                ),
                label: const Text(
                  'EDIT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              TextButton.icon(
                onPressed: () {
                  _showDeleteDialog(
                    index: index,
                    skillName: title,
                  );
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 15,
                  color: Colors.redAccent,
                ),
                label: const Text(
                  'DELETE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog({
    required int index,
    required String skillName,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFEF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
              size: 30,
            ),
          ),
          title: const Text(
            'Delete Skill?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$skillName"? This action cannot be undone.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.5,
              color: mutedText,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                setState(() {
                  _skills.removeAt(index);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$skillName deleted.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(90, 40),
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/mascot/tubi_confused.png',
              width: 130,
              height: 130,
            ),
            const SizedBox(height: 15),
            const Text(
              'No skills yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Add a skill you can share with the TubiLearn community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.5,
                color: mutedText,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddSkillScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(140, 44),
              ),
              child: const Text(
                'ADD A SKILL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}