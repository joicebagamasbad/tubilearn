import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/skill_match.dart';
import '../model/user.dart';
import '../services/current_user_service.dart';
import '../services/explore_service.dart';

class ExploreControllerException implements Exception {
  final String message;

  const ExploreControllerException(
      this.message,
      );

  @override
  String toString() => message;
}

// ============================================================
// EXPLORE SNAPSHOT
// ============================================================

class ExploreSnapshot {
  final List<Skill> skills;
  final List<String> categories;
  final List<String> cities;
  final List<SkillMatch> smartMatches;

  const ExploreSnapshot({
    required this.skills,
    required this.categories,
    required this.cities,
    required this.smartMatches,
  });
}

// ============================================================
// SMART MATCH SNAPSHOT
// ============================================================

class SmartMatchesSnapshot {
  final List<SkillMatch> matches;
  final bool hasOfferedSkills;
  final bool hasWantedSkills;

  const SmartMatchesSnapshot({
    required this.matches,
    required this.hasOfferedSkills,
    required this.hasWantedSkills,
  });
}

// ============================================================
// CONTROLLER
// ============================================================

class ExploreController {
  ExploreController({
    ExploreRepository? exploreRepository,
    ExploreService? exploreService,
    CurrentUserService? currentUserService,
  })  : _repository =
      exploreRepository ??
          ExploreRepository.instance,
        _exploreService =
            exploreService ??
                ExploreService.instance,
        _currentUserService =
            currentUserService ??
                CurrentUserService.instance;

  final ExploreRepository _repository;
  final ExploreService _exploreService;
  final CurrentUserService _currentUserService;

  // ============================================================
  // LOAD EXPLORE
  // ============================================================

  Future<ExploreSnapshot> loadExplore({
    int? smartMatchLimit,
  }) async {
    try {
      await _prepareExploreIfNeeded();

      return _buildExploreSnapshot(
        smartMatchLimit: smartMatchLimit,
      );
    } on CurrentUserServiceException catch (error) {
      throw ExploreControllerException(
        error.message,
      );
    } on ExploreServiceException catch (error) {
      throw ExploreControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw ExploreControllerException(
        error.message,
      );
    } catch (_) {
      throw const ExploreControllerException(
        'Explore could not be loaded. Please try again.',
      );
    }
  }

  // ============================================================
  // REFRESH EXPLORE
  // ============================================================

  Future<ExploreSnapshot> refreshExplore({
    int? smartMatchLimit,
  }) async {
    try {
      await _exploreService.refreshCurrentExplore();

      return _buildExploreSnapshot(
        smartMatchLimit: smartMatchLimit,
      );
    } on CurrentUserServiceException catch (error) {
      throw ExploreControllerException(
        error.message,
      );
    } on ExploreServiceException catch (error) {
      throw ExploreControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw ExploreControllerException(
        error.message,
      );
    } catch (_) {
      throw const ExploreControllerException(
        'Explore could not be refreshed. Please try again.',
      );
    }
  }

  // ============================================================
  // LOAD SMART MATCHES
  // ============================================================

  Future<SmartMatchesSnapshot> loadSmartMatches() async {
    try {
      await _prepareExploreIfNeeded();

      return _buildSmartMatchesSnapshot();
    } on CurrentUserServiceException catch (error) {
      throw ExploreControllerException(
        error.message,
      );
    } on ExploreServiceException catch (error) {
      throw ExploreControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw ExploreControllerException(
        error.message,
      );
    } catch (_) {
      throw const ExploreControllerException(
        'Smart matches could not be loaded. Please try again.',
      );
    }
  }

  // ============================================================
  // REFRESH SMART MATCHES
  // ============================================================

  Future<SmartMatchesSnapshot> refreshSmartMatches() async {
    try {
      await _exploreService.refreshCurrentExplore();

      return _buildSmartMatchesSnapshot();
    } on CurrentUserServiceException catch (error) {
      throw ExploreControllerException(
        error.message,
      );
    } on ExploreServiceException catch (error) {
      throw ExploreControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw ExploreControllerException(
        error.message,
      );
    } catch (_) {
      throw const ExploreControllerException(
        'Smart matches could not be refreshed.',
      );
    }
  }

  Future<void> _prepareExploreIfNeeded() async {
    if (_repository.isInitialized) {
      return;
    }
    await _exploreService.prepareCurrentSession();
  }

  // ============================================================
  // SMART MATCHES
  // ============================================================

  List<SkillMatch> getSmartMatches({
    int? limit,
  }) {
    try {
      final String currentUserId =
      _requireCurrentUserId();

      final List<SkillMatch> matches =
      _repository.getSmartMatchesForUser(
        currentUserId,
        limit: limit,
      );

      return _sanitizeMatches(
        matches,
        currentUserId: currentUserId,
      );
    } on CurrentUserServiceException catch (error) {
      throw ExploreControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw ExploreControllerException(
        error.message,
      );
    } on ExploreControllerException {
      rethrow;
    } catch (_) {
      throw const ExploreControllerException(
        'Smart Matches could not be loaded.',
      );
    }
  }

  // ============================================================
  // SMART MATCH SNAPSHOT
  // ============================================================

  SmartMatchesSnapshot _buildSmartMatchesSnapshot() {
    final String currentUserId =
    _requireCurrentUserId();

    final List<SkillMatch> rawMatches =
    _repository.getSmartMatchesForUser(
      currentUserId,
    );

    final List<SkillMatch> safeMatches =
    _sanitizeMatches(
      rawMatches,
      currentUserId: currentUserId,
    );

    final bool hasOfferedSkills =
        _repository
            .getOfferedSkillsForUser(
          currentUserId,
        )
            .isNotEmpty;

    final bool hasWantedSkills =
        _repository
            .getWantedSkillsForUser(
          currentUserId,
        )
            .isNotEmpty;

    return SmartMatchesSnapshot(
      matches: safeMatches,
      hasOfferedSkills: hasOfferedSkills,
      hasWantedSkills: hasWantedSkills,
    );
  }

  // ============================================================
  // SANITIZE SMART MATCHES
  // ============================================================

  List<SkillMatch> _sanitizeMatches(
      List<SkillMatch> matches, {
        required String currentUserId,
      }) {
    final String cleanCurrentUserId =
    currentUserId.trim();

    final Set<String> seenUserIds =
    <String>{};

    final List<SkillMatch> result =
    <SkillMatch>[];

    for (final SkillMatch match in matches) {
      final String candidateUserId =
      match.user.id.trim();

      if (candidateUserId.isEmpty) {
        continue;
      }

      if (candidateUserId ==
          cleanCurrentUserId) {
        continue;
      }

      if (!seenUserIds.add(
        candidateUserId,
      )) {
        continue;
      }

      result.add(
        match,
      );
    }

    return List<SkillMatch>.unmodifiable(
      result,
    );
  }

  // ============================================================
  // PROVIDERS FOR SKILL
  // ============================================================

  List<User> providersForSkill(
      Skill skill,
      ) {
    try {
      final String currentUserId =
      _requireCurrentUserId();

      final Set<String> seenUserIds =
      <String>{};

      final List<User> providers =
      <User>[];

      for (final User provider
      in _repository.getProvidersForSkill(
        skill.id,
      )) {
        final String providerId =
        provider.id.trim();

        if (providerId.isEmpty) {
          continue;
        }

        if (providerId ==
            currentUserId) {
          continue;
        }

        if (!seenUserIds.add(
          providerId,
        )) {
          continue;
        }

        providers.add(
          provider,
        );
      }

      return List<User>.unmodifiable(
        providers,
      );
    } on CurrentUserServiceException catch (error) {
      throw ExploreControllerException(
        error.message,
      );
    } on ExploreControllerException {
      rethrow;
    } catch (_) {
      throw const ExploreControllerException(
        'Skill providers could not be loaded.',
      );
    }
  }

  // ============================================================
  // FILTER SKILLS
  // ============================================================

  List<Skill> filterSkills({
    required String searchQuery,
    required String selectedCategory,
    required String selectedMode,
    required String selectedCity,
    required String sortOption,
  }) {
    try {
      final String query =
      searchQuery
          .trim()
          .toLowerCase();

      final List<Skill> results =
      _repository.skills.where(
            (
            Skill skill,
            ) {
          final List<User> providers =
          providersForSkill(
            skill,
          );

          final bool matchesCategory =
              selectedCategory == 'All' ||
                  skill.category.trim() ==
                      selectedCategory;

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
          _matchesModeFilter(
            skill: skill,
            providers: providers,
            selectedMode: selectedMode,
          );

          final bool matchesCity =
              selectedCity == 'Any' ||
                  providers.any(
                        (
                        User provider,
                        ) =>
                    provider.city
                        .trim()
                        .toLowerCase() ==
                        selectedCity
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
        sortOption: sortOption,
      );

      return List<Skill>.unmodifiable(
        results,
      );
    } on ExploreControllerException {
      rethrow;
    } catch (_) {
      throw const ExploreControllerException(
        'Explore results could not be filtered.',
      );
    }
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  List<String> get categories {
    try {
      final Set<String> categorySet =
      <String>{};

      for (final Skill skill
      in _repository.skills) {
        final String category =
        skill.category.trim();

        if (category.isNotEmpty) {
          categorySet.add(
            category,
          );
        }
      }

      final List<String> sorted =
      categorySet.toList()
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

      return List<String>.unmodifiable(
        <String>[
          'All',
          ...sorted,
        ],
      );
    } catch (_) {
      throw const ExploreControllerException(
        'Explore categories could not be loaded.',
      );
    }
  }

  // ============================================================
  // CITIES
  // ============================================================

  List<String> get cities {
    try {
      final Set<String> citySet =
      <String>{};

      for (final Skill skill
      in _repository.skills) {
        for (final User provider
        in providersForSkill(
          skill,
        )) {
          final String city =
          provider.city.trim();

          if (city.isNotEmpty) {
            citySet.add(
              city,
            );
          }
        }
      }

      final List<String> sorted =
      citySet.toList()
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

      return List<String>.unmodifiable(
        <String>[
          'Any',
          ...sorted,
        ],
      );
    } on ExploreControllerException {
      rethrow;
    } catch (_) {
      throw const ExploreControllerException(
        'Explore cities could not be loaded.',
      );
    }
  }

  // ============================================================
  // EXPLORE SNAPSHOT
  // ============================================================

  ExploreSnapshot _buildExploreSnapshot({
    int? smartMatchLimit,
  }) {
    final List<SkillMatch> matches =
    getSmartMatches(
      limit: smartMatchLimit,
    );

    return ExploreSnapshot(
      skills:
      List<Skill>.unmodifiable(
        _repository.skills,
      ),
      categories: categories,
      cities: cities,
      smartMatches:
      List<SkillMatch>.unmodifiable(
        matches,
      ),
    );
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String _requireCurrentUserId() {
    final String userId =
    _currentUserService
        .requireUserId()
        .trim();

    if (userId.isEmpty) {
      throw const ExploreControllerException(
        'No active local user is available.',
      );
    }

    return userId;
  }

  // ============================================================
  // SEARCH HELPERS
  // ============================================================

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

  // ============================================================
  // MODE FILTER
  // ============================================================

  bool _matchesModeFilter({
    required Skill skill,
    required List<User> providers,
    required String selectedMode,
  }) {
    if (selectedMode == 'Any') {
      return true;
    }

    if (!skill.supportsSessionMode(
      selectedMode,
    )) {
      return false;
    }

    if (providers.isEmpty) {
      return true;
    }

    return providers.any(
          (
          User provider,
          ) =>
          _providerSupportsMode(
            provider,
            selectedMode,
          ),
    );
  }

  bool _providerSupportsMode(
      User provider,
      String selectedMode,
      ) {
    final String value =
    provider.preferredMode
        .trim()
        .toLowerCase();

    if (value.isEmpty) {
      return true;
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
          ) ||
          value.contains(
            'meetup',
          );
    }

    return false;
  }

  // ============================================================
  // SORT
  // ============================================================

  void _sortSkills(
      List<Skill> skills, {
        required String sortOption,
      }) {
    switch (sortOption) {
      case 'Most Providers':
        skills.sort(
              (
              Skill first,
              Skill second,
              ) {
            final int firstCount =
                providersForSkill(
                  first,
                ).length;

            final int secondCount =
                providersForSkill(
                  second,
                ).length;

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
        return;

      case 'Top Provider Rating':
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

            final int providerComparison =
            providersForSkill(
              second,
            ).length.compareTo(
              providersForSkill(
                first,
              ).length,
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
        return;

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
    double highest = 0;

    for (final User provider
    in providersForSkill(
      skill,
    )) {
      if (provider.reviewCount <= 0) {
        continue;
      }

      if (provider.rating > highest) {
        highest = provider.rating;
      }
    }

    return highest;
  }
}
