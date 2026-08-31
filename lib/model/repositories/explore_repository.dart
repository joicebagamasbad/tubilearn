import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../skill.dart';
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

  final List<User> _users = [];

  final List<Skill> _skills = [];

  final List<UserSkill> _userSkills = [];

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

    _loadingFuture = loading;

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

    _loadingFuture = loading;

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
  //
  // Loads everything into temporary collections first.
  // Existing in-memory data is replaced only after the complete
  // read, parsing, and relationship validation succeeds.
  // ============================================================

  Future<void> _loadFromDatabase() async {
    try {
      final db =
      await AppDatabase.instance.database;

      final List<Map<String, Object?>>
      userRows = await db.query(
        'users',
        orderBy:
        'name COLLATE NOCASE ASC',
      );

      final List<Map<String, Object?>>
      skillRows = await db.query(
        'skills',
        orderBy:
        'title COLLATE NOCASE ASC',
      );

      final List<Map<String, Object?>>
      learningRows = await db.query(
        'skill_learnings',
        orderBy:
        'skill_id ASC, position ASC',
      );

      final List<Map<String, Object?>>
      userSkillRows = await db.query(
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
        ].join('|');

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

    // Prerequisite is allowed to be blank.
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
  //
  // Dynamic IconData is intentionally avoided so release-mode
  // icon tree shaking remains safe.
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

  // ------------------------------------------------------------
  // STRING THAT MAY BE EMPTY
  //
  // Used for valid optional text columns such as prerequisite.
  // The database value must still be a String, but "" is valid.
  // ------------------------------------------------------------

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