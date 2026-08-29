import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../skill.dart';
import '../user.dart';
import '../user_skill.dart';

class ExploreRepository {
  // ============================================================
  // SINGLETON
  //
  // Existing code can continue using:
  //
  // ExploreRepository()
  //
  // All calls point to the same repository instance/cache.
  // ============================================================

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

  bool _initialized = false;

  bool get isInitialized => _initialized;

  // ============================================================
  // INITIALIZE
  //
  // Loads persistent normalized Explore data from SQLite.
  //
  // Call this before runApp().
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final db =
    await AppDatabase.instance.database;

    final List<Map<String, Object?>> userRows =
    await db.query(
      'users',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    final List<Map<String, Object?>> skillRows =
    await db.query(
      'skills',
      orderBy: 'title COLLATE NOCASE ASC',
    );

    final List<Map<String, Object?>> userSkillRows =
    await db.query(
      'user_skills',
      orderBy: 'id ASC',
    );

    // ----------------------------------------------------------
    // Build users
    // ----------------------------------------------------------

    final List<User> loadedUsers =
    userRows.map(_userFromMap).toList();

    // ----------------------------------------------------------
    // Build skills + ordered learnings
    // ----------------------------------------------------------

    final List<Skill> loadedSkills = [];

    for (final Map<String, Object?> skillRow
    in skillRows) {
      final String skillId =
      skillRow['id'] as String;

      final List<Map<String, Object?>>
      learningRows =
      await db.query(
        'skill_learnings',
        columns: [
          'text',
        ],
        where: 'skill_id = ?',
        whereArgs: [
          skillId,
        ],
        orderBy: 'position ASC',
      );

      final List<String> learnings =
      learningRows
          .map(
            (row) =>
        row['text'] as String,
      )
          .toList();

      loadedSkills.add(
        _skillFromMap(
          skillRow,
          learnings,
        ),
      );
    }

    // ----------------------------------------------------------
    // Build user-skill relationships
    // ----------------------------------------------------------

    final List<UserSkill> loadedUserSkills =
    userSkillRows
        .map(_userSkillFromMap)
        .toList();

    // ----------------------------------------------------------
    // Replace cache only after complete successful loading.
    //
    // This avoids leaving the repository half-populated if any
    // database operation fails during initialization.
    // ----------------------------------------------------------

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
  }

  // ============================================================
  // REFRESH
  //
  // Useful later after Add/Edit/Delete Skill operations so the
  // in-memory cache can reflect the current SQLite contents.
  // ============================================================

  Future<void> refresh() async {
    final db =
    await AppDatabase.instance.database;

    final List<Map<String, Object?>> userRows =
    await db.query(
      'users',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    final List<Map<String, Object?>> skillRows =
    await db.query(
      'skills',
      orderBy: 'title COLLATE NOCASE ASC',
    );

    final List<Map<String, Object?>> userSkillRows =
    await db.query(
      'user_skills',
      orderBy: 'id ASC',
    );

    final List<User> loadedUsers =
    userRows.map(_userFromMap).toList();

    final List<Skill> loadedSkills = [];

    for (final Map<String, Object?> skillRow
    in skillRows) {
      final String skillId =
      skillRow['id'] as String;

      final List<Map<String, Object?>>
      learningRows =
      await db.query(
        'skill_learnings',
        columns: [
          'text',
        ],
        where: 'skill_id = ?',
        whereArgs: [
          skillId,
        ],
        orderBy: 'position ASC',
      );

      loadedSkills.add(
        _skillFromMap(
          skillRow,
          learningRows
              .map(
                (row) =>
            row['text'] as String,
          )
              .toList(),
        ),
      );
    }

    final List<UserSkill> loadedUserSkills =
    userSkillRows
        .map(_userSkillFromMap)
        .toList();

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
  }

  // ============================================================
  // MAP -> USER
  // ============================================================

  User _userFromMap(
      Map<String, Object?> map,
      ) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      initials:
      map['initials'] as String,
      city: map['city'] as String,
      bio: map['bio'] as String,
      rating:
      (map['rating'] as num)
          .toDouble(),
      reviewCount:
      map['review_count'] as int,
      completedSwaps:
      map['completed_swaps'] as int,
      responseRate:
      map['response_rate'] as int,
      memberSince:
      map['member_since'] as String,
      availability:
      map['availability'] as String,
      language:
      map['language'] as String,
      preferredMode:
      map['preferred_mode'] as String,
      teachingStyle:
      map['teaching_style'] as String,
      emailVerified:
      (map['email_verified'] as int) ==
          1,
      profileCompleted:
      (map['profile_completed'] as int) ==
          1,
    );
  }

  // ============================================================
  // MAP -> SKILL
  // ============================================================

  Skill _skillFromMap(
      Map<String, Object?> map,
      List<String> learnings,
      ) {
    final int iconCodePoint =
    map['icon_code_point'] as int;

    return Skill(
      id: map['id'] as String,
      title: map['title'] as String,
      category:
      map['category'] as String,
      level: map['level'] as String,

      // Material icon persisted as its numeric code point.
      icon: IconData(
        iconCodePoint,
        fontFamily: 'MaterialIcons',
      ),

      sessionLength:
      map['session_length'] as String,
      mode: map['mode'] as String,
      language:
      map['language'] as String,
      prerequisite:
      map['prerequisite'] as String,
      description:
      map['description'] as String,
      learnings:
      List.unmodifiable(
        learnings,
      ),
    );
  }

  // ============================================================
  // MAP -> USER SKILL
  // ============================================================

  UserSkill _userSkillFromMap(
      Map<String, Object?> map,
      ) {
    final String type =
    map['type'] as String;

    late final UserSkillType parsedType;

    switch (type) {
      case 'offered':
        parsedType =
            UserSkillType.offered;
        break;

      case 'wanted':
        parsedType =
            UserSkillType.wanted;
        break;

      default:
        throw StateError(
          'Unknown user skill type: $type',
        );
    }

    return UserSkill(
      id: map['id'] as String,
      userId:
      map['user_id'] as String,
      skillId:
      map['skill_id'] as String,
      type: parsedType,
      level:
      map['level'] as String,
      availability:
      map['availability'] as String,
    );
  }

  // ============================================================
  // PUBLIC READ METHODS
  // ============================================================

  List<User> get users =>
      List.unmodifiable(
        _users,
      );

  List<Skill> get skills =>
      List.unmodifiable(
        _skills,
      );

  List<UserSkill> get userSkills =>
      List.unmodifiable(
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

    for (final User user in _users) {
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

  List<UserSkill>
  getOfferedSkillsForUser(
      String userId,
      ) {
    final String normalizedUserId =
    userId.trim();

    if (normalizedUserId.isEmpty) {
      return [];
    }

    return _userSkills
        .where(
          (item) =>
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

  List<UserSkill>
  getWantedSkillsForUser(
      String userId,
      ) {
    final String normalizedUserId =
    userId.trim();

    if (normalizedUserId.isEmpty) {
      return [];
    }

    return _userSkills
        .where(
          (item) =>
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
      return [];
    }

    final Set<String> providerIds =
    _userSkills
        .where(
          (item) =>
      item.skillId ==
          normalizedSkillId &&
          item.type ==
              UserSkillType.offered,
    )
        .map(
          (item) =>
      item.userId,
    )
        .toSet();

    return _users
        .where(
          (user) =>
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
          item.type == type) {
        return item;
      }
    }

    return null;
  }
}