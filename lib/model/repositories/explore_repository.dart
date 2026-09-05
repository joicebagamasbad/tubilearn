import 'package:flutter/material.dart';

import '../../services/current_user_service.dart';
import '../database/app_database.dart';
import '../skill.dart';
import '../skill_match.dart';
import '../user.dart';
import '../user_skill.dart';

class ExploreRepositoryException implements Exception {
  final String message;

  const ExploreRepositoryException(
      this.message,
      );

  @override
  String toString() => message;
}

class ExploreRepository {
  ExploreRepository._();

  static final ExploreRepository instance =
  ExploreRepository._();

  factory ExploreRepository() {
    return instance;
  }

  // ============================================================
  // STATE
  // ============================================================

  final List<User> _users =
  <User>[];

  final List<Skill> _skills =
  <Skill>[];

  final List<UserSkill> _userSkills =
  <UserSkill>[];

  Future<void>? _loadingFuture;

  bool _initialized = false;

  bool get isInitialized =>
      _initialized;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final Future<void>? pending =
        _loadingFuture;

    if (pending != null) {
      await pending;
      return;
    }

    final Future<void> loading =
    _loadFromDatabase();

    _loadingFuture =
        loading;

    try {
      await loading;
    } finally {
      if (identical(
        _loadingFuture,
        loading,
      )) {
        _loadingFuture = null;
      }
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh() async {
    final Future<void>? pending =
        _loadingFuture;

    if (pending != null) {
      await pending;
    }

    final Future<void> loading =
    _loadFromDatabase();

    _loadingFuture =
        loading;

    try {
      await loading;
    } finally {
      if (identical(
        _loadingFuture,
        loading,
      )) {
        _loadingFuture = null;
      }
    }
  }

  // ============================================================
  // LOAD FROM DATABASE
  // ============================================================

  Future<void> _loadFromDatabase() async {
    try {
      final db =
      await AppDatabase.instance.database;

      final List<Map<String, Object?>>
      userRows =
      await db.query(
        'users',
        orderBy:
        'name COLLATE NOCASE ASC',
      );

      final List<Map<String, Object?>>
      skillRows =
      await db.query(
        'skills',
        orderBy:
        'title COLLATE NOCASE ASC',
      );

      final List<Map<String, Object?>>
      learningRows =
      await db.query(
        'skill_learnings',
        orderBy:
        'skill_id ASC, position ASC',
      );

      final List<Map<String, Object?>>
      userSkillRows =
      await db.query(
        'user_skills',
        orderBy:
        'id ASC',
      );

      // --------------------------------------------------------
      // USERS
      // --------------------------------------------------------

      final List<User> loadedUsers =
      <User>[];

      final Set<String> userIds =
      <String>{};

      for (final Map<String, Object?> row
      in userRows) {
        final User user =
        _userFromMap(
          row,
        );

        if (!userIds.add(
          user.id,
        )) {
          throw const ExploreRepositoryException(
            'Explore data contains duplicate user IDs.',
          );
        }

        loadedUsers.add(
          user,
        );
      }

      // --------------------------------------------------------
      // SKILL LEARNINGS
      // --------------------------------------------------------

      final Map<String, List<String>>
      learningsBySkill =
      <String, List<String>>{};

      final Map<String, Set<int>>
      learningPositionsBySkill =
      <String, Set<int>>{};

      for (final Map<String, Object?> row
      in learningRows) {
        final String skillId =
        _requireString(
          row,
          'skill_id',
          'Skill learning skill ID',
        );

        final String text =
        _requireString(
          row,
          'text',
          'Skill learning text',
        );

        final int position =
        _requireInt(
          row,
          'position',
          'Skill learning position',
        );

        if (position < 0) {
          throw const ExploreRepositoryException(
            'Explore data contains an invalid skill learning position.',
          );
        }

        final Set<int> positions =
        learningPositionsBySkill
            .putIfAbsent(
          skillId,
              () => <int>{},
        );

        if (!positions.add(
          position,
        )) {
          throw const ExploreRepositoryException(
            'Explore data contains duplicate skill learning positions.',
          );
        }

        learningsBySkill
            .putIfAbsent(
          skillId,
              () => <String>[],
        )
            .add(
          text,
        );
      }

      // --------------------------------------------------------
      // SKILLS
      // --------------------------------------------------------

      final List<Skill> loadedSkills =
      <Skill>[];

      final Set<String> skillIds =
      <String>{};

      for (final Map<String, Object?> row
      in skillRows) {
        final String skillId =
        _requireString(
          row,
          'id',
          'Skill ID',
        );

        if (!skillIds.add(
          skillId,
        )) {
          throw const ExploreRepositoryException(
            'Explore data contains duplicate skill IDs.',
          );
        }

        final Skill skill =
        _skillFromMap(
          row,
          learningsBySkill[
          skillId] ??
              const <String>[],
        );

        loadedSkills.add(
          skill,
        );
      }

      // --------------------------------------------------------
      // LEARNING RELATIONSHIP VALIDATION
      // --------------------------------------------------------

      for (final String learningSkillId
      in learningsBySkill.keys) {
        if (!skillIds.contains(
          learningSkillId,
        )) {
          throw const ExploreRepositoryException(
            'Explore data contains a learning entry for an unknown skill.',
          );
        }
      }

      // --------------------------------------------------------
      // USER SKILLS
      // --------------------------------------------------------

      final List<UserSkill>
      loadedUserSkills =
      <UserSkill>[];

      final Set<String> userSkillIds =
      <String>{};

      final Set<String> userSkillKeys =
      <String>{};

      for (final Map<String, Object?> row
      in userSkillRows) {
        final UserSkill relationship =
        _userSkillFromMap(
          row,
        );

        if (!userSkillIds.add(
          relationship.id,
        )) {
          throw const ExploreRepositoryException(
            'Explore data contains duplicate user-skill relationship IDs.',
          );
        }

        if (!userIds.contains(
          relationship.userId,
        )) {
          throw const ExploreRepositoryException(
            'Explore data contains a skill relationship for an unknown user.',
          );
        }

        if (!skillIds.contains(
          relationship.skillId,
        )) {
          throw const ExploreRepositoryException(
            'Explore data contains a user relationship for an unknown skill.',
          );
        }

        final String relationshipKey =
        <String>[
          relationship.userId,
          relationship.skillId,
          relationship.type.name,
        ].join(
          '|',
        );

        if (!userSkillKeys.add(
          relationshipKey,
        )) {
          throw const ExploreRepositoryException(
            'Explore data contains a duplicate user-skill relationship.',
          );
        }

        loadedUserSkills.add(
          relationship,
        );
      }

      // --------------------------------------------------------
      // REPLACE CACHE ONLY AFTER SUCCESS
      // --------------------------------------------------------

      _users
        ..clear()
        ..addAll(
          loadedUsers,
        );

      _skills
        ..clear()
        ..addAll(
          loadedSkills,
        );

      _userSkills
        ..clear()
        ..addAll(
          loadedUserSkills,
        );

      _initialized = true;
    } on ExploreRepositoryException {
      rethrow;
    } catch (_) {
      throw const ExploreRepositoryException(
        'Could not load Explore data. Please try again.',
      );
    }
  }

  // ============================================================
  // UPDATE CURRENT USER PROFILE
  // ============================================================

  Future<User> updateCurrentUserProfile({
    required String name,
    required String city,
    required String bio,
    required String availability,
    required String language,
    required String preferredMode,
    required String teachingStyle,
  }) async {
    await initialize();

    final String currentUserId;

    try {
      currentUserId =
          CurrentUserService.instance
              .requireUserId();
    } on CurrentUserServiceException catch (_) {
      throw const ExploreRepositoryException(
        'No active local user is available.',
      );
    }

    final User? existing =
    findUserById(
      currentUserId,
    );

    if (existing == null) {
      throw const ExploreRepositoryException(
        'Your profile could not be found.',
      );
    }

    final String cleanName =
    name.trim();

    final String cleanCity =
    city.trim();

    final String cleanBio =
    bio.trim();

    final String cleanAvailability =
    availability.trim();

    final String cleanLanguage =
    language.trim();

    final String cleanPreferredMode =
    preferredMode.trim();

    final String cleanTeachingStyle =
    teachingStyle.trim();

    if (cleanName.isEmpty) {
      throw const ExploreRepositoryException(
        'Name is required.',
      );
    }

    if (cleanCity.isEmpty) {
      throw const ExploreRepositoryException(
        'City is required.',
      );
    }

    if (cleanBio.isEmpty) {
      throw const ExploreRepositoryException(
        'Bio is required.',
      );
    }

    if (cleanAvailability.isEmpty) {
      throw const ExploreRepositoryException(
        'Availability is required.',
      );
    }

    if (cleanLanguage.isEmpty) {
      throw const ExploreRepositoryException(
        'Language is required.',
      );
    }

    if (cleanPreferredMode.isEmpty) {
      throw const ExploreRepositoryException(
        'Preferred mode is required.',
      );
    }

    if (cleanTeachingStyle.isEmpty) {
      throw const ExploreRepositoryException(
        'Teaching style is required.',
      );
    }

    if (cleanName.length > 80) {
      throw const ExploreRepositoryException(
        'Name is too long.',
      );
    }

    if (cleanCity.length > 100) {
      throw const ExploreRepositoryException(
        'City is too long.',
      );
    }

    if (cleanBio.length > 500) {
      throw const ExploreRepositoryException(
        'Bio must be 500 characters or less.',
      );
    }

    final String initials =
    _buildInitials(
      cleanName,
    );

    try {
      final db =
      await AppDatabase.instance.database;

      final int updatedRows =
      await db.update(
        'users',
        <String, Object?>{
          'name':
          cleanName,
          'initials':
          initials,
          'city':
          cleanCity,
          'bio':
          cleanBio,
          'availability':
          cleanAvailability,
          'language':
          cleanLanguage,
          'preferred_mode':
          cleanPreferredMode,
          'teaching_style':
          cleanTeachingStyle,
          'profile_completed':
          1,
        },
        where:
        'id = ?',
        whereArgs:
        <Object?>[
          currentUserId,
        ],
      );

      if (updatedRows != 1) {
        throw const ExploreRepositoryException(
          'Your profile could not be saved.',
        );
      }
    } on ExploreRepositoryException {
      rethrow;
    } catch (_) {
      throw const ExploreRepositoryException(
        'Your profile could not be saved. Please try again.',
      );
    }

    final User updatedUser =
    existing.copyWith(
      name:
      cleanName,
      initials:
      initials,
      city:
      cleanCity,
      bio:
      cleanBio,
      availability:
      cleanAvailability,
      language:
      cleanLanguage,
      preferredMode:
      cleanPreferredMode,
      teachingStyle:
      cleanTeachingStyle,
      profileCompleted:
      true,
    );

    final int userIndex =
    _users.indexWhere(
          (
          User user,
          ) =>
      user.id ==
          currentUserId,
    );

    if (userIndex < 0) {
      throw const ExploreRepositoryException(
        'Your profile was saved but could not be refreshed.',
      );
    }

    _users[userIndex] =
        updatedUser;

    return updatedUser;
  }

  // ============================================================
  // SMART MATCHES
  // ============================================================

  List<SkillMatch> getSmartMatchesForUser(
      String userId, {
        int? limit,
      }) {
    final String normalizedUserId =
    userId.trim();

    if (normalizedUserId.isEmpty) {
      return <SkillMatch>[];
    }

    final User? currentUser =
    findUserById(
      normalizedUserId,
    );

    if (currentUser == null) {
      return <SkillMatch>[];
    }

    final List<UserSkill> currentOffered =
    getOfferedSkillsForUser(
      currentUser.id,
    );

    final List<UserSkill> currentWanted =
    getWantedSkillsForUser(
      currentUser.id,
    );

    final Set<String> currentOfferedIds =
    currentOffered
        .map(
          (
          UserSkill relationship,
          ) =>
      relationship.skillId,
    )
        .toSet();

    final Set<String> currentWantedIds =
    currentWanted
        .map(
          (
          UserSkill relationship,
          ) =>
      relationship.skillId,
    )
        .toSet();

    if (currentOfferedIds.isEmpty &&
        currentWantedIds.isEmpty) {
      return <SkillMatch>[];
    }

    final List<SkillMatch> matches =
    <SkillMatch>[];

    for (final User candidate
    in _users) {
      if (candidate.id ==
          currentUser.id) {
        continue;
      }

      final List<UserSkill> candidateOffered =
      getOfferedSkillsForUser(
        candidate.id,
      );

      final List<UserSkill> candidateWanted =
      getWantedSkillsForUser(
        candidate.id,
      );

      final Set<String> candidateOfferedIds =
      candidateOffered
          .map(
            (
            UserSkill relationship,
            ) =>
        relationship.skillId,
      )
          .toSet();

      final Set<String> candidateWantedIds =
      candidateWanted
          .map(
            (
            UserSkill relationship,
            ) =>
        relationship.skillId,
      )
          .toSet();

      final Set<String> learnMatchIds =
      currentWantedIds.intersection(
        candidateOfferedIds,
      );

      final Set<String> teachMatchIds =
      currentOfferedIds.intersection(
        candidateWantedIds,
      );

      if (learnMatchIds.isEmpty &&
          teachMatchIds.isEmpty) {
        continue;
      }

      final bool hasLearningMatch =
          learnMatchIds.isNotEmpty;

      final bool hasTeachingMatch =
          teachMatchIds.isNotEmpty;

      final bool isTwoWayMatch =
          hasLearningMatch &&
              hasTeachingMatch;

      final bool sameCity =
      _textEquals(
        currentUser.city,
        candidate.city,
      );

      final bool modeCompatible =
      _preferenceCompatible(
        currentUser.preferredMode,
        candidate.preferredMode,
      );

      final bool languageCompatible =
      _languageCompatible(
        currentUser.language,
        candidate.language,
      );

      final bool availabilityCompatible =
      _availabilityCompatible(
        currentUser.availability,
        candidate.availability,
      );

      int score =
      0;

      if (hasLearningMatch) {
        score +=
        40;
      }

      if (hasTeachingMatch) {
        score +=
        25;
      }

      if (modeCompatible) {
        score +=
        8;
      }

      if (availabilityCompatible) {
        score +=
        6;
      }

      if (languageCompatible) {
        score +=
        5;
      }

      if (sameCity) {
        score +=
        4;
      }

      score +=
          _responseRateScore(
            candidate.responseRate,
          );

      score +=
          _ratingScore(
            candidate.rating,
          );

      score +=
          _trustScore(
            candidate,
          );

      score =
          score.clamp(
            0,
            100,
          );

      final Skill? skillToLearn =
      _firstSkillFromIds(
        learnMatchIds,
      );

      final Skill? skillToTeach =
      _firstSkillFromIds(
        teachMatchIds,
      );

      final List<String> reasons =
      _buildMatchReasons(
        candidate:
        candidate,
        learningMatchCount:
        learnMatchIds.length,
        teachingMatchCount:
        teachMatchIds.length,
        isTwoWayMatch:
        isTwoWayMatch,
        sameCity:
        sameCity,
        modeCompatible:
        modeCompatible,
        languageCompatible:
        languageCompatible,
        availabilityCompatible:
        availabilityCompatible,
      );

      matches.add(
        SkillMatch(
          user:
          candidate,
          score:
          score,
          skillToLearn:
          skillToLearn,
          skillToTeach:
          skillToTeach,
          isTwoWayMatch:
          isTwoWayMatch,
          sameCity:
          sameCity,
          modeCompatible:
          modeCompatible,
          languageCompatible:
          languageCompatible,
          availabilityCompatible:
          availabilityCompatible,
          reasons:
          List<String>.unmodifiable(
            reasons,
          ),
        ),
      );
    }

    matches.sort(
          (
          SkillMatch first,
          SkillMatch second,
          ) {
        final int scoreComparison =
        second.score.compareTo(
          first.score,
        );

        if (scoreComparison != 0) {
          return scoreComparison;
        }

        final int twoWayComparison =
        _boolRank(
          second.isTwoWayMatch,
        ).compareTo(
          _boolRank(
            first.isTwoWayMatch,
          ),
        );

        if (twoWayComparison != 0) {
          return twoWayComparison;
        }

        final int ratingComparison =
        second.user.rating.compareTo(
          first.user.rating,
        );

        if (ratingComparison != 0) {
          return ratingComparison;
        }

        final int responseComparison =
        second.user.responseRate.compareTo(
          first.user.responseRate,
        );

        if (responseComparison != 0) {
          return responseComparison;
        }

        return first.user.name
            .toLowerCase()
            .compareTo(
          second.user.name
              .toLowerCase(),
        );
      },
    );

    if (limit == null) {
      return List<SkillMatch>.unmodifiable(
        matches,
      );
    }

    if (limit <= 0) {
      return <SkillMatch>[];
    }

    return List<SkillMatch>.unmodifiable(
      matches.take(
        limit,
      ),
    );
  }

  // ============================================================
  // SMART MATCH HELPERS
  // ============================================================

  Skill? _firstSkillFromIds(
      Set<String> skillIds,
      ) {
    if (skillIds.isEmpty) {
      return null;
    }

    final List<Skill> matchingSkills =
    _skills.where(
          (
          Skill skill,
          ) =>
          skillIds.contains(
            skill.id,
          ),
    ).toList();

    if (matchingSkills.isEmpty) {
      return null;
    }

    matchingSkills.sort(
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

    return matchingSkills.first;
  }

  List<String> _buildMatchReasons({
    required User candidate,
    required int learningMatchCount,
    required int teachingMatchCount,
    required bool isTwoWayMatch,
    required bool sameCity,
    required bool modeCompatible,
    required bool languageCompatible,
    required bool availabilityCompatible,
  }) {
    final List<String> reasons =
    <String>[];

    if (isTwoWayMatch) {
      reasons.add(
        'Two-way skill exchange',
      );
    } else if (learningMatchCount > 0) {
      reasons.add(
        'Offers a skill you want to learn',
      );
    } else if (teachingMatchCount > 0) {
      reasons.add(
        'Wants a skill you can teach',
      );
    }

    if (learningMatchCount > 1) {
      reasons.add(
        '$learningMatchCount learning interests match',
      );
    }

    if (teachingMatchCount > 1) {
      reasons.add(
        '$teachingMatchCount offered skills match',
      );
    }

    if (modeCompatible) {
      reasons.add(
        'Compatible session mode',
      );
    }

    if (availabilityCompatible) {
      reasons.add(
        'Compatible availability',
      );
    }

    if (languageCompatible) {
      reasons.add(
        'Compatible language',
      );
    }

    if (sameCity) {
      reasons.add(
        'Same city',
      );
    }

    if (candidate.responseRate >= 90) {
      reasons.add(
        'High response rate',
      );
    }

    if (candidate.rating >= 4.5 &&
        candidate.reviewCount > 0) {
      reasons.add(
        'Strong community rating',
      );
    }

    if (candidate.completedSwaps > 0) {
      reasons.add(
        'Has completed swaps',
      );
    }

    return reasons;
  }

  int _responseRateScore(
      int responseRate,
      ) {
    final int safeRate =
    responseRate.clamp(
      0,
      100,
    );

    return ((safeRate / 100) * 5)
        .round();
  }

  int _ratingScore(
      double rating,
      ) {
    final double safeRating =
    rating.clamp(
      0,
      5,
    );

    return ((safeRating / 5) * 4)
        .round();
  }

  int _trustScore(
      User user,
      ) {
    int score =
    0;

    if (user.emailVerified) {
      score +=
      1;
    }

    if (user.profileCompleted) {
      score +=
      1;
    }

    if (user.completedSwaps > 0) {
      score +=
      1;
    }

    return score;
  }

  int _boolRank(
      bool value,
      ) {
    return value
        ? 1
        : 0;
  }

  bool _textEquals(
      String first,
      String second,
      ) {
    final String normalizedFirst =
    _normalizeText(
      first,
    );

    final String normalizedSecond =
    _normalizeText(
      second,
    );

    if (normalizedFirst.isEmpty ||
        normalizedSecond.isEmpty) {
      return false;
    }

    return normalizedFirst ==
        normalizedSecond;
  }

  bool _preferenceCompatible(
      String first,
      String second,
      ) {
    final Set<String> firstModes =
    _extractPreferenceTokens(
      first,
    );

    final Set<String> secondModes =
    _extractPreferenceTokens(
      second,
    );

    if (firstModes.isEmpty ||
        secondModes.isEmpty) {
      return false;
    }

    if (_containsFlexibleValue(
      firstModes,
    ) ||
        _containsFlexibleValue(
          secondModes,
        )) {
      return true;
    }

    return firstModes.intersection(
      secondModes,
    ).isNotEmpty;
  }

  bool _languageCompatible(
      String first,
      String second,
      ) {
    final Set<String> firstLanguages =
    _extractPreferenceTokens(
      first,
    );

    final Set<String> secondLanguages =
    _extractPreferenceTokens(
      second,
    );

    if (firstLanguages.isEmpty ||
        secondLanguages.isEmpty) {
      return false;
    }

    if (_containsFlexibleValue(
      firstLanguages,
    ) ||
        _containsFlexibleValue(
          secondLanguages,
        )) {
      return true;
    }

    return firstLanguages.intersection(
      secondLanguages,
    ).isNotEmpty;
  }

  bool _availabilityCompatible(
      String first,
      String second,
      ) {
    final String normalizedFirst =
    _normalizeText(
      first,
    );

    final String normalizedSecond =
    _normalizeText(
      second,
    );

    if (normalizedFirst.isEmpty ||
        normalizedSecond.isEmpty) {
      return false;
    }

    if (normalizedFirst ==
        normalizedSecond) {
      return true;
    }

    final Set<String> firstTokens =
    _meaningfulAvailabilityTokens(
      normalizedFirst,
    );

    final Set<String> secondTokens =
    _meaningfulAvailabilityTokens(
      normalizedSecond,
    );

    if (firstTokens.isEmpty ||
        secondTokens.isEmpty) {
      return false;
    }

    if (_containsFlexibleValue(
      firstTokens,
    ) ||
        _containsFlexibleValue(
          secondTokens,
        )) {
      return true;
    }

    return firstTokens.intersection(
      secondTokens,
    ).isNotEmpty;
  }

  Set<String> _extractPreferenceTokens(
      String value,
      ) {
    final String normalized =
    _normalizeText(
      value,
    );

    if (normalized.isEmpty) {
      return <String>{};
    }

    return normalized
        .split(
      RegExp(
        r'[,/&|]+',
      ),
    )
        .map(
          (
          String token,
          ) =>
          token.trim(),
    )
        .where(
          (
          String token,
          ) =>
      token.isNotEmpty,
    )
        .toSet();
  }

  Set<String> _meaningfulAvailabilityTokens(
      String value,
      ) {
    const Set<String> ignored =
    <String>{
      'and',
      'or',
      'the',
      'on',
      'at',
      'from',
      'to',
      'available',
      'availability',
    };

    return value
        .split(
      RegExp(
        r'[^a-z0-9]+',
      ),
    )
        .map(
          (
          String token,
          ) =>
          token.trim(),
    )
        .where(
          (
          String token,
          ) =>
      token.isNotEmpty &&
          !ignored.contains(
            token,
          ),
    )
        .toSet();
  }

  bool _containsFlexibleValue(
      Set<String> values,
      ) {
    const Set<String> flexibleValues =
    <String>{
      'any',
      'anytime',
      'flexible',
      'both',
      'either',
      'all',
    };

    for (final String value
    in values) {
      if (flexibleValues.contains(
        value,
      )) {
        return true;
      }

      if (value.contains(
        'flexible',
      ) ||
          value.contains(
            'anytime',
          )) {
        return true;
      }
    }

    return false;
  }

  String _normalizeText(
      String value,
      ) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(
      RegExp(
        r'\s+',
      ),
      ' ',
    );
  }

  // ============================================================
  // PROFILE INITIALS
  // ============================================================

  String _buildInitials(
      String name,
      ) {
    final List<String> parts =
    name
        .trim()
        .split(
      RegExp(
        r'\s+',
      ),
    )
        .where(
          (
          String part,
          ) =>
      part.isNotEmpty,
    )
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      final String first =
          parts.first;

      if (first.length == 1) {
        return first.toUpperCase();
      }

      return first
          .substring(
        0,
        2,
      )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  // ============================================================
  // MAP -> USER
  // ============================================================

  User _userFromMap(
      Map<String, Object?> map,
      ) {
    final String id =
    _requireString(
      map,
      'id',
      'User ID',
    );

    final String name =
    _requireString(
      map,
      'name',
      'User name',
    );

    final String initials =
    _requireString(
      map,
      'initials',
      'User initials',
    );

    final String city =
    _requireString(
      map,
      'city',
      'User city',
    );

    final String bio =
    _requireString(
      map,
      'bio',
      'User bio',
    );

    final double rating =
    _requireDouble(
      map,
      'rating',
      'User rating',
    );

    final int reviewCount =
    _requireInt(
      map,
      'review_count',
      'User review count',
    );

    final int completedSwaps =
    _requireInt(
      map,
      'completed_swaps',
      'User completed swaps',
    );

    final int responseRate =
    _requireInt(
      map,
      'response_rate',
      'User response rate',
    );

    final String memberSince =
    _requireString(
      map,
      'member_since',
      'User member since',
    );

    final String availability =
    _requireString(
      map,
      'availability',
      'User availability',
    );

    final String language =
    _requireString(
      map,
      'language',
      'User language',
    );

    final String preferredMode =
    _requireString(
      map,
      'preferred_mode',
      'User preferred mode',
    );

    final String teachingStyle =
    _requireString(
      map,
      'teaching_style',
      'User teaching style',
    );

    final bool emailVerified =
    _requireBooleanFlag(
      map,
      'email_verified',
      'User email verification',
    );

    final bool profileCompleted =
    _requireBooleanFlag(
      map,
      'profile_completed',
      'User profile completion',
    );

    if (rating < 0 ||
        rating > 5) {
      throw const ExploreRepositoryException(
        'Explore data contains an invalid user rating.',
      );
    }

    if (reviewCount < 0) {
      throw const ExploreRepositoryException(
        'Explore data contains an invalid review count.',
      );
    }

    if (completedSwaps < 0) {
      throw const ExploreRepositoryException(
        'Explore data contains an invalid completed swap count.',
      );
    }

    if (responseRate < 0 ||
        responseRate > 100) {
      throw const ExploreRepositoryException(
        'Explore data contains an invalid response rate.',
      );
    }

    return User(
      id:
      id,
      name:
      name,
      initials:
      initials,
      city:
      city,
      bio:
      bio,
      rating:
      rating,
      reviewCount:
      reviewCount,
      completedSwaps:
      completedSwaps,
      responseRate:
      responseRate,
      memberSince:
      memberSince,
      availability:
      availability,
      language:
      language,
      preferredMode:
      preferredMode,
      teachingStyle:
      teachingStyle,
      emailVerified:
      emailVerified,
      profileCompleted:
      profileCompleted,
    );
  }

  // ============================================================
  // MAP -> SKILL
  // ============================================================

  Skill _skillFromMap(
      Map<String, Object?> map,
      List<String> learnings,
      ) {
    final String id =
    _requireString(
      map,
      'id',
      'Skill ID',
    );

    final String title =
    _requireString(
      map,
      'title',
      'Skill title',
    );

    final String category =
    _requireString(
      map,
      'category',
      'Skill category',
    );

    final String level =
    _requireString(
      map,
      'level',
      'Skill level',
    );

    final int iconCodePoint =
    _requireInt(
      map,
      'icon_code_point',
      'Skill icon',
    );

    final String sessionLength =
    _requireString(
      map,
      'session_length',
      'Skill session length',
    );

    final String mode =
    _requireString(
      map,
      'mode',
      'Skill mode',
    );

    final String language =
    _requireString(
      map,
      'language',
      'Skill language',
    );

    final String prerequisite =
    _readStringAllowEmpty(
      map,
      'prerequisite',
      'Skill prerequisite',
    );

    final String description =
    _requireString(
      map,
      'description',
      'Skill description',
    );

    return Skill(
      id:
      id,
      title:
      title,
      category:
      category,
      level:
      level,
      icon:
      _iconFromCodePoint(
        iconCodePoint,
      ),
      sessionLength:
      sessionLength,
      mode:
      mode,
      language:
      language,
      prerequisite:
      prerequisite,
      description:
      description,
      learnings:
      List<String>.unmodifiable(
        learnings,
      ),
    );
  }

  // ============================================================
  // ICON CODE POINT -> MATERIAL ICON CONSTANT
  // ============================================================

  IconData _iconFromCodePoint(
      int codePoint,
      ) {
    const List<IconData> supportedIcons =
    <IconData>[
      Icons.design_services_outlined,
      Icons.camera_alt_outlined,
      Icons.movie_creation_outlined,
      Icons.code_rounded,
      Icons.translate_rounded,
      Icons.table_chart_outlined,
      Icons.record_voice_over_outlined,
      Icons.music_note_rounded,
      Icons.palette_outlined,
      Icons.web_outlined,
      Icons.school_outlined,
      Icons.self_improvement_rounded,
      Icons.lightbulb_outline_rounded,
    ];

    for (final IconData icon
    in supportedIcons) {
      if (icon.codePoint ==
          codePoint) {
        return icon;
      }
    }

    return Icons
        .lightbulb_outline_rounded;
  }

  // ============================================================
  // MAP -> USER SKILL
  // ============================================================

  UserSkill _userSkillFromMap(
      Map<String, Object?> map,
      ) {
    final String id =
    _requireString(
      map,
      'id',
      'User-skill relationship ID',
    );

    final String userId =
    _requireString(
      map,
      'user_id',
      'User-skill user ID',
    );

    final String skillId =
    _requireString(
      map,
      'skill_id',
      'User-skill skill ID',
    );

    final String type =
    _requireString(
      map,
      'type',
      'User-skill type',
    );

    final String level =
    _requireString(
      map,
      'level',
      'User-skill level',
    );

    final String availability =
    _requireString(
      map,
      'availability',
      'User-skill availability',
    );

    late final UserSkillType parsedType;

    switch (type) {
      case 'offered':
        parsedType =
            UserSkillType.offered;

      case 'wanted':
        parsedType =
            UserSkillType.wanted;

      default:
        throw const ExploreRepositoryException(
          'Explore data contains an invalid user-skill type.',
        );
    }

    return UserSkill(
      id:
      id,
      userId:
      userId,
      skillId:
      skillId,
      type:
      parsedType,
      level:
      level,
      availability:
      availability,
    );
  }

  // ============================================================
  // DEFENSIVE FIELD PARSING
  // ============================================================

  String _requireString(
      Map<String, Object?> row,
      String key,
      String label,
      ) {
    final Object? value =
    row[key];

    if (value is! String) {
      throw ExploreRepositoryException(
        '$label is invalid.',
      );
    }

    final String cleaned =
    value.trim();

    if (cleaned.isEmpty) {
      throw ExploreRepositoryException(
        '$label is required.',
      );
    }

    return cleaned;
  }

  String _readStringAllowEmpty(
      Map<String, Object?> row,
      String key,
      String label,
      ) {
    final Object? value =
    row[key];

    if (value is! String) {
      throw ExploreRepositoryException(
        '$label is invalid.',
      );
    }

    return value.trim();
  }

  int _requireInt(
      Map<String, Object?> row,
      String key,
      String label,
      ) {
    final Object? value =
    row[key];

    if (value is int) {
      return value;
    }

    if (value is num) {
      final double numericValue =
      value.toDouble();

      if (!numericValue.isFinite ||
          numericValue !=
              numericValue
                  .truncateToDouble()) {
        throw ExploreRepositoryException(
          '$label is invalid.',
        );
      }

      return numericValue.toInt();
    }

    if (value is String) {
      final int? parsed =
      int.tryParse(
        value.trim(),
      );

      if (parsed != null) {
        return parsed;
      }
    }

    throw ExploreRepositoryException(
      '$label is invalid.',
    );
  }

  double _requireDouble(
      Map<String, Object?> row,
      String key,
      String label,
      ) {
    final Object? value =
    row[key];

    if (value is num) {
      final double parsed =
      value.toDouble();

      if (parsed.isFinite) {
        return parsed;
      }
    }

    if (value is String) {
      final double? parsed =
      double.tryParse(
        value.trim(),
      );

      if (parsed != null &&
          parsed.isFinite) {
        return parsed;
      }
    }

    throw ExploreRepositoryException(
      '$label is invalid.',
    );
  }

  bool _requireBooleanFlag(
      Map<String, Object?> row,
      String key,
      String label,
      ) {
    final int value =
    _requireInt(
      row,
      key,
      label,
    );

    if (value == 0) {
      return false;
    }

    if (value == 1) {
      return true;
    }

    throw ExploreRepositoryException(
      '$label must be 0 or 1.',
    );
  }

  // ============================================================
  // PUBLIC READ METHODS
  // ============================================================

  List<User> get users =>
      List<User>.unmodifiable(
        _users,
      );

  List<Skill> get skills =>
      List<Skill>.unmodifiable(
        _skills,
      );

  List<UserSkill> get userSkills =>
      List<UserSkill>.unmodifiable(
        _userSkills,
      );

  // ============================================================
  // FIND USER
  // ============================================================

  User? findUserById(
      String userId,
      ) {
    final String normalizedId =
    userId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    for (final User user
    in _users) {
      if (user.id ==
          normalizedId) {
        return user;
      }
    }

    return null;
  }

  // ============================================================
  // FIND SKILL
  // ============================================================

  Skill? findSkillById(
      String skillId,
      ) {
    final String normalizedId =
    skillId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    for (final Skill skill
    in _skills) {
      if (skill.id ==
          normalizedId) {
        return skill;
      }
    }

    return null;
  }

  // ============================================================
  // OFFERED SKILLS
  // ============================================================

  List<UserSkill> getOfferedSkillsForUser(
      String userId,
      ) {
    final String normalizedUserId =
    userId.trim();

    if (normalizedUserId.isEmpty) {
      return <UserSkill>[];
    }

    return _userSkills
        .where(
          (
          UserSkill item,
          ) =>
      item.userId ==
          normalizedUserId &&
          item.type ==
              UserSkillType.offered,
    )
        .toList();
  }

  // ============================================================
  // WANTED SKILLS
  // ============================================================

  List<UserSkill> getWantedSkillsForUser(
      String userId,
      ) {
    final String normalizedUserId =
    userId.trim();

    if (normalizedUserId.isEmpty) {
      return <UserSkill>[];
    }

    return _userSkills
        .where(
          (
          UserSkill item,
          ) =>
      item.userId ==
          normalizedUserId &&
          item.type ==
              UserSkillType.wanted,
    )
        .toList();
  }

  // ============================================================
  // PROVIDERS FOR SKILL
  // ============================================================

  List<User> getProvidersForSkill(
      String skillId,
      ) {
    final String normalizedSkillId =
    skillId.trim();

    if (normalizedSkillId.isEmpty) {
      return <User>[];
    }

    final Set<String> providerIds =
    _userSkills
        .where(
          (
          UserSkill item,
          ) =>
      item.skillId ==
          normalizedSkillId &&
          item.type ==
              UserSkillType.offered,
    )
        .map(
          (
          UserSkill item,
          ) =>
      item.userId,
    )
        .toSet();

    return _users
        .where(
          (
          User user,
          ) =>
          providerIds.contains(
            user.id,
          ),
    )
        .toList();
  }

  // ============================================================
  // FIND USER SKILL RELATIONSHIP
  // ============================================================

  UserSkill? findUserSkill({
    required String userId,
    required String skillId,
    required UserSkillType type,
  }) {
    final String normalizedUserId =
    userId.trim();

    final String normalizedSkillId =
    skillId.trim();

    if (normalizedUserId.isEmpty ||
        normalizedSkillId.isEmpty) {
      return null;
    }

    for (final UserSkill item
    in _userSkills) {
      if (item.userId ==
          normalizedUserId &&
          item.skillId ==
              normalizedSkillId &&
          item.type ==
              type) {
        return item;
      }
    }

    return null;
  }
}