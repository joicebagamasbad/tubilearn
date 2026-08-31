import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../services/current_user_service.dart';
import '../database/app_database.dart';
import '../skill.dart';
import '../user_skill.dart';
import 'explore_repository.dart';

class MySkillsRepositoryException implements Exception {
  final String message;

  const MySkillsRepositoryException(
      this.message,
      );

  @override
  String toString() => message;
}

// ============================================================
// MANAGED SKILL
// ============================================================

class ManagedSkill {
  final Skill skill;
  final UserSkill userSkill;
  final String? ownerUserId;

  const ManagedSkill({
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

class MySkillsRepository {
  MySkillsRepository._();

  static final MySkillsRepository instance =
  MySkillsRepository._();

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  int _lastGeneratedIdValue = 0;

  // ============================================================
  // GET OFFERED SKILLS
  // ============================================================

  Future<List<ManagedSkill>> getOfferedSkills(
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
          .getOfferedSkillsForUser(
        cleanUserId,
      );

      if (relationships.isEmpty) {
        return const <ManagedSkill>[];
      }

      final Database db =
      await AppDatabase.instance.database;

      // --------------------------------------------------------
      // LOAD ALL SKILL OWNERS IN ONE QUERY
      //
      // Previous implementation queried the skills table once
      // per relationship. This keeps reads bounded as the user's
      // skill list grows.
      // --------------------------------------------------------

      final Set<String> relationshipSkillIds =
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

      if (relationshipSkillIds.length !=
          relationships.length) {
        throw const MySkillsRepositoryException(
          'Saved skill relationships contain invalid or duplicate skill references.',
        );
      }

      final String placeholders =
      List<String>.filled(
        relationshipSkillIds.length,
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
        relationshipSkillIds
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
          throw const MySkillsRepositoryException(
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
          relationshipSkillIds.length) {
        throw const MySkillsRepositoryException(
          'One or more saved skills could not be found.',
        );
      }

      final List<ManagedSkill> results =
      <ManagedSkill>[];

      for (final UserSkill relationship
      in relationships) {
        final Skill? skill =
        ExploreRepository.instance
            .findSkillById(
          relationship.skillId,
        );

        if (skill == null) {
          throw const MySkillsRepositoryException(
            'A saved skill relationship points to a missing skill.',
          );
        }

        if (!ownersBySkillId.containsKey(
          skill.id,
        )) {
          throw const MySkillsRepositoryException(
            'Skill ownership details could not be found.',
          );
        }

        results.add(
          ManagedSkill(
            skill: skill,
            userSkill: relationship,
            ownerUserId:
            ownersBySkillId[skill.id],
          ),
        );
      }

      results.sort(
            (
            ManagedSkill a,
            ManagedSkill b,
            ) =>
            a.skill.title
                .toLowerCase()
                .compareTo(
              b.skill.title
                  .toLowerCase(),
            ),
      );

      return List<ManagedSkill>.unmodifiable(
        results,
      );
    } on MySkillsRepositoryException {
      rethrow;
    } on ExploreRepositoryException catch (_) {
      throw const MySkillsRepositoryException(
        'Could not load your skills. Please try again.',
      );
    } on DatabaseException catch (_) {
      throw const MySkillsRepositoryException(
        'Could not load your skills. Please try again.',
      );
    } catch (_) {
      throw const MySkillsRepositoryException(
        'Could not load your skills. Please try again.',
      );
    }
  }

  // ============================================================
  // ADD OFFERED SKILL
  // ============================================================

  Future<void> addOfferedSkill({
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
          // ----------------------------------------------------
          // CURRENT LOCAL USER MUST EXIST
          // ----------------------------------------------------

          final List<Map<String, Object?>> userRows =
          await txn.query(
            'users',
            columns: <String>[
              'id',
            ],
            where: 'id = ?',
            whereArgs: <Object?>[
              cleanUserId,
            ],
            limit: 1,
          );

          if (userRows.length != 1) {
            throw const MySkillsRepositoryException(
              'Current user profile could not be found.',
            );
          }

          // ----------------------------------------------------
          // EXISTING CATALOG / CUSTOM SKILL
          // ----------------------------------------------------

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
            throw const MySkillsRepositoryException(
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
            // --------------------------------------------------
            // CREATE CUSTOM SKILL OWNED BY CURRENT USER
            // --------------------------------------------------

            skillId =
                _generateId(
                  'skill_custom',
                );

            final int insertedSkillRowId =
            await txn.insert(
              'skills',
              <String, Object?>{
                'id': skillId,
                'owner_user_id':
                cleanUserId,
                'title': cleanTitle,
                'category':
                cleanCategory,
                'level': cleanLevel,
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
                'prerequisite': '',
                'description':
                cleanDescription,
              },
              conflictAlgorithm:
              ConflictAlgorithm.abort,
            );

            if (insertedSkillRowId <= 0) {
              throw const MySkillsRepositoryException(
                'Could not create the new skill.',
              );
            }
          }

          // ----------------------------------------------------
          // PREVENT DUPLICATE OFFERED RELATIONSHIP
          // ----------------------------------------------------

          final List<Map<String, Object?>>
          existingRelationship =
          await txn.query(
            'user_skills',
            columns: <String>[
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
              'offered',
            ],
            limit: 1,
          );

          if (existingRelationship.isNotEmpty) {
            throw const MySkillsRepositoryException(
              'You already offer this skill.',
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
              'offered',
              'level':
              cleanLevel,
              'availability':
              cleanAvailability,
            },
            conflictAlgorithm:
            ConflictAlgorithm.abort,
          );

          if (insertedRelationshipRowId <= 0) {
            throw const MySkillsRepositoryException(
              'Could not add the skill to your profile.',
            );
          }
        },
      );

      await _refreshExploreAfterWrite();
    } on MySkillsRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const MySkillsRepositoryException(
        'Could not add the skill. Please try again.',
      );
    } catch (_) {
      throw const MySkillsRepositoryException(
        'Could not add the skill. Please try again.',
      );
    }
  }

  // ============================================================
  // UPDATE OFFERED SKILL
  // ============================================================

  Future<void> updateOfferedSkill({
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
            columns: <String>[
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
              'offered',
            ],
            limit: 1,
          );

          if (relationshipRows.isEmpty) {
            throw const MySkillsRepositoryException(
              'Skill relationship could not be found.',
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
            columns: <String>[
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

          if (skillRows.isEmpty) {
            throw const MySkillsRepositoryException(
              'Skill could not be found.',
            );
          }

          final Map<String, Object?> skillRow =
              skillRows.first;

          final String? ownerUserId =
          _readOptionalString(
            skillRow,
            'owner_user_id',
            'Skill owner',
          );

          final bool ownsMetadata =
              ownerUserId ==
                  cleanUserId;

          if (ownsMetadata) {
            // --------------------------------------------------
            // PREVENT CUSTOM SKILL NAME COLLISION
            // --------------------------------------------------

            final List<Map<String, Object?>>
            conflictingTitles =
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

            if (conflictingTitles.isNotEmpty) {
              throw const MySkillsRepositoryException(
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
              throw const MySkillsRepositoryException(
                'Could not update the skill details.',
              );
            }
          } else {
            // --------------------------------------------------
            // SHARED CATALOG METADATA IS READ-ONLY
            // --------------------------------------------------

            final String currentTitle =
            _requireRowString(
              skillRow,
              'title',
              'Skill title',
            );

            final String currentCategory =
            _requireRowString(
              skillRow,
              'category',
              'Skill category',
            );

            final String currentDescription =
            _requireRowString(
              skillRow,
              'description',
              'Skill description',
            );

            if (cleanTitle != currentTitle ||
                cleanCategory != currentCategory ||
                cleanDescription !=
                    currentDescription) {
              throw const MySkillsRepositoryException(
                'Shared skill details cannot be renamed or rewritten. '
                    'You can update your level and availability.',
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
              'offered',
            ],
          );

          if (updatedRelationshipRows != 1) {
            throw const MySkillsRepositoryException(
              'Could not update your skill profile.',
            );
          }
        },
      );

      await _refreshExploreAfterWrite();
    } on MySkillsRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const MySkillsRepositoryException(
        'Could not update the skill. Please try again.',
      );
    } catch (_) {
      throw const MySkillsRepositoryException(
        'Could not update the skill. Please try again.',
      );
    }
  }

  // ============================================================
  // DELETE OFFERED SKILL
  // ============================================================

  Future<void> deleteOfferedSkill({
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
            columns: <String>[
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
              'offered',
            ],
            limit: 1,
          );

          if (relationshipRows.isEmpty) {
            throw const MySkillsRepositoryException(
              'Skill relationship could not be found.',
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
            columns: <String>[
              'owner_user_id',
            ],
            where: 'id = ?',
            whereArgs: <Object?>[
              skillId,
            ],
            limit: 1,
          );

          if (skillRows.isEmpty) {
            throw const MySkillsRepositoryException(
              'Skill could not be found.',
            );
          }

          final String? ownerUserId =
          _readOptionalString(
            skillRows.first,
            'owner_user_id',
            'Skill owner',
          );

          final int deletedRelationshipRows =
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
              'offered',
            ],
          );

          if (deletedRelationshipRows != 1) {
            throw const MySkillsRepositoryException(
              'Could not remove the skill from your profile.',
            );
          }

          // ----------------------------------------------------
          // CLEAN UP UNUSED CUSTOM SKILL
          //
          // Only the current user's custom metadata is eligible
          // for cleanup, and only when no relationships anywhere
          // still reference it.
          // ----------------------------------------------------

          if (ownerUserId ==
              cleanUserId) {
            final int remainingLinks =
                Sqflite.firstIntValue(
                  await txn.rawQuery(
                    '''
                        SELECT COUNT(*)
                        FROM user_skills
                        WHERE skill_id = ?
                        ''',
                    <Object?>[
                      skillId,
                    ],
                  ),
                ) ??
                    0;

            if (remainingLinks < 0) {
              throw const MySkillsRepositoryException(
                'Could not verify remaining skill references.',
              );
            }

            if (remainingLinks == 0) {
              final int deletedSkillRows =
              await txn.delete(
                'skills',
                where: '''
                  id = ?
                  AND owner_user_id = ?
                ''',
                whereArgs: <Object?>[
                  skillId,
                  cleanUserId,
                ],
              );

              if (deletedSkillRows != 1) {
                throw const MySkillsRepositoryException(
                  'Could not remove the unused custom skill.',
                );
              }
            }
          }
        },
      );

      await _refreshExploreAfterWrite();
    } on MySkillsRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const MySkillsRepositoryException(
        'Could not delete the skill. Please try again.',
      );
    } catch (_) {
      throw const MySkillsRepositoryException(
        'Could not delete the skill. Please try again.',
      );
    }
  }

  // ============================================================
  // CURRENT LOCAL USER BOUNDARY
  // ============================================================

  String _requireCurrentLocalUser(
      String userId,
      ) {
    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    try {
      _currentUserService.requireCurrentUser(
        cleanUserId,
        message:
        'You can only modify skills for the active local user.',
      );
    } on CurrentUserServiceException catch (_) {
      throw const MySkillsRepositoryException(
        'You can only modify skills for the active local user.',
      );
    }

    return cleanUserId;
  }

  // ============================================================
  // REFRESH AFTER WRITE
  // ============================================================

  Future<void> _refreshExploreAfterWrite() async {
    try {
      await ExploreRepository.instance.refresh();
    } on ExploreRepositoryException catch (_) {
      throw const MySkillsRepositoryException(
        'Your change was saved, but the refreshed skill data could not be loaded.',
      );
    }
  }

  // ============================================================
  // ID GENERATION
  // ============================================================

  String _generateId(
      String prefix,
      ) {
    final int current =
        DateTime.now()
            .microsecondsSinceEpoch;

    if (current >
        _lastGeneratedIdValue) {
      _lastGeneratedIdValue =
          current;
    } else {
      _lastGeneratedIdValue++;
    }

    return '${prefix}_$_lastGeneratedIdValue';
  }

  // ============================================================
  // INPUT VALIDATION
  // ============================================================

  String _requireText(
      String value,
      String field,
      ) {
    final String clean =
    value.trim();

    if (clean.isEmpty) {
      throw MySkillsRepositoryException(
        '$field is required.',
      );
    }

    return clean;
  }

  void _validateLengths({
    required String title,
    required String description,
  }) {
    if (title.length > 80) {
      throw const MySkillsRepositoryException(
        'Skill name must be 80 characters or less.',
      );
    }

    if (description.length > 200) {
      throw const MySkillsRepositoryException(
        'Description must be 200 characters or less.',
      );
    }
  }

  String _validateLevel(
      String value,
      ) {
    final String clean =
    _requireText(
      value,
      'Experience level',
    );

    const Set<String> allowed =
    <String>{
      'Beginner',
      'Intermediate',
      'Advanced',
    };

    if (!allowed.contains(
      clean,
    )) {
      throw const MySkillsRepositoryException(
        'Invalid experience level.',
      );
    }

    return clean;
  }

  // ============================================================
  // DEFENSIVE DATABASE PARSING
  // ============================================================

  String _requireRowString(
      Map<String, Object?> row,
      String key,
      String label,
      ) {
    if (!row.containsKey(
      key,
    )) {
      throw MySkillsRepositoryException(
        '$label is missing.',
      );
    }

    final Object? value =
    row[key];

    if (value is! String) {
      throw MySkillsRepositoryException(
        '$label is invalid.',
      );
    }

    final String clean =
    value.trim();

    if (clean.isEmpty) {
      throw MySkillsRepositoryException(
        '$label is required.',
      );
    }

    return clean;
  }

  String? _readOptionalString(
      Map<String, Object?> row,
      String key,
      String label,
      ) {
    if (!row.containsKey(
      key,
    )) {
      throw MySkillsRepositoryException(
        '$label is missing.',
      );
    }

    final Object? value =
    row[key];

    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw MySkillsRepositoryException(
        '$label is invalid.',
      );
    }

    final String clean =
    value.trim();

    if (clean.isEmpty) {
      return null;
    }

    return clean;
  }

  // ============================================================
  // CATEGORY ICON
  // ============================================================

  IconData _iconForCategory(
      String category,
      ) {
    switch (category) {
      case 'Design & Creative':
        return Icons
            .design_services_outlined;

      case 'Photography':
        return Icons
            .camera_alt_outlined;

      case 'Video & Media':
        return Icons
            .movie_creation_outlined;

      case 'Technology':
        return Icons
            .code_rounded;

      case 'Music':
        return Icons
            .music_note_rounded;

      case 'Language':
        return Icons
            .translate_rounded;

      case 'Education':
        return Icons
            .school_outlined;

      case 'Lifestyle':
        return Icons
            .self_improvement_rounded;

      default:
        return Icons
            .lightbulb_outline_rounded;
    }
  }
}