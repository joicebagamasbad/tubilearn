import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../services/current_user_service.dart';
import '../database/app_database.dart';
import '../skill.dart';
import '../user.dart';
import '../user_skill.dart';
import 'firestore_my_skills_repository.dart';
import 'firestore_profile_repository.dart';

class LocalUserDataProjectionException implements Exception {
  final String message;

  const LocalUserDataProjectionException(this.message);

  @override
  String toString() => message;
}

class LocalManagedSkillRecord {
  final Skill skill;
  final UserSkill userSkill;
  final String? ownerUid;

  const LocalManagedSkillRecord({
    required this.skill,
    required this.userSkill,
    required this.ownerUid,
  });
}

class LocalUserSkillsSnapshot {
  final List<LocalManagedSkillRecord> records;

  const LocalUserSkillsSnapshot(this.records);
}

class LocalUserDataProjectionRepository {
  LocalUserDataProjectionRepository({
    AppDatabase? database,
    CurrentUserService? currentUserService,
  }) : _database = database ?? AppDatabase.instance,
       _currentUserService = currentUserService ?? CurrentUserService.instance;

  static final LocalUserDataProjectionRepository instance =
      LocalUserDataProjectionRepository();

  final AppDatabase _database;
  final CurrentUserService _currentUserService;

  Future<User?> loadProfile(String uid) async {
    final String cleanUid = _requireUid(uid);
    try {
      final Database db = await _database.database;
      _requireActiveUid(cleanUid);
      final List<Map<String, Object?>> rows = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: <Object?>[cleanUid],
        limit: 1,
      );
      _requireActiveUid(cleanUid);
      if (rows.isEmpty) return null;
      if (rows.length != 1) {
        throw const LocalUserDataProjectionException(
          'The local user profile is not unique.',
        );
      }
      return _userFromRow(rows.single);
    } on LocalUserDataProjectionException {
      rethrow;
    } on DatabaseException {
      throw const LocalUserDataProjectionException(
        'The local user profile could not be loaded.',
      );
    } catch (_) {
      throw const LocalUserDataProjectionException(
        'The local user profile could not be loaded.',
      );
    }
  }

  Future<LocalUserSkillsSnapshot> loadSkills(String uid) async {
    final String cleanUid = _requireUid(uid);
    try {
      final Database db = await _database.database;
      _requireActiveUid(cleanUid);
      final List<Map<String, Object?>> rows = await db.rawQuery(
        '''
        SELECT
          us.id AS user_skill_id,
          us.user_id,
          us.skill_id,
          us.type,
          us.level AS user_level,
          us.availability,
          s.owner_user_id,
          s.title,
          s.category,
          s.level AS skill_level,
          s.icon_code_point,
          s.session_length,
          s.mode,
          s.language,
          s.prerequisite,
          s.description
        FROM user_skills us
        INNER JOIN skills s ON s.id = us.skill_id
        WHERE us.user_id = ?
        ORDER BY lower(s.title), us.type, us.id
        ''',
        <Object?>[cleanUid],
      );
      _requireActiveUid(cleanUid);
      if (rows.isEmpty) {
        return const LocalUserSkillsSnapshot(<LocalManagedSkillRecord>[]);
      }

      final Set<String> skillIds = rows
          .map(
            (Map<String, Object?> row) =>
                _requiredString(row, 'skill_id', 'Skill ID'),
          )
          .toSet();
      final String placeholders = List<String>.filled(
        skillIds.length,
        '?',
      ).join(',');
      final List<Map<String, Object?>> learningRows = await db.rawQuery('''
        SELECT skill_id, position, text
        FROM skill_learnings
        WHERE skill_id IN ($placeholders)
        ORDER BY skill_id, position
        ''', skillIds.cast<Object?>().toList(growable: false));
      _requireActiveUid(cleanUid);
      final Map<String, List<String>> learnings = <String, List<String>>{};
      for (final Map<String, Object?> row in learningRows) {
        final String skillId = _requiredString(row, 'skill_id', 'Skill ID');
        final int position = _requiredInt(row, 'position', 'Learning position');
        final String text = _requiredString(row, 'text', 'Learning text');
        final List<String> items = learnings.putIfAbsent(
          skillId,
          () => <String>[],
        );
        if (position != items.length) {
          throw const LocalUserDataProjectionException(
            'Local skill learning positions are invalid.',
          );
        }
        items.add(text);
      }

      final List<LocalManagedSkillRecord> result = <LocalManagedSkillRecord>[];
      final Set<String> relationshipIds = <String>{};
      final Set<String> relationshipKeys = <String>{};
      for (final Map<String, Object?> row in rows) {
        final String relationshipId = _requiredString(
          row,
          'user_skill_id',
          'User skill ID',
        );
        final String skillId = _requiredString(row, 'skill_id', 'Skill ID');
        final UserSkillType type = _typeFromString(
          _requiredString(row, 'type', 'User skill type'),
        );
        if (!relationshipIds.add(relationshipId) ||
            !relationshipKeys.add('$skillId:${type.name}')) {
          throw const LocalUserDataProjectionException(
            'Local skills contain duplicate relationships.',
          );
        }
        final Skill skill = Skill(
          id: skillId,
          title: _requiredString(row, 'title', 'Skill title'),
          category: _requiredString(row, 'category', 'Skill category'),
          level: _requiredString(row, 'skill_level', 'Skill level'),
          icon: IconData(
            // ignore: non_const_argument_for_const_parameter
            _positiveInt(row, 'icon_code_point', 'Skill icon'),
            fontFamily: 'MaterialIcons',
          ),
          sessionLength: _requiredString(
            row,
            'session_length',
            'Session length',
          ),
          mode: _requiredString(row, 'mode', 'Skill mode'),
          language: _requiredString(row, 'language', 'Skill language'),
          prerequisite: _stringAllowEmpty(row, 'prerequisite', 'Prerequisite'),
          description: _requiredString(row, 'description', 'Skill description'),
          learnings: List<String>.unmodifiable(
            learnings[skillId] ?? const <String>[],
          ),
        );
        result.add(
          LocalManagedSkillRecord(
            skill: skill,
            userSkill: UserSkill(
              id: relationshipId,
              userId: cleanUid,
              skillId: skillId,
              type: type,
              level: _requiredString(row, 'user_level', 'User skill level'),
              availability: _requiredString(
                row,
                'availability',
                'Availability',
              ),
            ),
            ownerUid: _optionalString(row, 'owner_user_id', 'Skill owner'),
          ),
        );
      }
      return LocalUserSkillsSnapshot(
        List<LocalManagedSkillRecord>.unmodifiable(result),
      );
    } on LocalUserDataProjectionException {
      rethrow;
    } on DatabaseException {
      throw const LocalUserDataProjectionException(
        'Local skills could not be loaded.',
      );
    } catch (_) {
      throw const LocalUserDataProjectionException(
        'Local skills could not be loaded.',
      );
    }
  }

  Future<User> projectProfile({
    required String uid,
    required FirestoreProfileData profile,
  }) async {
    final String cleanUid = _requireUid(uid);
    final String initials = _buildInitials(profile.name);
    try {
      final Database db = await _database.database;
      _requireActiveUid(cleanUid);
      final int updated = await db.update(
        'users',
        <String, Object?>{
          'name': profile.name.trim(),
          'initials': initials,
          'city': profile.city.trim(),
          'bio': profile.bio.trim(),
          'member_since': profile.memberSince.trim(),
          'availability': profile.availability.trim(),
          'language': profile.language.trim(),
          'preferred_mode': profile.preferredMode.trim(),
          'teaching_style': profile.teachingStyle.trim(),
          'profile_completed': profile.profileCompleted ? 1 : 0,
        },
        where: 'id = ? AND id != ?',
        whereArgs: <Object?>[cleanUid, 'user_joice_local'],
      );
      if (updated != 1) {
        throw const LocalUserDataProjectionException(
          'The same-account local profile could not be found.',
        );
      }
      final User? projected = await loadProfile(cleanUid);
      if (projected == null) {
        throw const LocalUserDataProjectionException(
          'The projected local profile could not be reloaded.',
        );
      }
      return projected;
    } on LocalUserDataProjectionException {
      rethrow;
    } on DatabaseException {
      throw const LocalUserDataProjectionException(
        'The cloud profile was saved but its local copy could not be updated.',
      );
    } catch (_) {
      throw const LocalUserDataProjectionException(
        'The cloud profile was saved but its local copy could not be updated.',
      );
    }
  }

  Future<void> projectSkills({
    required String uid,
    required FirestoreMySkillsSnapshot snapshot,
  }) async {
    final String cleanUid = _requireUid(uid);
    if (snapshot.source == FirestoreMySkillsSource.unavailable) {
      throw const LocalUserDataProjectionException(
        'Unavailable cloud skills cannot replace the local projection.',
      );
    }
    try {
      final Database db = await _database.database;
      _requireActiveUid(cleanUid);
      await db.transaction((Transaction transaction) async {
        _requireActiveUid(cleanUid);
        final List<Map<String, Object?>> userRows = await transaction.query(
          'users',
          columns: <String>['id'],
          where: 'id = ? AND id != ?',
          whereArgs: <Object?>[cleanUid, 'user_joice_local'],
          limit: 1,
        );
        _requireActiveUid(cleanUid);
        if (userRows.length != 1) {
          throw const LocalUserDataProjectionException(
            'The same-account local profile could not be found.',
          );
        }

        final Map<String, FirestoreSkillRecord> catalog =
            <String, FirestoreSkillRecord>{};
        for (final FirestoreManagedSkillRecord record in snapshot.records) {
          final FirestoreSkillRecord? previous =
              catalog[record.catalog.skill.id];
          if (previous != null &&
              (previous.ownerUid != record.catalog.ownerUid ||
                  previous.skill.title != record.catalog.skill.title)) {
            throw const LocalUserDataProjectionException(
              'Cloud catalog data is inconsistent.',
            );
          }
          catalog[record.catalog.skill.id] = record.catalog;
        }

        final Map<String, String> effectiveLocalSkillIds = <String, String>{};
        for (final FirestoreSkillRecord record in catalog.values) {
          _requireActiveUid(cleanUid);
          effectiveLocalSkillIds[record.skill.id] = await _projectCatalogSkill(
            transaction,
            cleanUid,
            record,
          );
        }

        final Set<String> cloudRelationshipIds = <String>{};
        final Map<String, Set<UserSkillType>> cloudRelationshipTypes =
            <String, Set<UserSkillType>>{};
        for (final FirestoreManagedSkillRecord record in snapshot.records) {
          final UserSkill relationship = record.link.userSkill;
          if (relationship.userId != cleanUid ||
              !cloudRelationshipIds.add(relationship.id)) {
            throw const LocalUserDataProjectionException(
              'Cloud skill relationship ownership is invalid.',
            );
          }
          final String? effectiveLocalSkillId =
              effectiveLocalSkillIds[relationship.skillId];
          if (effectiveLocalSkillId == null) {
            throw const LocalUserDataProjectionException(
              'Cloud skill relationship catalog data is invalid.',
            );
          }
          final Set<UserSkillType> types = cloudRelationshipTypes.putIfAbsent(
            effectiveLocalSkillId,
            () => <UserSkillType>{},
          );
          if (!types.add(relationship.type)) {
            throw const LocalUserDataProjectionException(
              'Cloud skill relationships resolve to the same local skill.',
            );
          }
        }

        for (final FirestoreManagedSkillRecord record in snapshot.records) {
          final UserSkill relationship = record.link.userSkill;
          final String effectiveLocalSkillId =
              effectiveLocalSkillIds[relationship.skillId]!;
          final List<Map<String, Object?>> existing = await transaction.query(
            'user_skills',
            columns: <String>['user_id'],
            where: 'id = ?',
            whereArgs: <Object?>[relationship.id],
            limit: 1,
          );
          _requireActiveUid(cleanUid);
          if (existing.isNotEmpty &&
              _requiredString(existing.single, 'user_id', 'User ID') !=
                  cleanUid) {
            throw const LocalUserDataProjectionException(
              'A stable relationship ID belongs to another local account.',
            );
          }
          bool hasExistingRelationship = existing.isNotEmpty;
          final List<Map<String, Object?>> tupleConflicts = await transaction
              .query(
                'user_skills',
                columns: <String>['id'],
                where: 'user_id = ? AND skill_id = ? AND type = ? AND id != ?',
                whereArgs: <Object?>[
                  cleanUid,
                  effectiveLocalSkillId,
                  relationship.type.name,
                  relationship.id,
                ],
                limit: 2,
              );
          _requireActiveUid(cleanUid);
          if (tupleConflicts.length > 1) {
            throw const LocalUserDataProjectionException(
              'Local skills contain duplicate relationships.',
            );
          }
          if (tupleConflicts.isNotEmpty) {
            final String staleRelationshipId = _requiredString(
              tupleConflicts.single,
              'id',
              'User skill ID',
            );
            if (cloudRelationshipIds.contains(staleRelationshipId)) {
              throw const LocalUserDataProjectionException(
                'Cloud skill relationships conflict with the local projection.',
              );
            }
            _requireActiveUid(cleanUid);
            if (hasExistingRelationship) {
              final int deleted = await transaction.delete(
                'user_skills',
                where:
                    'id = ? AND user_id = ? AND skill_id = ? AND type = ?',
                whereArgs: <Object?>[
                  staleRelationshipId,
                  cleanUid,
                  effectiveLocalSkillId,
                  relationship.type.name,
                ],
              );
              _requireActiveUid(cleanUid);
              if (deleted != 1) {
                throw const LocalUserDataProjectionException(
                  'A stale local skill relationship could not be reconciled.',
                );
              }
            } else {
              final int changed = await transaction.update(
                'user_skills',
                <String, Object?>{'id': relationship.id},
                where:
                    'id = ? AND user_id = ? AND skill_id = ? AND type = ?',
                whereArgs: <Object?>[
                  staleRelationshipId,
                  cleanUid,
                  effectiveLocalSkillId,
                  relationship.type.name,
                ],
              );
              _requireActiveUid(cleanUid);
              if (changed != 1) {
                throw const LocalUserDataProjectionException(
                  'A stale local skill relationship could not be reconciled.',
                );
              }
              hasExistingRelationship = true;
            }
          }
          final Map<String, Object?> values = <String, Object?>{
            'id': relationship.id,
            'user_id': cleanUid,
            'skill_id': effectiveLocalSkillId,
            'type': relationship.type.name,
            'level': relationship.level,
            'availability': relationship.availability,
          };
          if (!hasExistingRelationship) {
            _requireActiveUid(cleanUid);
            await transaction.insert(
              'user_skills',
              values,
              conflictAlgorithm: ConflictAlgorithm.abort,
            );
            _requireActiveUid(cleanUid);
          } else {
            _requireActiveUid(cleanUid);
            final int changed = await transaction.update(
              'user_skills',
              values,
              where: 'id = ? AND user_id = ?',
              whereArgs: <Object?>[relationship.id, cleanUid],
            );
            _requireActiveUid(cleanUid);
            if (changed != 1) {
              throw const LocalUserDataProjectionException(
                'A local skill relationship could not be updated.',
              );
            }
          }
        }

        final List<Map<String, Object?>> localRelationships = await transaction
            .query(
              'user_skills',
              columns: <String>['id'],
              where: 'user_id = ?',
              whereArgs: <Object?>[cleanUid],
            );
        _requireActiveUid(cleanUid);
        for (final Map<String, Object?> row in localRelationships) {
          final String relationshipId = _requiredString(
            row,
            'id',
            'User skill ID',
          );
          if (!cloudRelationshipIds.contains(relationshipId)) {
            _requireActiveUid(cleanUid);
            final int deleted = await transaction.delete(
              'user_skills',
              where: 'id = ? AND user_id = ?',
              whereArgs: <Object?>[relationshipId, cleanUid],
            );
            _requireActiveUid(cleanUid);
            if (deleted != 1) {
              throw const LocalUserDataProjectionException(
                'A stale local skill relationship could not be removed.',
              );
            }
          }
        }
        _requireActiveUid(cleanUid);
      });
    } on LocalUserDataProjectionException {
      rethrow;
    } on DatabaseException {
      throw const LocalUserDataProjectionException(
        'Cloud skills were saved but their local copy could not be updated.',
      );
    } catch (_) {
      throw const LocalUserDataProjectionException(
        'Cloud skills were saved but their local copy could not be updated.',
      );
    }
  }

  Future<String> _projectCatalogSkill(
    Transaction transaction,
    String activeUid,
    FirestoreSkillRecord record,
  ) async {
    final Skill skill = record.skill;
    final String? ownerUid = record.ownerUid;
    if (ownerUid == 'user_joice_local') {
      throw const LocalUserDataProjectionException(
        'Legacy local skill ownership cannot be projected from Firestore.',
      );
    }
    final List<Map<String, Object?>> existing = await transaction.query(
      'skills',
      columns: <String>['owner_user_id'],
      where: 'id = ?',
      whereArgs: <Object?>[skill.id],
      limit: 1,
    );
    _requireActiveUid(activeUid);
    final List<Map<String, Object?>> normalizedTitleMatches = await transaction
        .rawQuery('''
      SELECT id
      FROM skills
      WHERE lower(trim(title)) = lower(trim(?))
      ORDER BY id
      LIMIT 2
      ''', <Object?>[skill.title]);
    _requireActiveUid(activeUid);
    if (normalizedTitleMatches.length > 1) {
      throw const LocalUserDataProjectionException(
        'Multiple local catalog skills use the same normalized title.',
      );
    }
    if (existing.isNotEmpty) {
      if (normalizedTitleMatches.isNotEmpty &&
          _requiredString(
                normalizedTitleMatches.single,
                'id',
                'Skill ID',
              ) !=
              skill.id) {
        throw const LocalUserDataProjectionException(
          'The cloud skill ID conflicts with an existing local catalog title.',
        );
      }
      final String? existingOwner = _optionalString(
        existing.single,
        'owner_user_id',
        'Skill owner',
      );
      if (existingOwner == 'user_joice_local' || existingOwner != ownerUid) {
        throw const LocalUserDataProjectionException(
          'Cloud projection cannot reassign existing local skill ownership.',
        );
      }
    } else if (normalizedTitleMatches.isNotEmpty) {
      return _requiredString(
        normalizedTitleMatches.single,
        'id',
        'Skill ID',
      );
    }

    if (ownerUid != null && ownerUid != activeUid) {
      final List<Map<String, Object?>> ownerRows = await transaction.query(
        'users',
        columns: <String>['id'],
        where: 'id = ? AND id != ?',
        whereArgs: <Object?>[ownerUid, 'user_joice_local'],
        limit: 1,
      );
      _requireActiveUid(activeUid);
      if (ownerRows.length != 1) {
        throw const LocalUserDataProjectionException(
          'A shared custom skill owner is not available in the local cache.',
        );
      }
    }

    final Map<String, Object?> values = <String, Object?>{
      'id': skill.id,
      'owner_user_id': ownerUid,
      'title': skill.title,
      'category': skill.category,
      'level': skill.level,
      'icon_code_point': skill.icon.codePoint,
      'session_length': skill.sessionLength,
      'mode': skill.mode,
      'language': skill.language,
      'prerequisite': skill.prerequisite,
      'description': skill.description,
    };
    if (existing.isEmpty) {
      _requireActiveUid(activeUid);
      await transaction.insert(
        'skills',
        values,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      _requireActiveUid(activeUid);
    } else {
      _requireActiveUid(activeUid);
      final int changed = await transaction.update(
        'skills',
        values,
        where: 'id = ?',
        whereArgs: <Object?>[skill.id],
      );
      _requireActiveUid(activeUid);
      if (changed != 1) {
        throw const LocalUserDataProjectionException(
          'A local skill catalog entry could not be updated.',
        );
      }
    }

    _requireActiveUid(activeUid);
    await transaction.delete(
      'skill_learnings',
      where: 'skill_id = ?',
      whereArgs: <Object?>[skill.id],
    );
    _requireActiveUid(activeUid);
    for (int index = 0; index < skill.learnings.length; index++) {
      _requireActiveUid(activeUid);
      await transaction.insert('skill_learnings', <String, Object?>{
        'skill_id': skill.id,
        'position': index,
        'text': skill.learnings[index],
      }, conflictAlgorithm: ConflictAlgorithm.abort);
      _requireActiveUid(activeUid);
    }
    return skill.id;
  }

  User _userFromRow(Map<String, Object?> row) {
    final double rating = _requiredNumber(row, 'rating', 'Rating').toDouble();
    final int reviewCount = _requiredInt(row, 'review_count', 'Review count');
    final int completedSwaps = _requiredInt(
      row,
      'completed_swaps',
      'Completed swaps',
    );
    final int responseRate = _requiredInt(
      row,
      'response_rate',
      'Response rate',
    );
    if (rating < 0 ||
        rating > 5 ||
        reviewCount < 0 ||
        completedSwaps < 0 ||
        responseRate < 0 ||
        responseRate > 100) {
      throw const LocalUserDataProjectionException(
        'Local profile metrics are invalid.',
      );
    }
    return User(
      id: _requiredString(row, 'id', 'User ID'),
      name: _requiredString(row, 'name', 'Name'),
      initials: _requiredString(row, 'initials', 'Initials'),
      city: _requiredString(row, 'city', 'City'),
      bio: _stringAllowEmpty(row, 'bio', 'Bio'),
      rating: rating,
      reviewCount: reviewCount,
      completedSwaps: completedSwaps,
      responseRate: responseRate,
      memberSince: _requiredString(row, 'member_since', 'Member since'),
      availability: _requiredString(row, 'availability', 'Availability'),
      language: _requiredString(row, 'language', 'Language'),
      preferredMode: _requiredString(row, 'preferred_mode', 'Preferred mode'),
      teachingStyle: _requiredString(row, 'teaching_style', 'Teaching style'),
      emailVerified: _booleanFlag(row, 'email_verified', 'Email verification'),
      profileCompleted: _booleanFlag(
        row,
        'profile_completed',
        'Profile completion',
      ),
      profileImagePath: _optionalString(
        row,
        'profile_image_path',
        'Profile image path',
      ),
    );
  }

  String _buildInitials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      throw const LocalUserDataProjectionException('Profile name is invalid.');
    }
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _requireUid(String uid) {
    final String clean = uid.trim();
    if (clean.isEmpty || clean == 'user_joice_local') {
      throw const LocalUserDataProjectionException(
        'A valid authenticated user ID is required.',
      );
    }
    try {
      _currentUserService.requireCurrentUser(
        clean,
        message: 'The local projection is limited to the active account.',
      );
    } on CurrentUserServiceException catch (error) {
      throw LocalUserDataProjectionException(error.message);
    }
    return clean;
  }

  void _requireActiveUid(String uid) {
    try {
      _currentUserService.requireCurrentUser(
        uid,
        message: 'The authenticated account changed during local projection.',
      );
    } on CurrentUserServiceException catch (error) {
      throw LocalUserDataProjectionException(error.message);
    }
  }

  UserSkillType _typeFromString(String value) {
    switch (value) {
      case 'offered':
        return UserSkillType.offered;
      case 'wanted':
        return UserSkillType.wanted;
      default:
        throw const LocalUserDataProjectionException(
          'Local user skill type is invalid.',
        );
    }
  }

  String _requiredString(Map<String, Object?> row, String key, String label) {
    final Object? value = row[key];
    if (value is! String || value.trim().isEmpty) {
      throw LocalUserDataProjectionException('$label is invalid.');
    }
    return value.trim();
  }

  String _stringAllowEmpty(Map<String, Object?> row, String key, String label) {
    final Object? value = row[key];
    if (value is! String) {
      throw LocalUserDataProjectionException('$label is invalid.');
    }
    return value.trim();
  }

  String? _optionalString(Map<String, Object?> row, String key, String label) {
    if (!row.containsKey(key)) {
      throw LocalUserDataProjectionException('$label is missing.');
    }
    final Object? value = row[key];
    if (value == null) return null;
    if (value is! String) {
      throw LocalUserDataProjectionException('$label is invalid.');
    }
    final String clean = value.trim();
    return clean.isEmpty ? null : clean;
  }

  int _requiredInt(Map<String, Object?> row, String key, String label) {
    final Object? value = row[key];
    if (value is! int) {
      throw LocalUserDataProjectionException('$label is invalid.');
    }
    return value;
  }

  int _positiveInt(Map<String, Object?> row, String key, String label) {
    final int value = _requiredInt(row, key, label);
    if (value <= 0) {
      throw LocalUserDataProjectionException('$label is invalid.');
    }
    return value;
  }

  num _requiredNumber(Map<String, Object?> row, String key, String label) {
    final Object? value = row[key];
    if (value is! num) {
      throw LocalUserDataProjectionException('$label is invalid.');
    }
    return value;
  }

  bool _booleanFlag(Map<String, Object?> row, String key, String label) {
    final int value = _requiredInt(row, key, label);
    if (value != 0 && value != 1) {
      throw LocalUserDataProjectionException('$label is invalid.');
    }
    return value == 1;
  }
}
