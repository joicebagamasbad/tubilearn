import 'package:flutter/material.dart';

import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../theme/app_theme.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
  });

  @override
  State<ExploreScreen> createState() =>
      _ExploreScreenState();
}

class _ExploreScreenState
    extends State<ExploreScreen> {
  static const Color primary = AppTheme.primary;
  static const Color darkText = AppTheme.darkText;
  static const Color mutedText = AppTheme.mutedText;
  static const Color background = AppTheme.background;
  static const Color border = AppTheme.border;

  final ExploreRepository _repository =
  ExploreRepository();

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
    'Music',
  ];

  List<Skill> get _filteredSkills {
    final String query =
    _searchQuery.trim().toLowerCase();

    return _repository.skills.where(
          (skill) {
        final bool matchesCategory =
            _selectedCategory == 'All' ||
                skill.category ==
                    _selectedCategory;

        final bool matchesSearch =
            query.isEmpty ||
                skill.title
                    .toLowerCase()
                    .contains(query) ||
                skill.category
                    .toLowerCase()
                    .contains(query) ||
                skill.level
                    .toLowerCase()
                    .contains(query) ||
                skill.description
                    .toLowerCase()
                    .contains(query);

        return matchesCategory &&
            matchesSearch;
      },
    ).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final List<Skill> skills =
        _filteredSkills;

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
                  18,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _buildTubiIntro(),

                    const SizedBox(
                      height: 18,
                    ),

                    _buildSearchBar(),

                    const SizedBox(
                      height: 22,
                    ),

                    const Text(
                      'Browse Categories',
                      style:
                      AppTextStyles.cardTitle,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _buildCategories(),

                    const SizedBox(
                      height: 26,
                    ),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Skills For You',
                            style:
                            AppTextStyles.cardTitle,
                          ),
                        ),

                        Text(
                          '${skills.length} skills',
                          style:
                          AppTextStyles.caption,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    if (skills.isEmpty)
                      _buildNoResults()
                    else
                      ...skills.map(
                            (skill) =>
                            Padding(
                              padding:
                              const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child:
                              _buildSkillCard(
                                skill,
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

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 62,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration:
      const BoxDecoration(
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
              Navigator.pop(
                context,
              );
            },
            icon: const Icon(
              Icons
                  .arrow_back_ios_new_rounded,
              size: 18,
              color: primary,
            ),
          ),

          const Expanded(
            child: Center(
              child: Text(
                'Explore',
                style:
                AppTextStyles.cardTitle,
              ),
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons
                  .favorite_border_rounded,
              size: 20,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TUBI INTRO
  // ============================================================

  Widget _buildTubiIntro() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        16,
        14,
        10,
        14,
      ),
      decoration: BoxDecoration(
        color:
        const Color(
          0xFFF1EFFF,
        ),
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
          const Color(
            0xFFE4E0FF,
          ),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover something new',
                  style:
                  AppTextStyles.cardTitle,
                ),

                SizedBox(
                  height: 5,
                ),

                Text(
                  'Find practical skills and people willing to exchange knowledge with you.',
                  style:
                  AppTextStyles.secondary,
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

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

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          13,
        ),
        border: Border.all(
          color:
          border,
        ),
      ),
      child: TextField(
        controller:
        _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery =
                value;
          });
        },
        style:
        AppTextStyles.input,
        decoration:
        InputDecoration(
          hintText:
          'Search skills or topics',
          hintStyle:
          AppTextStyles.inputHint,

          prefixIcon:
          const Icon(
            Icons.search_rounded,
            color: mutedText,
            size: 20,
          ),

          suffixIcon:
          _searchQuery.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController
                  .clear();

              setState(() {
                _searchQuery =
                '';
              });
            },
            icon:
            const Icon(
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

          border:
          InputBorder.none,

          enabledBorder:
          InputBorder.none,

          focusedBorder:
          InputBorder.none,

          filled:
          false,
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Widget _buildCategories() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection:
        Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        itemCount:
        _categories.length,

        separatorBuilder:
            (context, index) {
          return const SizedBox(
            width: 8,
          );
        },

        itemBuilder:
            (context, index) {
          final String category =
          _categories[index];

          final bool selected =
              _selectedCategory ==
                  category;

          return InkWell(
            borderRadius:
            BorderRadius.circular(
              20,
            ),
            onTap: () {
              setState(() {
                _selectedCategory =
                    category;
              });
            },
            child:
            AnimatedContainer(
              duration:
              const Duration(
                milliseconds: 180,
              ),
              padding:
              const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              alignment:
              Alignment.center,
              decoration:
              BoxDecoration(
                color: selected
                    ? primary
                    : Colors.white,
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                border: Border.all(
                  color: selected
                      ? primary
                      : border,
                ),
              ),
              child: Text(
                category,
                style:
                AppTextStyles.caption
                    .copyWith(
                  color: selected
                      ? Colors.white
                      : darkText,
                  fontWeight:
                  selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SKILL CARD
  // ============================================================

  Widget _buildSkillCard(
      Skill skill,
      ) {
    final int providerCount =
        _repository
            .getProvidersForSkill(
          skill.id,
        ).length;

    return InkWell(
      borderRadius:
      BorderRadius.circular(
        16,
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/skill-details',
          arguments:
          skill,
        );
      },
      child: Container(
        width:
        double.infinity,
        padding:
        const EdgeInsets.all(
          14,
        ),
        decoration:
        BoxDecoration(
          color:
          Colors.white,
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          border:
          Border.all(
            color:
            border,
          ),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withValues(
                alpha: 0.025,
              ),
              blurRadius:
              10,
              offset:
              const Offset(
                0,
                4,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width:
              58,
              height:
              58,
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFF2F0FF,
                ),
                borderRadius:
                BorderRadius.circular(
                  15,
                ),
              ),
              child: Icon(
                skill.icon,
                color:
                primary,
                size:
                28,
              ),
            ),

            const SizedBox(
              width: 13,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.title,
                    style:
                    AppTextStyles.cardTitle,
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    skill.category,
                    style:
                    AppTextStyles.caption,
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Row(
                    children: [
                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          const Color(
                            0xFFF2F0FF,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: Text(
                          skill.level,
                          style:
                          AppTextStyles.caption
                              .copyWith(
                            color:
                            primary,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 9,
                      ),

                      const Icon(
                        Icons
                            .people_outline_rounded,
                        size: 13,
                        color: mutedText,
                      ),

                      const SizedBox(
                        width: 4,
                      ),

                      Expanded(
                        child: Text(
                          '$providerCount provider${providerCount == 1 ? '' : 's'}',
                          style:
                          AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .arrow_forward_ios_rounded,
              size:
              14,
              color:
              mutedText,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildNoResults() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 20,
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/mascot/tubi_thinking.png',
            width:
            90,
            height:
            90,
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            'No skills found',
            style:
            AppTextStyles.cardTitle,
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'We couldn\'t find anything for "$_searchQuery".',
            textAlign:
            TextAlign.center,
            style:
            AppTextStyles.secondary,
          ),
        ],
      ),
    );
  }
}