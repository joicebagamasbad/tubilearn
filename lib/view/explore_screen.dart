import 'package:flutter/material.dart';

import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/user.dart';
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
      ExploreRepository.instance;

  final TextEditingController _searchController =
  TextEditingController();

  String _selectedCategory = 'All';
  String _searchQuery = '';

  String _selectedMode = 'Any';
  String _selectedCity = 'Any';
  String _sortOption = 'A-Z';

  bool _isRefreshing = false;

  final List<String> _modeOptions = const [
    'Any',
    'Online',
    'In-person',
  ];

  final List<String> _sortOptions = const [
    'A-Z',
    'Most Providers',
    'Highest Rated',
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

  Color get _softPrimaryBorderColor =>
      _isDarkMode
          ? _primaryColor.withValues(
        alpha: 0.28,
      )
          : const Color(
        0xFFD2E5E2,
      );

  // ============================================================
  // FILTER OPTIONS
  // ============================================================

  List<String> get _categories {
    final Set<String> categories =
    <String>{};

    for (final Skill skill
    in _repository.skills) {
      final String category =
      skill.category.trim();

      if (category.isNotEmpty) {
        categories.add(
          category,
        );
      }
    }

    final List<String> sorted =
    categories.toList()
      ..sort(
            (
            String first,
            String second,
            ) =>
            first
                .toLowerCase()
                .compareTo(
              second.toLowerCase(),
            ),
      );

    return <String>[
      'All',
      ...sorted,
    ];
  }

  List<String> get _cities {
    final Set<String> cities =
    <String>{};

    for (final Skill skill
    in _repository.skills) {
      final List<User> providers =
      _repository.getProvidersForSkill(
        skill.id,
      );

      for (final User user
      in providers) {
        final String city =
        user.city.trim();

        if (city.isNotEmpty) {
          cities.add(
            city,
          );
        }
      }
    }

    final List<String> sorted =
    cities.toList()
      ..sort(
            (
            String first,
            String second,
            ) =>
            first
                .toLowerCase()
                .compareTo(
              second.toLowerCase(),
            ),
      );

    return <String>[
      'Any',
      ...sorted,
    ];
  }

  int get _activeFilterCount {
    int count = 0;

    if (_selectedCategory != 'All') {
      count++;
    }

    if (_selectedMode != 'Any') {
      count++;
    }

    if (_selectedCity != 'Any') {
      count++;
    }

    if (_sortOption != 'A-Z') {
      count++;
    }

    return count;
  }

  bool get _hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
          _activeFilterCount > 0;

  // ============================================================
  // FILTERING
  // ============================================================

  List<Skill> get _filteredSkills {
    final String query =
    _searchQuery
        .trim()
        .toLowerCase();

    final List<Skill> results =
    _repository.skills.where(
          (
          Skill skill,
          ) {
        final List<User> providers =
        _repository
            .getProvidersForSkill(
          skill.id,
        );

        final bool matchesCategory =
            _selectedCategory == 'All' ||
                skill.category.trim() ==
                    _selectedCategory;

        final bool matchesSearch =
            query.isEmpty ||
                _skillMatchesSearch(
                  skill,
                  query,
                ) ||
                providers.any(
                      (
                      User provider,
                      ) =>
                      _providerMatchesSearch(
                        provider,
                        query,
                      ),
                );

        final bool matchesMode =
            _selectedMode == 'Any' ||
                _supportsMode(
                  skill.mode,
                  _selectedMode,
                ) ||
                providers.any(
                      (
                      User provider,
                      ) =>
                      _supportsMode(
                        provider.preferredMode,
                        _selectedMode,
                      ),
                );

        final bool matchesCity =
            _selectedCity == 'Any' ||
                providers.any(
                      (
                      User provider,
                      ) =>
                  provider.city
                      .trim()
                      .toLowerCase() ==
                      _selectedCity
                          .trim()
                          .toLowerCase(),
                );

        return matchesCategory &&
            matchesSearch &&
            matchesMode &&
            matchesCity;
      },
    ).toList();

    _sortSkills(
      results,
    );

    return results;
  }

  bool _skillMatchesSearch(
      Skill skill,
      String query,
      ) {
    final List<String> searchable =
    <String>[
      skill.title,
      skill.category,
      skill.level,
      skill.description,
      skill.mode,
      skill.language,
      skill.prerequisite,
      ...skill.learnings,
    ];

    return searchable.any(
          (
          String value,
          ) =>
          value
              .toLowerCase()
              .contains(
            query,
          ),
    );
  }

  bool _providerMatchesSearch(
      User provider,
      String query,
      ) {
    final List<String> searchable =
    <String>[
      provider.name,
      provider.city,
      provider.bio,
      provider.availability,
      provider.language,
      provider.preferredMode,
      provider.teachingStyle,
    ];

    return searchable.any(
          (
          String value,
          ) =>
          value
              .toLowerCase()
              .contains(
            query,
          ),
    );
  }

  bool _supportsMode(
      String rawValue,
      String selectedMode,
      ) {
    final String value =
    rawValue
        .trim()
        .toLowerCase();

    if (value.isEmpty) {
      return false;
    }

    if (value.contains(
      'both',
    ) ||
        value.contains(
          'either',
        )) {
      return true;
    }

    if (selectedMode == 'Online') {
      return value.contains(
        'online',
      );
    }

    if (selectedMode == 'In-person') {
      return value.contains(
        'in-person',
      ) ||
          value.contains(
            'in person',
          );
    }

    return true;
  }

  void _sortSkills(
      List<Skill> skills,
      ) {
    switch (_sortOption) {
      case 'Most Providers':
        skills.sort(
              (
              Skill first,
              Skill second,
              ) {
            final int firstCount =
                _repository
                    .getProvidersForSkill(
                  first.id,
                )
                    .length;

            final int secondCount =
                _repository
                    .getProvidersForSkill(
                  second.id,
                )
                    .length;

            final int providerComparison =
            secondCount.compareTo(
              firstCount,
            );

            if (providerComparison != 0) {
              return providerComparison;
            }

            return first.title
                .toLowerCase()
                .compareTo(
              second.title
                  .toLowerCase(),
            );
          },
        );

        break;

      case 'Highest Rated':
        skills.sort(
              (
              Skill first,
              Skill second,
              ) {
            final double firstRating =
            _highestProviderRating(
              first,
            );

            final double secondRating =
            _highestProviderRating(
              second,
            );

            final int ratingComparison =
            secondRating.compareTo(
              firstRating,
            );

            if (ratingComparison != 0) {
              return ratingComparison;
            }

            return first.title
                .toLowerCase()
                .compareTo(
              second.title
                  .toLowerCase(),
            );
          },
        );

        break;

      case 'A-Z':
      default:
        skills.sort(
              (
              Skill first,
              Skill second,
              ) =>
              first.title
                  .toLowerCase()
                  .compareTo(
                second.title
                    .toLowerCase(),
              ),
        );
    }
  }

  double _highestProviderRating(
      Skill skill,
      ) {
    final List<User> providers =
    _repository.getProvidersForSkill(
      skill.id,
    );

    if (providers.isEmpty) {
      return 0;
    }

    double highest = 0;

    for (final User provider
    in providers) {
      if (provider.rating >
          highest) {
        highest =
            provider.rating;
      }
    }

    return highest;
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshExplore() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _repository.refresh();

      if (!mounted) {
        return;
      }

      final List<String> categories =
          _categories;

      final List<String> cities =
          _cities;

      setState(() {
        if (!categories.contains(
          _selectedCategory,
        )) {
          _selectedCategory =
          'All';
        }

        if (!cities.contains(
          _selectedCity,
        )) {
          _selectedCity =
          'Any';
        }
      });
    } on ExploreRepositoryException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Explore could not be refreshed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // ============================================================
  // RESET
  // ============================================================

  void _resetFilters() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _selectedMode = 'Any';
      _selectedCity = 'Any';
      _sortOption = 'A-Z';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

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
              child: RefreshIndicator(
                onRefresh:
                _refreshExplore,
                color:
                _primaryColor,
                child: SingleChildScrollView(
                  physics:
                  const AlwaysScrollableScrollPhysics(
                    parent:
                    BouncingScrollPhysics(),
                  ),
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

                      _buildSearchAndFilter(),

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
                        height: 22,
                      ),

                      _buildFilterSummary(),

                      const SizedBox(
                        height: 18,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Skills For You',
                              style:
                              AppTextStyles
                                  .cardTitle
                                  .copyWith(
                                color:
                                _textColor,
                              ),
                            ),
                          ),
                          Text(
                            '${skills.length} skill${skills.length == 1 ? '' : 's'}',
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
            tooltip:
            'Back',
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
            tooltip:
            'Refresh',
            onPressed:
            _isRefreshing
                ? null
                : _refreshExplore,
            icon:
            _isRefreshing
                ? SizedBox(
              width: 18,
              height: 18,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color:
                _primaryColor,
              ),
            )
                : Icon(
              Icons.refresh_rounded,
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
  // SEARCH + FILTER
  // ============================================================

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child:
          _buildSearchBar(),
        ),

        const SizedBox(
          width: 10,
        ),

        _buildFilterButton(),
      ],
    );
  }

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
        textInputAction:
        TextInputAction.search,
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
          'Search skills or people',
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
            tooltip:
            'Clear search',
            onPressed: () {
              _searchController
                  .clear();

              setState(() {
                _searchQuery =
                '';
              });
            },
            icon:
            Icon(
              Icons.close_rounded,
              color:
              _mutedColor,
              size: 18,
            ),
          )
              : null,
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

  Widget _buildFilterButton() {
    final int count =
        _activeFilterCount;

    return Stack(
      clipBehavior:
      Clip.none,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: OutlinedButton(
            onPressed:
            _openFilters,
            style:
            OutlinedButton.styleFrom(
              padding:
              EdgeInsets.zero,
              side:
              BorderSide(
                color:
                count > 0
                    ? _primaryColor
                    : _borderColor,
              ),
              backgroundColor:
              count > 0
                  ? _softPrimaryColor
                  : _surfaceColor,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  13,
                ),
              ),
            ),
            child:
            Icon(
              Icons.tune_rounded,
              size: 21,
              color:
              count > 0
                  ? _primaryColor
                  : _mutedColor,
            ),
          ),
        ),

        if (count > 0)
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              width: 20,
              height: 20,
              alignment:
              Alignment.center,
              decoration:
              BoxDecoration(
                shape:
                BoxShape.circle,
                color:
                _primaryColor,
                border:
                Border.all(
                  color:
                  Theme.of(context)
                      .scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: Text(
                '$count',
                style:
                TextStyle(
                  fontSize: 9,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  _isDarkMode
                      ? const Color(
                    0xFF092E31,
                  )
                      : Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // FILTER SHEET
  // ============================================================

  Future<void> _openFilters() async {
    String temporaryMode =
        _selectedMode;

    String temporaryCity =
        _selectedCity;

    String temporarySort =
        _sortOption;

    final List<String> cities =
        _cities;

    await showModalBottomSheet<void>(
      context:
      context,
      isScrollControlled:
      true,
      backgroundColor:
      Colors.transparent,
      builder: (
          BuildContext sheetContext,
          ) {
        return StatefulBuilder(
          builder: (
              BuildContext context,
              StateSetter setSheetState,
              ) {
            return SafeArea(
              top: false,
              child: Container(
                padding:
                EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  20 +
                      MediaQuery.of(
                        sheetContext,
                      ).viewInsets.bottom,
                ),
                decoration:
                BoxDecoration(
                  color:
                  _surfaceColor,
                  borderRadius:
                  const BorderRadius.vertical(
                    top:
                    Radius.circular(
                      26,
                    ),
                  ),
                ),
                child:
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration:
                          BoxDecoration(
                            color:
                            _borderColor,
                            borderRadius:
                            BorderRadius.circular(
                              20,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Explore Filters',
                              style:
                              AppTextStyles
                                  .cardTitle
                                  .copyWith(
                                color:
                                _textColor,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                temporaryMode =
                                'Any';

                                temporaryCity =
                                'Any';

                                temporarySort =
                                'A-Z';
                              });
                            },
                            child:
                            const Text(
                              'RESET',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      Text(
                        'Session mode',
                        style:
                        AppTextStyles.caption
                            .copyWith(
                          color:
                          _textColor,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 9,
                      ),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                        _modeOptions.map(
                              (
                              String mode,
                              ) {
                            final bool selected =
                                temporaryMode ==
                                    mode;

                            return ChoiceChip(
                              label:
                              Text(
                                mode,
                              ),
                              selected:
                              selected,
                              showCheckmark:
                              false,
                              onSelected: (_) {
                                setSheetState(() {
                                  temporaryMode =
                                      mode;
                                });
                              },
                              selectedColor:
                              _primaryColor,
                              backgroundColor:
                              _surfaceVariantColor,
                              side:
                              BorderSide(
                                color:
                                selected
                                    ? _primaryColor
                                    : _borderColor,
                              ),
                              labelStyle:
                              TextStyle(
                                fontSize: 12,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                selected
                                    ? (_isDarkMode
                                    ? const Color(
                                  0xFF092E31,
                                )
                                    : Colors.white)
                                    : _textColor,
                              ),
                            );
                          },
                        ).toList(),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      Text(
                        'Provider city',
                        style:
                        AppTextStyles.caption
                            .copyWith(
                          color:
                          _textColor,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 9,
                      ),

                      Container(
                        width:
                        double.infinity,
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 13,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          _surfaceVariantColor,
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
                        child:
                        DropdownButtonHideUnderline(
                          child:
                          DropdownButton<String>(
                            value:
                            cities.contains(
                              temporaryCity,
                            )
                                ? temporaryCity
                                : 'Any',
                            isExpanded:
                            true,
                            dropdownColor:
                            _surfaceColor,
                            icon:
                            Icon(
                              Icons
                                  .keyboard_arrow_down_rounded,
                              color:
                              _mutedColor,
                            ),
                            style:
                            TextStyle(
                              fontSize: 13,
                              color:
                              _textColor,
                            ),
                            items:
                            cities.map(
                                  (
                                  String city,
                                  ) =>
                                  DropdownMenuItem<String>(
                                    value:
                                    city,
                                    child:
                                    Text(
                                      city,
                                      overflow:
                                      TextOverflow.ellipsis,
                                    ),
                                  ),
                            ).toList(),
                            onChanged: (
                                String? value,
                                ) {
                              if (value ==
                                  null) {
                                return;
                              }

                              setSheetState(() {
                                temporaryCity =
                                    value;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      Text(
                        'Sort results',
                        style:
                        AppTextStyles.caption
                            .copyWith(
                          color:
                          _textColor,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 9,
                      ),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                        _sortOptions.map(
                              (
                              String option,
                              ) {
                            final bool selected =
                                temporarySort ==
                                    option;

                            return ChoiceChip(
                              label:
                              Text(
                                option,
                              ),
                              selected:
                              selected,
                              showCheckmark:
                              false,
                              onSelected: (_) {
                                setSheetState(() {
                                  temporarySort =
                                      option;
                                });
                              },
                              selectedColor:
                              _primaryColor,
                              backgroundColor:
                              _surfaceVariantColor,
                              side:
                              BorderSide(
                                color:
                                selected
                                    ? _primaryColor
                                    : _borderColor,
                              ),
                              labelStyle:
                              TextStyle(
                                fontSize: 12,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                selected
                                    ? (_isDarkMode
                                    ? const Color(
                                  0xFF092E31,
                                )
                                    : Colors.white)
                                    : _textColor,
                              ),
                            );
                          },
                        ).toList(),
                      ),

                      const SizedBox(
                        height: 26,
                      ),

                      SizedBox(
                        width:
                        double.infinity,
                        child:
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedMode =
                                  temporaryMode;

                              _selectedCity =
                                  temporaryCity;

                              _sortOption =
                                  temporarySort;
                            });

                            Navigator.pop(
                              sheetContext,
                            );
                          },
                          icon:
                          const Icon(
                            Icons.check_rounded,
                            size: 18,
                          ),
                          label:
                          const Text(
                            'APPLY FILTERS',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // FILTER SUMMARY
  // ============================================================

  Widget _buildFilterSummary() {
    final List<String> labels =
    <String>[];

    if (_selectedMode != 'Any') {
      labels.add(
        _selectedMode,
      );
    }

    if (_selectedCity != 'Any') {
      labels.add(
        _selectedCity,
      );
    }

    if (_sortOption != 'A-Z') {
      labels.add(
        _sortOption,
      );
    }

    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration:
      BoxDecoration(
        color:
        _softPrimaryColor,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border:
        Border.all(
          color:
          _softPrimaryBorderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune_rounded,
            size: 16,
            color:
            _primaryColor,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              labels.join(
                ' • ',
              ),
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
              style:
              AppTextStyles.caption
                  .copyWith(
                color:
                _textColor,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),

          TextButton(
            onPressed:
            _resetFilters,
            child:
            const Text(
              'CLEAR',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Widget _buildCategories() {
    final List<String> categories =
        _categories;

    return SizedBox(
      height: 38,
      child:
      ListView.separated(
        scrollDirection:
        Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        itemCount:
        categories.length,
        separatorBuilder: (
            BuildContext context,
            int index,
            ) {
          return const SizedBox(
            width: 8,
          );
        },
        itemBuilder: (
            BuildContext context,
            int index,
            ) {
          final String category =
          categories[index];

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
    final List<User> providers =
    _repository
        .getProvidersForSkill(
      skill.id,
    );

    final int providerCount =
        providers.length;

    final double highestRating =
    _highestProviderRating(
      skill,
    );

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
              child:
              Icon(
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
                        child:
                        Text(
                          skill.level,
                          style:
                          AppTextStyles
                              .caption
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
                        Icons
                            .people_outline_rounded,
                        size: 13,
                        color:
                        _mutedColor,
                      ),

                      const SizedBox(
                        width: 4,
                      ),

                      Flexible(
                        child: Text(
                          '$providerCount provider${providerCount == 1 ? '' : 's'}',
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          AppTextStyles
                              .caption
                              .copyWith(
                            color:
                            _mutedColor,
                          ),
                        ),
                      ),

                      if (providerCount >
                          0) ...[
                        const SizedBox(
                          width: 8,
                        ),
                        Icon(
                          Icons.star_rounded,
                          size: 13,
                          color:
                          AppTheme.accent,
                        ),
                        const SizedBox(
                          width: 3,
                        ),
                        Text(
                          highestRating
                              .toStringAsFixed(
                            1,
                          ),
                          style:
                          AppTextStyles
                              .caption
                              .copyWith(
                            color:
                            _mutedColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Icon(
              Icons
                  .arrow_forward_ios_rounded,
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
    String message =
        'No skills match your current search and filters.';

    if (_searchQuery
        .trim()
        .isNotEmpty &&
        _activeFilterCount == 0) {
      message =
      'We couldn\'t find anything for "$_searchQuery".';
    } else if (_searchQuery
        .trim()
        .isEmpty &&
        _activeFilterCount == 0) {
      message =
      'No skills are available right now.';
    }

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
            message,
            textAlign:
            TextAlign.center,
            style:
            AppTextStyles.secondary
                .copyWith(
              color:
              _mutedColor,
            ),
          ),

          if (_hasActiveFilters) ...[
            const SizedBox(
              height: 14,
            ),
            TextButton.icon(
              onPressed:
              _resetFilters,
              icon:
              const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label:
              const Text(
                'SHOW ALL SKILLS',
                style:
                AppTextStyles.button,
              ),
              style:
              TextButton.styleFrom(
                foregroundColor:
                _primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger =
    ScaffoldMessenger.of(
      context,
    );

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content:
        Text(
          message,
        ),
      ),
    );
  }
}