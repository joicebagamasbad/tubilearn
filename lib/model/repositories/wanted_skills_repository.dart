import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../services/current_user_service.dart';
import '../database/app_database.dart';
import '../skill.dart';
import '../user_skill.dart';
import 'explore_repository.dart';

class WantedSkillsRepositoryException implements Exception {
  final String message;

  const WantedSkillsRepositoryException(
      this.message,
      );

  @override
  String toString() => message;
}

class ManagedWantedSkill {
  final Skill skill;
  final UserSkill userSkill;
  final String? ownerUserId;

  const ManagedWantedSkill({
    required this.skill,
    required this.userSkill,
    required this.ownerUserId,
  });

  bool metadataCanBeEditedBy(
      String userId,
      ) {
    return ownerUserId != null &&
        ownerUserId == userId.trim();
  }
}

class WantedSkillsRepository {
  WantedSkillsRepository._();

  static final WantedSkillsRepository instance =
  WantedSkillsRepository._();

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  int _lastGeneratedIdValue = 0;

  // ============================================================
  // GET WANTED SKILLS
  // ============================================================

  Future<List<ManagedWantedSkill>> getWantedSkills(
      String userId,
      ) async {
    final String cleanUserId =
    _requireCurrentLocalUser(
      userId,
    );

    try {
      await ExploreRepository.instance.refresh();

      final List<UserSkill> relationships =
      ExploreRepository.instance
          .getWantedSkillsForUser(
        cleanUserId,
      );

      if (relationships.isEmpty) {
        return const <ManagedWantedSkill>[];
      }

      final Database db =
      await AppDatabase.instance.database;

      final Set<String> skillIds =
      relationships
          .map(
            (
            UserSkill relationship,
            ) =>
            relationship.skillId.trim(),
      )
          .where(
            (
            String id,
            ) =>
        id.isNotEmpty,
      )
          .toSet();

      if (skillIds.length !=
          relationships.length) {
        throw const WantedSkillsRepositoryException(
          'Saved learning interests contain invalid or duplicate skill references.',
        );
      }

      final String placeholders =
      List<String>.filled(
        skillIds.length,
        '?',
      ).join(',');

      final List<Map<String, Object?>> skillRows =
      await db.rawQuery(
        '''
        SELECT
          id,
          owner_user_id
        FROM skills
        WHERE id IN ($placeholders)
        ''',
        skillIds
            .cast<Object?>()
            .toList(
          growable: false,
        ),
      );

      final Map<String, String?> ownersBySkillId =
      <String, String?>{};

      for (final Map<String, Object?> row
      in skillRows) {
        final String skillId =
        _requireRowString(
          row,
          'id',
          'Skill ID',
        );

        if (ownersBySkillId.containsKey(
          skillId,
        )) {
          throw const WantedSkillsRepositoryException(
            'Stored skill data contains duplicate IDs.',
          );
        }

        ownersBySkillId[skillId] =
            _readOptionalString(
              row,
              'owner_user_id',
              'Skill owner',
            );
      }

      if (ownersBySkillId.length !=
          skillIds.length) {
        throw const WantedSkillsRepositoryException(
          'One or more learning interests could not be found.',
        );
      }

      final List<ManagedWantedSkill> result =
      <ManagedWantedSkill>[];

      for (final UserSkill relationship
      in relationships) {
        final Skill? skill =
        ExploreRepository.instance
            .findSkillById(
          relationship.skillId,
        );

        if (skill == null) {
          throw const WantedSkillsRepositoryException(
            'A learning interest points to a missing skill.',
          );
        }

        result.add(
          ManagedWantedSkill(
            skill: skill,
            userSkill: relationship,
            ownerUserId:
            ownersBySkillId[
            relationship.skillId],
          ),
        );
      }

      result.sort(
            (
            ManagedWantedSkill a,
            ManagedWantedSkill b,
            ) =>
            a.skill.title
                .toLowerCase()
                .compareTo(
              b.skill.title
                  .toLowerCase(),
            ),
      );

      return List<ManagedWantedSkill>.unmodifiable(
        result,
      );
    } on WantedSkillsRepositoryException {
      rethrow;
    } on ExploreRepositoryException {
      throw const WantedSkillsRepositoryException(
        'Could not load your learning interests. Please try again.',
      );
    } on DatabaseException {
      throw const WantedSkillsRepositoryException(
        'Could not load your learning interests. Please try again.',
      );
    } catch (_) {
      throw const WantedSkillsRepositoryException(
        'Could not load your learning interests. Please try again.',
      );
    }
  }

  // ============================================================
  // ADD WANTED SKILL
  // ============================================================

  Future<void> addWantedSkill({
    required String userId,
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
  }) async {
    final String cleanUserId =
    _requireCurrentLocalUser(
      userId,
    );

    final String cleanTitle =
    _requireText(
      title,
      'Skill name',
    );

    final String cleanCategory =
    _requireText(
      category,
      'Category',
    );

    final String cleanDescription =
    _requireText(
      description,
      'Description',
    );

    final String cleanLevel =
    _validateLevel(
      level,
    );

    final String cleanAvailability =
    _requireText(
      availability,
      'Availability',
    );

    _validateLengths(
      title: cleanTitle,
      description: cleanDescription,
    );

    try {
      final Database db =
      await AppDatabase.instance.database;

      await db.transaction(
            (
            Transaction txn,
            ) async {
          final List<Map<String, Object?>> userRows =
          await txn.query(
            'users',
            columns: const <String>[
              'id',
            ],
            where: 'id = ?',
            whereArgs: <Object?>[
              cleanUserId,
            ],
            limit: 1,
          );

          if (userRows.length != 1) {
            throw const WantedSkillsRepositoryException(
              'Current user profile could not be found.',
            );
          }

          final List<Map<String, Object?>>
          existingSkills =
          await txn.rawQuery(
            '''
            SELECT
              id,
              owner_user_id
            FROM skills
            WHERE lower(trim(title)) =
                  lower(trim(?))
            LIMIT 2
            ''',
            <Object?>[
              cleanTitle,
            ],
          );

          if (existingSkills.length > 1) {
            throw const WantedSkillsRepositoryException(
              'Multiple stored skills use the same normalized name.',
            );
          }

          late final String skillId;

          if (existingSkills.isNotEmpty) {
            skillId =
                _requireRowString(
                  existingSkills.first,
                  'id',
                  'Skill ID',
                );
          } else {
            skillId =
                _generateId(
                  'skill_custom',
                );

            final int insertedSkillRowId =
            await txn.insert(
              'skills',
              <String, Object?>{
                'id':
                skillId,
                'owner_user_id':
                cleanUserId,
                'title':
                cleanTitle,
                'category':
                cleanCategory,
                'level':
                cleanLevel,
                'icon_code_point':
                _iconForCategory(
                  cleanCategory,
                ).codePoint,
                'session_length':
                'Flexible',
                'mode':
                'Online / In-person',
                'language':
                'Filipino / English',
                'prerequisite':
                '',
                'description':
                cleanDescription,
              },
              conflictAlgorithm:
              ConflictAlgorithm.abort,
            );

            if (insertedSkillRowId <= 0) {
              throw const WantedSkillsRepositoryException(
                'Could not create the learning interest.',
              );
            }
          }

          final List<Map<String, Object?>>
          existingRelationship =
          await txn.query(
            'user_skills',
            columns: const <String>[
              'id',
            ],
            where: '''
              user_id = ?
              AND skill_id = ?
              AND type = ?
            ''',
            whereArgs: <Object?>[
              cleanUserId,
              skillId,
              'wanted',
            ],
            limit: 1,
          );

          if (existingRelationship.isNotEmpty) {
            throw const WantedSkillsRepositoryException(
              'You already want to learn this skill.',
            );
          }

          final String relationshipId =
          _generateId(
            'user_skill',
          );

          final int insertedRelationshipRowId =
          await txn.insert(
            'user_skills',
            <String, Object?>{
              'id':
              relationshipId,
              'user_id':
              cleanUserId,
              'skill_id':
              skillId,
              'type':
              'wanted',
              'level':
              cleanLevel,
              'availability':
              cleanAvailability,
            },
            conflictAlgorithm:
            ConflictAlgorithm.abort,
          );

          if (insertedRelationshipRowId <= 0) {
            throw const WantedSkillsRepositoryException(
              'Could not add the learning interest to your profile.',
            );
          }
        },
      );

      await _refreshExploreAfterWrite();
    } on WantedSkillsRepositoryException {
      rethrow;
    } on DatabaseException {
      throw const WantedSkillsRepositoryException(
        'Could not add the learning interest. Please try again.',
      );
    } catch (_) {
      throw const WantedSkillsRepositoryException(
        'Could not add the learning interest. Please try again.',
      );
    }
  }

  // ============================================================
  // UPDATE WANTED SKILL
  // ============================================================

  Future<void> updateWantedSkill({
    required String userId,
    required String userSkillId,
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
  }) async {
    final String cleanUserId =
    _requireCurrentLocalUser(
      userId,
    );

    final String cleanUserSkillId =
    _requireText(
      userSkillId,
      'User skill ID',
    );

    final String cleanTitle =
    _requireText(
      title,
      'Skill name',
    );

    final String cleanCategory =
    _requireText(
      category,
      'Category',
    );

    final String cleanDescription =
    _requireText(
      description,
      'Description',
    );

    final String cleanLevel =
    _validateLevel(
      level,
    );

    final String cleanAvailability =
    _requireText(
      availability,
      'Availability',
    );

    _validateLengths(
      title: cleanTitle,
      description: cleanDescription,
    );

    try {
      final Database db =
      await AppDatabase.instance.database;

      await db.transaction(
            (
            Transaction txn,
            ) async {
          final List<Map<String, Object?>>
          relationshipRows =
          await txn.query(
            'user_skills',
            columns: const <String>[
              'id',
              'skill_id',
            ],
            where: '''
              id = ?
              AND user_id = ?
              AND type = ?
            ''',
            whereArgs: <Object?>[
              cleanUserSkillId,
              cleanUserId,
              'wanted',
            ],
            limit: 1,
          );

          if (relationshipRows.length != 1) {
            throw const WantedSkillsRepositoryException(
              'Learning interest could not be found.',
            );
          }

          final String skillId =
          _requireRowString(
            relationshipRows.first,
            'skill_id',
            'Skill ID',
          );

          final List<Map<String, Object?>> skillRows =
          await txn.query(
            'skills',
            columns: const <String>[
              'id',
              'owner_user_id',
              'title',
              'category',
              'description',
            ],
            where: 'id = ?',
            whereArgs: <Object?>[
              skillId,
            ],
            limit: 1,
          );

          if (skillRows.length != 1) {
            throw const WantedSkillsRepositoryException(
              'Skill could not be found.',
            );
          }

          final String? ownerUserId =
          _readOptionalString(
            skillRows.first,
            'owner_user_id',
            'Skill owner',
          );

          final bool ownsMetadata =
              ownerUserId ==
                  cleanUserId;

          if (ownsMetadata) {
            final List<Map<String, Object?>>
            titleConflicts =
            await txn.rawQuery(
              '''
              SELECT id
              FROM skills
              WHERE
                lower(trim(title)) =
                  lower(trim(?))
                AND id != ?
              LIMIT 1
              ''',
              <Object?>[
                cleanTitle,
                skillId,
              ],
            );

            if (titleConflicts.isNotEmpty) {
              throw const WantedSkillsRepositoryException(
                'Another skill already uses that name.',
              );
            }

            final int updatedSkillRows =
            await txn.update(
              'skills',
              <String, Object?>{
                'title':
                cleanTitle,
                'category':
                cleanCategory,
                'level':
                cleanLevel,
                'icon_code_point':
                _iconForCategory(
                  cleanCategory,
                ).codePoint,
                'description':
                cleanDescription,
              },
              where: '''
                id = ?
                AND owner_user_id = ?
              ''',
              whereArgs: <Object?>[
                skillId,
                cleanUserId,
              ],
            );

            if (updatedSkillRows != 1) {
              throw const WantedSkillsRepositoryException(
                'Could not update the learning interest details.',
              );
            }
          } else {
            final String storedTitle =
            _requireRowString(
              skillRows.first,
              'title',
              'Skill title',
            );

            final String storedCategory =
            _requireRowString(
              skillRows.first,
              'category',
              'Skill category',
            );

            final String storedDescription =
            _requireRowString(
              skillRows.first,
              'description',
              'Skill description',
            );

            if (cleanTitle != storedTitle ||
                cleanCategory != storedCategory ||
                cleanDescription !=
                    storedDescription) {
              throw const WantedSkillsRepositoryException(
                'Shared skill details cannot be changed. You can only update your level and availability.',
              );
            }
          }

          final int updatedRelationshipRows =
          await txn.update(
            'user_skills',
            <String, Object?>{
              'level':
              cleanLevel,
              'availability':
              cleanAvailability,
            },
            where: '''
              id = ?
              AND user_id = ?
              AND type = ?
            ''',
            whereArgs: <Object?>[
              cleanUserSkillId,
              cleanUserId,
              'wanted',
            ],
          );

          if (updatedRelationshipRows != 1) {
            throw const WantedSkillsRepositoryException(
              'Could not update the learning interest.',
            );
          }
        },
      );

      await _refreshExploreAfterWrite();
    } on WantedSkillsRepositoryException {
      rethrow;
    } on DatabaseException {
      throw const WantedSkillsRepositoryException(
        'Could not update the learning interest. Please try again.',
      );
    } catch (_) {
      throw const WantedSkillsRepositoryException(
        'Could not update the learning interest. Please try again.',
      );
    }
  }

  // ============================================================
  // DELETE WANTED SKILL
  // ============================================================

  Future<void> deleteWantedSkill({
    required String userId,
    required String userSkillId,
  }) async {
    final String cleanUserId =
    _requireCurrentLocalUser(
      userId,
    );

    final String cleanUserSkillId =
    _requireText(
      userSkillId,
      'User skill ID',
    );

    try {
      final Database db =
      await AppDatabase.instance.database;

      await db.transaction(
            (
            Transaction txn,
            ) async {
          final List<Map<String, Object?>>
          relationshipRows =
          await txn.query(
            'user_skills',
            columns: const <String>[
              'id',
              'skill_id',
            ],
            where: '''
              id = ?
              AND user_id = ?
              AND type = ?
            ''',
            whereArgs: <Object?>[
              cleanUserSkillId,
              cleanUserId,
              'wanted',
            ],
            limit: 1,
          );

          if (relationshipRows.length != 1) {
            throw const WantedSkillsRepositoryException(
              'Learning interest could not be found.',
            );
          }

          final String skillId =
          _requireRowString(
            relationshipRows.first,
            'skill_id',
            'Skill ID',
          );

          final int deletedRows =
          await txn.delete(
            'user_skills',
            where: '''
              id = ?
              AND user_id = ?
              AND type = ?
            ''',
            whereArgs: <Object?>[
              cleanUserSkillId,
              cleanUserId,
              'wanted',
            ],
          );

          if (deletedRows != 1) {
            throw const WantedSkillsRepositoryException(
              'Could not remove the learning interest.',
            );
          }

          await _deleteUnusedOwnedCustomSkill(
            txn: txn,
            skillId: skillId,
            userId: cleanUserId,
          );
        },
      );

      await _refreshExploreAfterWrite();
    } on WantedSkillsRepositoryException {
      rethrow;
    } on DatabaseException {
      throw const WantedSkillsRepositoryException(
        'Could not remove the learning interest. Please try again.',
      );
    } catch (_) {
      throw const WantedSkillsRepositoryException(
        'Could not remove the learning interest. Please try again.',
      );
    }
  }

  // ============================================================
  // CLEAN UP UNUSED CUSTOM SKILL
  // ============================================================

  Future<void> _deleteUnusedOwnedCustomSkill({
    required Transaction txn,
    required String skillId,
    required String userId,
  }) async {
    final List<Map<String, Object?>> skillRows =
    await txn.query(
      'skills',
      columns: const <String>[
        'id',
        'owner_user_id',
      ],
      where: 'id = ?',
      whereArgs: <Object?>[
        skillId,
      ],
      limit: 1,
    );

    if (skillRows.isEmpty) {
      return;
    }

    final String? ownerUserId =
    _readOptionalString(
      skillRows.first,
      'owner_user_id',
      'Skill owner',
    );

    if (ownerUserId != userId) {
      return;
    }

    final List<Map<String, Object?>> references =
    await txn.query(
      'user_skills',
      columns: const <String>[
        'id',
      ],
      where: 'skill_id = ?',
      whereArgs: <Object?>[
        skillId,
      ],
      limit: 1,
    );

    if (references.isNotEmpty) {
      return;
    }

    final int deletedSkillRows =
    await txn.delete(
      'skills',
      where: '''
        id = ?
        AND owner_user_id = ?
      ''',
      whereArgs: <Object?>[
        skillId,
        userId,
      ],
    );

    if (deletedSkillRows > 1) {
      throw const WantedSkillsRepositoryException(
        'Unexpected custom skill deletion result.',
      );
    }
  }

  // ============================================================
  // REFRESH EXPLORE CACHE
  // ============================================================

  Future<void> _refreshExploreAfterWrite() async {
    try {
      await ExploreRepository.instance.refresh();
    } on ExploreRepositoryException {
      throw const WantedSkillsRepositoryException(
        'Your learning interest was saved, but refreshed data could not be loaded.',
      );
    }
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String _requireCurrentLocalUser(
      String userId,
      ) {
    final String cleanUserId =
    userId.trim();

    if (cleanUserId.isEmpty) {
      throw const WantedSkillsRepositoryException(
        'User ID is required.',
      );
    }

    try {
      _currentUserService.requireCurrentUser(
        cleanUserId,
        message:
        'You can only manage learning interests for your current profile.',
      );
    } on CurrentUserServiceException catch (error) {
      throw WantedSkillsRepositoryException(
        error.message,
      );
    }

    return cleanUserId;
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String _requireText(
      String value,
      String label,
      ) {
    final String cleanValue =
    value.trim();

    if (cleanValue.isEmpty) {
      throw WantedSkillsRepositoryException(
        '$label is required.',
      );
    }

    return cleanValue;
  }

  String _validateLevel(
      String value,
      ) {
    final String cleanLevel =
    _requireText(
      value,
      'Level',
    );

    const Set<String> allowedLevels =
    <String>{
      'Beginner',
      'Intermediate',
      'Advanced',
    };

    if (!allowedLevels.contains(
      cleanLevel,
    )) {
      throw const WantedSkillsRepositoryException(
        'Level is invalid.',
      );
    }

    return cleanLevel;
  }

  void _validateLengths({
    required String title,
    required String description,
  }) {
    if (title.length > 80) {
      throw const WantedSkillsRepositoryException(
        'Skill name must be 80 characters or less.',
      );
    }

    if (description.length > 200) {
      throw const WantedSkillsRepositoryException(
        'Description must be 200 characters or less.',
      );
    }
  }

  // ============================================================
  // ROW PARSING
  // ============================================================

  String _requireRowString(
      Map<String, Object?> row,
      String key,
      String label,
      ) {
    final Object? value =
    row[key];

    if (value is! String) {
      throw WantedSkillsRepositoryException(
        '$label is invalid.',
      );
    }

    final String cleanValue =
    value.trim();

    if (cleanValue.isEmpty) {
      throw WantedSkillsRepositoryException(
        '$label is required.',
      );
    }

    return cleanValue;
  }

  String? _readOptionalString(
      Map<String, Object?> row,
      String key,
      String label,
      ) {
    final Object? value =
    row[key];

    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw WantedSkillsRepositoryException(
        '$label is invalid.',
      );
    }

    final String cleanValue =
    value.trim();

    if (cleanValue.isEmpty) {
      return null;
    }

    return cleanValue;
  }

  // ============================================================
  // ID GENERATION
  // ============================================================

  String _generateId(
      String prefix,
      ) {
    final int currentMicros =
        DateTime.now()
            .microsecondsSinceEpoch;

    if (currentMicros >
        _lastGeneratedIdValue) {
      _lastGeneratedIdValue =
          currentMicros;
    } else {
      _lastGeneratedIdValue++;
    }

    return '${prefix}_$_lastGeneratedIdValue';
  }

  // ============================================================
  // CATEGORY ICON
  // ============================================================

  IconData _iconForCategory(
      String category,
      ) {
    switch (category.trim()) {
      case 'Design & Creative':
        return Icons.design_services_outlined;

      case 'Technology':
        return Icons.code_rounded;

      case 'Photography':
        return Icons.camera_alt_outlined;

      case 'Video & Media':
        return Icons.movie_creation_outlined;

      case 'Music':
        return Icons.music_note_rounded;

      case 'Language':
        return Icons.translate_rounded;

      case 'Education':
        return Icons.school_outlined;

      case 'Lifestyle':
        return Icons.self_improvement_rounded;

      default:
        return Icons.lightbulb_outline_rounded;
    }
  }
}