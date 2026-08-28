import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNav = 0;

  static const Color primary = AppTheme.primary;
  static const Color darkText = AppTheme.darkText;
  static const Color mutedText = AppTheme.mutedText;
  static const Color background = AppTheme.background;

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
                padding: const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  24,
                ),
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Joice! 👋',
                style: AppTextStyles.pageTitle,
              ),

              SizedBox(height: 4),

              Text(
                'Ready to share and learn?',
                style: AppTextStyles.secondary,
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

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/explore',
        );
      },
      child: Container(
        height: 50,
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
                style: AppTextStyles.secondary,
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
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required String title,
    String? action,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.sectionTitle,
          ),
        ),

        if (action != null)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (action == 'Explore') {
                Navigator.pushNamed(
                  context,
                  '/explore',
                );
              }

              if (action == 'See all') {
                Navigator.pushNamed(
                  context,
                  '/swap-requests',
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: Text(
                action,
                style: AppTextStyles.caption.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // AI MATCH
  // ============================================================

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
      ),
      child: Column(
        children: [
          Row(
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

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alex Rivera',
                      style: AppTextStyles.cardTitle,
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Video Editing • Advanced',
                      style: AppTextStyles.secondary.copyWith(
                        fontSize: 12,
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
                child: Text(
                  '92% Match',
                  style: AppTextStyles.caption.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/mascot/tubi_happy.png',
                width: 52,
                height: 52,
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'Great fit! You teach Photography, while Alex can teach Video Editing.',
                  style: AppTextStyles.bodyMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text(
                'VIEW MATCH',
                style: AppTextStyles.button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // POPULAR SKILLS
  // ============================================================

  Widget _buildPopularSkills() {
    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: skills.length,
        separatorBuilder: (_, __) {
          return const SizedBox(width: 12);
        },
        itemBuilder: (context, index) {
          final skill = skills[index];

          return InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/explore',
              );
            },
            child: Container(
              width: 132,
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
                    width: 50,
                    height: 50,
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
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // UPCOMING SESSION
  // ============================================================

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

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alex Rivera',
                  style: AppTextStyles.cardTitle,
                ),

                const SizedBox(height: 3),

                Text(
                  'Video Editing Session',
                  style: AppTextStyles.secondary.copyWith(
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Today • 4:00 PM',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          SizedBox(
            width: 100,
            height: 38,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'JOIN CALL',
                style: AppTextStyles.button.copyWith(
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

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
      height: 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFEEEEF5),
          ),
        ),
      ),
      child: Row(
        children: List.generate(
          items.length,
              (index) {
            final bool selected =
                _selectedNav == index;

            return Expanded(
              child: InkWell(
                onTap: () {
                  if (index == 0) {
                    setState(() {
                      _selectedNav = 0;
                    });
                    return;
                  }

                  if (index == 1) {
                    Navigator.pushNamed(
                      context,
                      '/explore',
                    );
                    return;
                  }

                  if (index == 2) {
                    setState(() {
                      _selectedNav = 2;
                    });
                    return;
                  }

                  if (index == 3) {
                    Navigator.pushNamed(
                      context,
                      '/chat',
                    );
                    return;
                  }

                  if (index == 4) {
                    Navigator.pushNamed(
                      context,
                      '/my-skills',
                    );
                    return;
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 180,
                      ),
                      width: 36,
                      height: 29,
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
                        size: 20,
                        color: selected
                            ? primary
                            : const Color(0xFF777C8F),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      items[index]['label'] as String,
                      style: AppTextStyles.navLabel.copyWith(
                        color: selected
                            ? primary
                            : const Color(0xFF777C8F),
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
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