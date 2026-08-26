import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const Color primary = Color(0xFF5B5FEF);
  static const Color darkText = Color(0xFF171A2B);
  static const Color mutedText = Color(0xFF8A8FA3);
  static const Color background = Color(0xFFF9F9FF);
  static const Color border = Color(0xFFE8E8F2);

  final TextEditingController _searchController =
  TextEditingController();

  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Design',
    'Photography',
    'Technology',
    'Video',
    'Communication',
  ];

  final List<Map<String, dynamic>> _skills = [
    {
      'title': 'Graphic Design',
      'category': 'Design',
      'level': 'Beginner–Intermediate',
      'icon': Icons.design_services_outlined,
      'sessionLength': '45–60 mins',
      'mode': 'Online / Meetup',
      'language': 'Filipino / English',
      'prerequisite':
      'A phone, tablet, or laptop. Canva is enough for beginners.',
      'description':
      'Learn practical graphic design for school projects, social media posts, small businesses, presentations, and basic branding.',
      'learnings': [
        'Basic layout and visual hierarchy',
        'Color combinations and typography',
        'Creating posters and social media graphics',
        'Using Canva efficiently',
      ],
      'providers': [
        {
          'name': 'Mika Santos',
          'initials': 'MS',
          'city': 'Tarlac City',
          'level': 'Intermediate',
          'rating': 4.8,
          'completedSwaps': 12,
          'wantsToLearn': 'Basic Excel',
          'availability': 'Weekends • 2:00 PM onwards',
          'language': 'Filipino / English',
        },
        {
          'name': 'Paolo Reyes',
          'initials': 'PR',
          'city': 'Angeles City',
          'level': 'Advanced',
          'rating': 4.9,
          'completedSwaps': 21,
          'wantsToLearn': 'Photography',
          'availability': 'Weekday evenings',
          'language': 'Filipino / English',
        },
      ],
    },

    {
      'title': 'Photography',
      'category': 'Photography',
      'level': 'Beginner–Intermediate',
      'icon': Icons.camera_alt_outlined,
      'sessionLength': '45–60 mins',
      'mode': 'Online / Meetup',
      'language': 'Filipino / English',
      'prerequisite':
      'Any smartphone or camera. A DSLR or mirrorless camera is not required.',
      'description':
      'Learn practical photography using equipment you already have, from smartphone cameras to dedicated cameras.',
      'learnings': [
        'Composition and framing',
        'Using natural and available light',
        'Basic camera or smartphone settings',
        'Simple photo editing and color correction',
      ],
      'providers': [
        {
          'name': 'Alex Rivera',
          'initials': 'AR',
          'city': 'Mabalacat City',
          'level': 'Advanced',
          'rating': 4.9,
          'completedSwaps': 18,
          'wantsToLearn': 'Graphic Design',
          'availability': 'Saturday afternoons',
          'language': 'Filipino / English',
        },
        {
          'name': 'Bea Mendoza',
          'initials': 'BM',
          'city': 'Tarlac City',
          'level': 'Intermediate',
          'rating': 4.7,
          'completedSwaps': 9,
          'wantsToLearn': 'Video Editing',
          'availability': 'Sunday mornings',
          'language': 'Filipino / English',
        },
      ],
    },

    {
      'title': 'Video Editing',
      'category': 'Video',
      'level': 'Beginner–Intermediate',
      'icon': Icons.movie_creation_outlined,
      'sessionLength': '60 mins',
      'mode': 'Online',
      'language': 'Filipino / English',
      'prerequisite':
      'A smartphone or computer capable of running CapCut, VN, Premiere Pro, or a similar editor.',
      'description':
      'Learn practical video editing for school requirements, short-form content, personal projects, and small business promotion.',
      'learnings': [
        'Trimming and arranging clips',
        'Basic transitions and pacing',
        'Audio, captions, and simple effects',
        'Export settings for social media',
      ],
      'providers': [
        {
          'name': 'Carlo Dela Cruz',
          'initials': 'CD',
          'city': 'Quezon City',
          'level': 'Advanced',
          'rating': 4.8,
          'completedSwaps': 16,
          'wantsToLearn': 'English Conversation',
          'availability': 'Weekday evenings',
          'language': 'Filipino / English',
        },
        {
          'name': 'Jamie Garcia',
          'initials': 'JG',
          'city': 'San Fernando, Pampanga',
          'level': 'Intermediate',
          'rating': 4.7,
          'completedSwaps': 8,
          'wantsToLearn': 'Canva Design',
          'availability': 'Saturday evenings',
          'language': 'Filipino / English',
        },
      ],
    },

    {
      'title': 'UI/UX Design',
      'category': 'Design',
      'level': 'Beginner',
      'icon': Icons.dashboard_customize_outlined,
      'sessionLength': '60 mins',
      'mode': 'Online',
      'language': 'Filipino / English',
      'prerequisite':
      'A laptop or desktop computer. No prior Figma experience required.',
      'description':
      'Learn how to plan and design simple mobile or web interfaces with a focus on usability rather than decoration alone.',
      'learnings': [
        'Basic UI and UX principles',
        'Wireframes and screen planning',
        'Using Figma for simple interfaces',
        'Building consistent layouts and components',
      ],
      'providers': [
        {
          'name': 'Nico Villanueva',
          'initials': 'NV',
          'city': 'Manila',
          'level': 'Intermediate',
          'rating': 4.8,
          'completedSwaps': 14,
          'wantsToLearn': 'Public Speaking',
          'availability': 'Sunday afternoons',
          'language': 'Filipino / English',
        },
      ],
    },

    {
      'title': 'Basic Web Development',
      'category': 'Technology',
      'level': 'Beginner',
      'icon': Icons.code_rounded,
      'sessionLength': '60–90 mins',
      'mode': 'Online',
      'language': 'Filipino / English',
      'prerequisite':
      'A laptop or desktop computer and willingness to practice between sessions.',
      'description':
      'Learn the foundations of building simple websites using HTML, CSS, and basic programming concepts.',
      'learnings': [
        'HTML page structure',
        'Basic CSS styling',
        'Simple responsive layouts',
        'How websites and browsers work',
      ],
      'providers': [
        {
          'name': 'Joshua Lim',
          'initials': 'JL',
          'city': 'Cebu City',
          'level': 'Intermediate',
          'rating': 4.9,
          'completedSwaps': 20,
          'wantsToLearn': 'Basic Guitar',
          'availability': 'Weekday evenings',
          'language': 'Filipino / English',
        },
      ],
    },

    {
      'title': 'English Conversation',
      'category': 'Communication',
      'level': 'Beginner–Intermediate',
      'icon': Icons.record_voice_over_outlined,
      'sessionLength': '30–45 mins',
      'mode': 'Online / Meetup',
      'language': 'English with Filipino support',
      'prerequisite':
      'No formal requirement. Best for learners who want more confidence speaking English.',
      'description':
      'Practice everyday English conversation in a low-pressure setting for school, work, interviews, and daily communication.',
      'learnings': [
        'Conversational vocabulary',
        'Speaking with more confidence',
        'Common grammar corrections',
        'Interview and presentation practice',
      ],
      'providers': [
        {
          'name': 'Andrea Flores',
          'initials': 'AF',
          'city': 'Baguio City',
          'level': 'Advanced',
          'rating': 4.9,
          'completedSwaps': 23,
          'wantsToLearn': 'Video Editing',
          'availability': 'Weekday evenings',
          'language': 'English / Filipino',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredSkills {
    return _skills.where((skill) {
      final String query =
      _searchQuery.toLowerCase().trim();

      final String title =
      (skill['title'] as String).toLowerCase();

      final String category =
      (skill['category'] as String).toLowerCase();

      final String level =
      (skill['level'] as String).toLowerCase();

      final String description =
      (skill['description'] as String).toLowerCase();

      final bool matchesCategory =
          _selectedCategory == 'All' ||
              skill['category'] == _selectedCategory;

      final bool matchesSearch =
          query.isEmpty ||
              title.contains(query) ||
              category.contains(query) ||
              level.contains(query) ||
              description.contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                    _buildTubiIntro(),

                    const SizedBox(height: 18),

                    _buildSearchBar(),

                    const SizedBox(height: 22),

                    const Text(
                      'Browse Categories',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildCategories(),

                    const SizedBox(height: 26),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Skills For You',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: darkText,
                            ),
                          ),
                        ),

                        Text(
                          '${_filteredSkills.length} skills',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (_filteredSkills.isEmpty)
                      _buildNoResults()
                    else
                      ..._filteredSkills.map(
                            (skill) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildSkillCard(skill),
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
      height: 62,
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
                'Explore',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.favorite_border_rounded,
              size: 20,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTubiIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        10,
        14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE4E0FF),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover something new',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Find practical skills and people willing to exchange knowledge with you.',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.45,
                    color: mutedText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Image.asset(
            'assets/images/mascot/tubi_studying.png',
            width: 82,
            height: 82,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: border,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(
          fontSize: 11,
          color: darkText,
        ),
        decoration: InputDecoration(
          hintText: 'Search skills or topics',
          hintStyle: const TextStyle(
            fontSize: 10.5,
            color: mutedText,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: mutedText,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController.clear();

              setState(() {
                _searchQuery = '';
              });
            },
            icon: const Icon(
              Icons.close_rounded,
              color: mutedText,
              size: 18,
            ),
          )
              : const Icon(
            Icons.tune_rounded,
            color: primary,
            size: 19,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final String category =
          _categories[index];

          final bool selected =
              _selectedCategory == category;

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 180,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? primary
                      : border,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : darkText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkillCard(
      Map<String, dynamic> skill,
      ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/skill-details',
          arguments: skill,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.025,
              ),
              blurRadius: 10,
              offset: const Offset(
                0,
                4,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F0FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                skill['icon'] as IconData,
                color: primary,
                size: 28,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill['title'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: darkText,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    skill['category'] as String,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: mutedText,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F0FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          skill['level'] as String,
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ),

                      const SizedBox(width: 9),

                      const Icon(
                        Icons.schedule_outlined,
                        size: 13,
                        color: mutedText,
                      ),

                      const SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          skill['sessionLength'] as String,
                          style: const TextStyle(
                            fontSize: 8.5,
                            color: mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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

  Widget _buildNoResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 20,
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/mascot/tubi_thinking.png',
            width: 90,
            height: 90,
          ),

          const SizedBox(height: 12),

          const Text(
            'No skills found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'We couldn\'t find anything for "$_searchQuery".',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: mutedText,
            ),
          ),
        ],
      ),
    );
  }
}