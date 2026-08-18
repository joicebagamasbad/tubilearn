import 'package:flutter/material.dart';
import 'add_skill_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNav = 0;

  static const Color primary = Color(0xFF5B5FEF);
  static const Color darkText = Color(0xFF171A2B);
  static const Color mutedText = Color(0xFF8A8FA3);
  static const Color background = Color(0xFFF9F9FF);

  final List<Map<String, dynamic>> skills = [
    {
      'title': 'Graphic Design',
      'icon': Icons.design_services_outlined,
    },
    {
      'title': 'Photography',
      'icon': Icons.camera_alt_outlined,
    },
    {
      'title': 'Video Editing',
      'icon': Icons.movie_creation_outlined,
    },
    {
      'title': 'Illustration',
      'icon': Icons.brush_outlined,
    },
    {
      'title': 'UI/UX Design',
      'icon': Icons.dashboard_customize_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildSearchBar(),
                    const SizedBox(height: 24),

                    _buildSectionHeader(
                      title: '✦ Your AI Match',
                      action: 'See all',
                    ),

                    const SizedBox(height: 12),
                    _buildMatchCard(),

                    const SizedBox(height: 28),

                    _buildSectionHeader(
                      title: 'Popular Skills',
                      action: 'Explore',
                    ),

                    const SizedBox(height: 14),
                    _buildPopularSkills(),

                    const SizedBox(height: 28),

                    _buildSectionHeader(
                      title: 'Upcoming Session',
                    ),

                    const SizedBox(height: 12),
                    _buildUpcomingSession(),
                  ],
                ),
              ),
            ),

            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Joice! 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Ready to share and learn?',
                style: TextStyle(
                  fontSize: 12,
                  color: mutedText,
                ),
              ),
            ],
          ),
        ),

        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            size: 21,
            color: darkText,
          ),
        ),

        const SizedBox(width: 10),

        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFFFAA45),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE9E9F3),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(width: 14),

          Icon(
            Icons.search,
            color: mutedText,
            size: 20,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Search skills or people',
              style: TextStyle(
                color: mutedText,
                fontSize: 12,
              ),
            ),
          ),

          Icon(
            Icons.filter_list_rounded,
            color: primary,
            size: 20,
          ),

          SizedBox(width: 14),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? action,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
          ),
        ),

        if (action != null)
          Text(
            action,
            style: const TextStyle(
              color: primary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildMatchCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEAEAF4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFAA45),
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alex Rivera',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Video Editing • Advanced',
                      style: TextStyle(
                        fontSize: 10,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EFFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '92% Match',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Image.asset(
                'assets/images/mascot/tubi_happy.png',
                width: 52,
                height: 52,
                fit: BoxFit.contain,
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'Great fit! You teach Photography, while Alex can teach Video Editing.',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.45,
                    color: Color(0xFF666B80),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'VIEW MATCH',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSkills() {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: skills.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 12);
        },
        itemBuilder: (context, index) {
          final skill = skills[index];

          return Container(
            width: 125,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F2FF),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: const Color(0xFFE5E1FF),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    skill['icon'] as IconData,
                    color: primary,
                    size: 25,
                  ),
                ),

                const SizedBox(height: 11),

                Text(
                  skill['title'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingSession() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAEAF4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFFFAA45),
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alex Rivera',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Video Editing Session',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: mutedText,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Today • 4:00 PM',
                  style: TextStyle(
                    fontSize: 9,
                    color: mutedText,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: 92,
            height: 34,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(92, 34),
                maximumSize: const Size(92, 34),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'JOIN CALL',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final items = [
      {
        'icon': Icons.home_outlined,
        'selected': Icons.home_rounded,
        'label': 'Home',
      },
      {
        'icon': Icons.explore_outlined,
        'selected': Icons.explore,
        'label': 'Explore',
      },
      {
        'icon': Icons.auto_awesome_outlined,
        'selected': Icons.auto_awesome,
        'label': 'AI Match',
      },
      {
        'icon': Icons.chat_bubble_outline_rounded,
        'selected': Icons.chat_bubble_rounded,
        'label': 'Chat',
      },
      {
        'icon': Icons.person_outline_rounded,
        'selected': Icons.person_rounded,
        'label': 'Profile',
      },
    ];

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFEEEEF5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(
          items.length,
              (index) {
            final bool selected = _selectedNav == index;

            return Expanded(
              child: InkWell(
                onTap: () {
                  if (index == 1) {
                    Navigator.pushNamed(context, '/add-skill');
                    return;
                  }

                  if (index == 4) {
                    Navigator.pushNamed(context, '/my-skills');
                    return;
                  }

                  setState(() {
                    _selectedNav = index;
                  });
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 180,
                      ),
                      width: 34,
                      height: 28,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFF0EFFF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        selected
                            ? items[index]['selected'] as IconData
                            : items[index]['icon'] as IconData,
                        size: 19,
                        color: selected
                            ? primary
                            : const Color(0xFF777C8F),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      items[index]['label'] as String,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? primary
                            : const Color(0xFF777C8F),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}