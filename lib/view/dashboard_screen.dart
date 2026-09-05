import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
  });

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  int _selectedNav = 0;

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

  Color get _softPrimaryColor =>
      _isDarkMode
          ? _primaryColor.withValues(
        alpha: 0.16,
      )
          : const Color(
        0xFFE4F0EF,
      );

  Color get _skillCardColor =>
      _isDarkMode
          ? _surfaceVariantColor
          : const Color(
        0xFFF1F5F3,
      );

  Color get _skillCardBorderColor =>
      _isDarkMode
          ? _borderColor
          : const Color(
        0xFFDCE6E2,
      );

  Color get _skillIconBackground =>
      _isDarkMode
          ? _surfaceColor
          : const Color(
        0xFFFFFFFF,
      );

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      Theme.of(context)
          .scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics:
                const BouncingScrollPhysics(),
                padding:
                const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  24,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(
                      height: 20,
                    ),
                    _buildSearchBar(),
                    const SizedBox(
                      height: 24,
                    ),
                    _buildSectionHeader(
                      title:
                      '✦ Your AI Match',
                      action:
                      'See all',
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    _buildMatchCard(),
                    const SizedBox(
                      height: 28,
                    ),
                    _buildSectionHeader(
                      title:
                      'Popular Skills',
                      action:
                      'Explore',
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    _buildPopularSkills(),
                    const SizedBox(
                      height: 28,
                    ),
                    _buildSectionHeader(
                      title:
                      'Upcoming Session',
                    ),
                    const SizedBox(
                      height: 12,
                    ),
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
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Joice! 👋',
                style:
                AppTextStyles.pageTitle
                    .copyWith(
                  color:
                  _textColor,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                'Ready to share and learn?',
                style:
                AppTextStyles.secondary
                    .copyWith(
                  color:
                  _mutedColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration:
          BoxDecoration(
            color:
            _surfaceColor,
            borderRadius:
            BorderRadius.circular(
              12,
            ),
            border:
            Border.all(
              color:
              _borderColor,
            ),
          ),
          child: Icon(
            Icons
                .notifications_none_rounded,
            size: 21,
            color:
            _textColor,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Container(
          width: 42,
          height: 42,
          decoration:
          const BoxDecoration(
            color:
            AppTheme.accent,
            shape:
            BoxShape.circle,
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
      borderRadius:
      BorderRadius.circular(
        14,
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/explore',
        );
      },
      child: Container(
        height: 50,
        decoration:
        BoxDecoration(
          color:
          _surfaceColor,
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          border:
          Border.all(
            color:
            _borderColor,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
            ),
            Icon(
              Icons.search,
              color:
              _mutedColor,
              size: 20,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                'Search skills or people',
                style:
                AppTextStyles.secondary
                    .copyWith(
                  color:
                  _mutedColor,
                ),
              ),
            ),
            Icon(
              Icons
                  .filter_list_rounded,
              color:
              _primaryColor,
              size: 20,
            ),
            const SizedBox(
              width: 14,
            ),
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
            style:
            AppTextStyles.sectionTitle
                .copyWith(
              color:
              _textColor,
            ),
          ),
        ),
        if (action != null)
          InkWell(
            borderRadius:
            BorderRadius.circular(
              8,
            ),
            onTap: () {
              if (action ==
                  'Explore') {
                Navigator.pushNamed(
                  context,
                  '/explore',
                );
              }

              if (action ==
                  'See all') {
                Navigator.pushNamed(
                  context,
                  '/swap-requests',
                );
              }
            },
            child: Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: Text(
                action,
                style:
                AppTextStyles.caption
                    .copyWith(
                  color:
                  _primaryColor,
                  fontWeight:
                  FontWeight.w700,
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
      padding:
      const EdgeInsets.all(
        14,
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                const BoxDecoration(
                  color:
                  AppTheme.accent,
                  shape:
                  BoxShape.circle,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alex Rivera',
                      style:
                      AppTextStyles
                          .cardTitle
                          .copyWith(
                        color:
                        _textColor,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      'Video Editing • Advanced',
                      style:
                      AppTextStyles
                          .secondary
                          .copyWith(
                        fontSize: 12,
                        color:
                        _mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                BoxDecoration(
                  color:
                  _softPrimaryColor,
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  '92% Match',
                  style:
                  AppTextStyles
                      .caption
                      .copyWith(
                    color:
                    _primaryColor,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/mascot/tubi_happy.png',
                width: 52,
                height: 52,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  'Great fit! You teach Photography, while Alex can teach Video Editing.',
                  style:
                  AppTextStyles
                      .bodyMuted
                      .copyWith(
                    color:
                    _mutedColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text(
                'VIEW MATCH',
                style:
                AppTextStyles.button,
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
        scrollDirection:
        Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        itemCount:
        skills.length,
        separatorBuilder:
            (_, _) {
          return const SizedBox(
            width: 12,
          );
        },
        itemBuilder: (
            context,
            index,
            ) {
          final Map<String, dynamic>
          skill =
          skills[index];

          return InkWell(
            borderRadius:
            BorderRadius.circular(
              17,
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/explore',
              );
            },
            child: Container(
              width: 132,
              padding:
              const EdgeInsets.all(
                14,
              ),
              decoration:
              BoxDecoration(
                color:
                _skillCardColor,
                borderRadius:
                BorderRadius.circular(
                  17,
                ),
                border:
                Border.all(
                  color:
                  _skillCardBorderColor,
                ),
              ),
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration:
                    BoxDecoration(
                      color:
                      _skillIconBackground,
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                      border:
                      Border.all(
                        color:
                        _borderColor,
                      ),
                    ),
                    child: Icon(
                      skill['icon']
                      as IconData,
                      color:
                      _primaryColor,
                      size: 25,
                    ),
                  ),
                  const SizedBox(
                    height: 11,
                  ),
                  Text(
                    skill['title']
                    as String,
                    maxLines: 1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    textAlign:
                    TextAlign.center,
                    style:
                    AppTextStyles
                        .cardTitle
                        .copyWith(
                      fontSize: 13,
                      color:
                      _textColor,
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
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        _surfaceColor,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border:
        Border.all(
          color:
          _borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration:
            const BoxDecoration(
              color:
              AppTheme.accent,
              shape:
              BoxShape.circle,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Alex Rivera',
                  style:
                  AppTextStyles
                      .cardTitle
                      .copyWith(
                    color:
                    _textColor,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  'Video Editing Session',
                  style:
                  AppTextStyles
                      .secondary
                      .copyWith(
                    fontSize: 12,
                    color:
                    _mutedColor,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  'Today • 4:00 PM',
                  style:
                  AppTextStyles
                      .caption
                      .copyWith(
                    color:
                    _mutedColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            height: 38,
            child:
            ElevatedButton(
              onPressed: () {},
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                _primaryColor,
                foregroundColor:
                _isDarkMode
                    ? const Color(
                  0xFF092E31,
                )
                    : Colors.white,
                padding:
                EdgeInsets.zero,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
              ),
              child: Text(
                'JOIN CALL',
                style:
                AppTextStyles
                    .button
                    .copyWith(
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
    final List<Map<String, dynamic>>
    items = [
      {
        'icon':
        Icons.home_outlined,
        'selected':
        Icons.home_rounded,
        'label':
        'Home',
      },
      {
        'icon':
        Icons.explore_outlined,
        'selected':
        Icons.explore,
        'label':
        'Explore',
      },
      {
        'icon':
        Icons.auto_awesome_outlined,
        'selected':
        Icons.auto_awesome,
        'label':
        'AI Match',
      },
      {
        'icon':
        Icons
            .chat_bubble_outline_rounded,
        'selected':
        Icons
            .chat_bubble_rounded,
        'label':
        'Chat',
      },
      {
        'icon':
        Icons.person_outline_rounded,
        'selected':
        Icons.person_rounded,
        'label':
        'Profile',
      },
    ];

    return Container(
      height: 76,
      decoration:
      BoxDecoration(
        color:
        _isDarkMode
            ? Theme.of(context)
            .scaffoldBackgroundColor
            : _surfaceColor,
        border:
        Border(
          top:
          BorderSide(
            color:
            _borderColor,
          ),
        ),
      ),
      child: Row(
        children:
        List.generate(
          items.length,
              (
              int index,
              ) {
            final bool selected =
                _selectedNav ==
                    index;

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
                      '/profile',
                    );

                    return;
                  }
                },
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration:
                      const Duration(
                        milliseconds:
                        180,
                      ),
                      width: 36,
                      height: 29,
                      decoration:
                      BoxDecoration(
                        color:
                        selected
                            ? _softPrimaryColor
                            : Colors
                            .transparent,
                        borderRadius:
                        BorderRadius
                            .circular(
                          12,
                        ),
                      ),
                      child: Icon(
                        selected
                            ? items[index][
                        'selected']
                        as IconData
                            : items[index][
                        'icon']
                        as IconData,
                        size: 20,
                        color:
                        selected
                            ? _primaryColor
                            : _mutedColor,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      items[index]
                      ['label']
                      as String,
                      style:
                      AppTextStyles
                          .navLabel
                          .copyWith(
                        color:
                        selected
                            ? _primaryColor
                            : _mutedColor,
                        fontWeight:
                        selected
                            ? FontWeight
                            .w700
                            : FontWeight
                            .w600,
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