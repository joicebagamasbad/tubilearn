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

  bool get _isDarkMode =>
      Theme.of(context).brightness ==
          Brightness.dark;

  Color get _primaryColor =>
      Theme.of(context).colorScheme.primary;

  Color get _surfaceColor =>
      Theme.of(context).colorScheme.surface;

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

  Color get _softPrimaryBorderColor =>
      _isDarkMode
          ? _primaryColor.withValues(
        alpha: 0.28,
      )
          : const Color(
        0xFFD2E5E2,
      );

  List<Skill> get _filteredSkills {
    final String query =
    _searchQuery.trim().toLowerCase();

    return _repository.skills.where(
          (
          Skill skill,
          ) {
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
      backgroundColor:
      Theme.of(context)
          .scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child:
              SingleChildScrollView(
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
                    Text(
                      'Browse Categories',
                      style:
                      AppTextStyles.cardTitle
                          .copyWith(
                        color:
                        _textColor,
                      ),
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
                        Expanded(
                          child: Text(
                            'Skills For You',
                            style:
                            AppTextStyles.cardTitle
                                .copyWith(
                              color:
                              _textColor,
                            ),
                          ),
                        ),
                        Text(
                          '${skills.length} skills',
                          style:
                          AppTextStyles.caption
                              .copyWith(
                            color:
                            _mutedColor,
                          ),
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
                            (
                            Skill skill,
                            ) =>
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
      BoxDecoration(
        color:
        _surfaceColor,
        border:
        Border(
          bottom:
          BorderSide(
            color:
            _borderColor,
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
            icon:
            Icon(
              Icons
                  .arrow_back_ios_new_rounded,
              size: 18,
              color:
              _primaryColor,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Explore',
                style:
                AppTextStyles.cardTitle
                    .copyWith(
                  color:
                  _textColor,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon:
            Icon(
              Icons.favorite_border_rounded,
              size: 20,
              color:
              _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _buildTubiIntro() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        16,
        14,
        10,
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        _softPrimaryColor,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color:
          _softPrimaryBorderColor,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover something new',
                  style:
                  AppTextStyles.cardTitle
                      .copyWith(
                    color:
                    _textColor,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  'Find practical skills and people willing to exchange knowledge with you.',
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
      decoration:
      BoxDecoration(
        color:
        _surfaceColor,
        borderRadius:
        BorderRadius.circular(
          13,
        ),
        border:
        Border.all(
          color:
          _borderColor,
        ),
      ),
      child: TextField(
        controller:
        _searchController,
        onChanged: (
            String value,
            ) {
          setState(() {
            _searchQuery =
                value;
          });
        },
        style:
        AppTextStyles.input
            .copyWith(
          color:
          _textColor,
        ),
        decoration:
        InputDecoration(
          hintText:
          'Search skills or topics',
          hintStyle:
          AppTextStyles.inputHint
              .copyWith(
            color:
            _mutedColor,
          ),
          prefixIcon:
          Icon(
            Icons.search_rounded,
            color:
            _mutedColor,
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
            icon: Icon(
              Icons.close_rounded,
              color:
              _mutedColor,
              size: 18,
            ),
          )
              : Icon(
            Icons.tune_rounded,
            color:
            _primaryColor,
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
      child:
      ListView.separated(
        scrollDirection:
        Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        itemCount:
        _categories.length,
        separatorBuilder:
            (
            BuildContext context,
            int index,
            ) {
          return const SizedBox(
            width: 8,
          );
        },
        itemBuilder:
            (
            BuildContext context,
            int index,
            ) {
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
                color:
                selected
                    ? _primaryColor
                    : _surfaceColor,
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                border:
                Border.all(
                  color:
                  selected
                      ? _primaryColor
                      : _borderColor,
                ),
              ),
              child:
              Text(
                category,
                style:
                AppTextStyles.caption
                    .copyWith(
                  color:
                  selected
                      ? _isDarkMode
                      ? const Color(
                    0xFF092E31,
                  )
                      : Colors.white
                      : _textColor,
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
        )
            .length;

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
          boxShadow: [
            BoxShadow(
              color:
              Colors.black
                  .withValues(
                alpha:
                _isDarkMode
                    ? 0.12
                    : 0.025,
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
              width: 58,
              height: 58,
              decoration:
              BoxDecoration(
                color:
                _softPrimaryColor,
                borderRadius:
                BorderRadius.circular(
                  15,
                ),
                border:
                Border.all(
                  color:
                  _softPrimaryBorderColor,
                ),
              ),
              child: Icon(
                skill.icon,
                color:
                _primaryColor,
                size: 28,
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
                    AppTextStyles.cardTitle
                        .copyWith(
                      color:
                      _textColor,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    skill.category,
                    style:
                    AppTextStyles.caption
                        .copyWith(
                      color:
                      _mutedColor,
                    ),
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
                          _softPrimaryColor,
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
                            _primaryColor,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 9,
                      ),
                      Icon(
                        Icons.people_outline_rounded,
                        size: 13,
                        color:
                        _mutedColor,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Expanded(
                        child: Text(
                          '$providerCount provider${providerCount == 1 ? '' : 's'}',
                          style:
                          AppTextStyles.caption
                              .copyWith(
                            color:
                            _mutedColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color:
              _mutedColor,
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
            width: 90,
            height: 90,
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            'No skills found',
            style:
            AppTextStyles.cardTitle
                .copyWith(
              color:
              _textColor,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            'We couldn\'t find anything for "$_searchQuery".',
            textAlign:
            TextAlign.center,
            style:
            AppTextStyles.secondary
                .copyWith(
              color:
              _mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}