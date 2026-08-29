import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

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
//
// Combines:
//
// Skill = catalog / skill information
// UserSkill = user's offered-skill relationship
// ownerUserId = who owns custom metadata
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

  // ============================================================
  // GET OFFERED SKILLS
  // ============================================================

  Future<List<ManagedSkill>> getOfferedSkills(
      String userId,
      ) async {
    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    await ExploreRepository.instance.refresh();

    final List<UserSkill> relationships =
    ExploreRepository.instance
        .getOfferedSkillsForUser(
      cleanUserId,
    );

    final Database db =
    await AppDatabase.instance.database;

    final List<ManagedSkill> results = [];

    for (final UserSkill relationship
    in relationships) {
      final Skill? skill =
      ExploreRepository.instance
          .findSkillById(
        relationship.skillId,
      );

      if (skill == null) {
        continue;
      }

      final List<Map<String, Object?>>
      skillRows = await db.query(
        'skills',
        columns: [
          'owner_user_id',
        ],
        where: 'id = ?',
        whereArgs: [
          skill.id,
        ],
        limit: 1,
      );

      String? ownerUserId;

      if (skillRows.isNotEmpty) {
        ownerUserId =
        skillRows.first[
        'owner_user_id'
        ] as String?;
      }

      results.add(
        ManagedSkill(
          skill: skill,
          userSkill: relationship,
          ownerUserId: ownerUserId,
        ),
      );
    }

    results.sort(
          (a, b) => a.skill.title
          .toLowerCase()
          .compareTo(
        b.skill.title
            .toLowerCase(),
      ),
    );

    return results;
  }

  // ============================================================
  // ADD OFFERED SKILL
  //
  // Existing catalog title:
  // attaches that skill to the user.
  //
  // New title:
  // creates a custom user-owned skill first.
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
    _requireText(
      userId,
      'User ID',
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

    if (cleanTitle.length > 80) {
      throw const MySkillsRepositoryException(
        'Skill name must be 80 characters or less.',
      );
    }

    if (cleanDescription.length > 200) {
      throw const MySkillsRepositoryException(
        'Description must be 200 characters or less.',
      );
    }

    final Database db =
    await AppDatabase.instance.database;

    await db.transaction(
          (txn) async {
        // ------------------------------------------------------
        // Make sure current user exists.
        // ------------------------------------------------------

        final List<Map<String, Object?>>
        userRows = await txn.query(
          'users',
          columns: [
            'id',
          ],
          where: 'id = ?',
          whereArgs: [
            cleanUserId,
          ],
          limit: 1,
        );

        if (userRows.isEmpty) {
          throw const MySkillsRepositoryException(
            'Current user profile could not be found.',
          );
        }

        // ------------------------------------------------------
        // Look for existing skill title.
        // ------------------------------------------------------

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
          LIMIT 1
          ''',
          [
            cleanTitle,
          ],
        );

        late final String skillId;

        if (existingSkills.isNotEmpty) {
          skillId =
          existingSkills.first[
          'id'
          ] as String;
        } else {
          // ----------------------------------------------------
          // New custom skill owned by current user.
          // ----------------------------------------------------

          skillId =
          'skill_custom_${DateTime.now().microsecondsSinceEpoch}';

          await txn.insert(
            'skills',
            {
              'id': skillId,
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
          );
        }

        // ------------------------------------------------------
        // Prevent duplicate offered relationship.
        // ------------------------------------------------------

        final List<Map<String, Object?>>
        existingRelationship =
        await txn.query(
          'user_skills',
          columns: [
            'id',
          ],
          where: '''
            user_id = ?
            AND skill_id = ?
            AND type = ?
          ''',
          whereArgs: [
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
            'user_skill_${DateTime.now().microsecondsSinceEpoch}';

        await txn.insert(
          'user_skills',
          {
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
        );
      },
    );

    await ExploreRepository.instance.refresh();
  }

  // ============================================================
  // UPDATE OFFERED SKILL
  //
  // Shared catalog skill:
  // only level + availability can change.
  //
  // Custom user-owned skill:
  // metadata can also change.
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
    _requireText(
      userId,
      'User ID',
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

    if (cleanTitle.length > 80) {
      throw const MySkillsRepositoryException(
        'Skill name must be 80 characters or less.',
      );
    }

    if (cleanDescription.length > 200) {
      throw const MySkillsRepositoryException(
        'Description must be 200 characters or less.',
      );
    }

    final Database db =
    await AppDatabase.instance.database;

    await db.transaction(
          (txn) async {
        final List<Map<String, Object?>>
        relationshipRows =
        await txn.query(
          'user_skills',
          where: '''
            id = ?
            AND user_id = ?
            AND type = ?
          ''',
          whereArgs: [
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
        relationshipRows.first[
        'skill_id'
        ] as String;

        final List<Map<String, Object?>>
        skillRows = await txn.query(
          'skills',
          where: 'id = ?',
          whereArgs: [
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
        skillRow[
        'owner_user_id'
        ] as String?;

        final bool ownsMetadata =
            ownerUserId ==
                cleanUserId;

        if (ownsMetadata) {
          // ----------------------------------------------------
          // Prevent custom skill from being renamed to another
          // existing skill title.
          // ----------------------------------------------------

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
            [
              cleanTitle,
              skillId,
            ],
          );

          if (conflictingTitles.isNotEmpty) {
            throw const MySkillsRepositoryException(
              'Another skill already uses that name.',
            );
          }

          await txn.update(
            'skills',
            {
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
            where: 'id = ?',
            whereArgs: [
              skillId,
            ],
          );
        } else {
          // ----------------------------------------------------
          // Shared catalog metadata cannot be modified by one
          // user's profile.
          // ----------------------------------------------------

          final String currentTitle =
          skillRow[
          'title'
          ] as String;

          final String currentCategory =
          skillRow[
          'category'
          ] as String;

          final String currentDescription =
          skillRow[
          'description'
          ] as String;

          if (cleanTitle !=
              currentTitle ||
              cleanCategory !=
                  currentCategory ||
              cleanDescription !=
                  currentDescription) {
            throw const MySkillsRepositoryException(
              'Shared skill details cannot be renamed or rewritten. '
                  'You can update your level and availability.',
            );
          }
        }

        await txn.update(
          'user_skills',
          {
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
          whereArgs: [
            cleanUserSkillId,
            cleanUserId,
            'offered',
          ],
        );
      },
    );

    await ExploreRepository.instance.refresh();
  }

  // ============================================================
  // DELETE OFFERED SKILL
  //
  // Always removes the user's offered relationship.
  //
  // If this is a custom skill owned by the user and no remaining
  // relationships reference it, the custom skill is also removed.
  // ============================================================

  Future<void> deleteOfferedSkill({
    required String userId,
    required String userSkillId,
  }) async {
    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    final String cleanUserSkillId =
    _requireText(
      userSkillId,
      'User skill ID',
    );

    final Database db =
    await AppDatabase.instance.database;

    await db.transaction(
          (txn) async {
        final List<Map<String, Object?>>
        relationshipRows =
        await txn.query(
          'user_skills',
          where: '''
            id = ?
            AND user_id = ?
            AND type = ?
          ''',
          whereArgs: [
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
        relationshipRows.first[
        'skill_id'
        ] as String;

        final List<Map<String, Object?>>
        skillRows = await txn.query(
          'skills',
          columns: [
            'owner_user_id',
          ],
          where: 'id = ?',
          whereArgs: [
            skillId,
          ],
          limit: 1,
        );

        final String? ownerUserId =
        skillRows.isEmpty
            ? null
            : skillRows.first[
        'owner_user_id'
        ] as String?;

        await txn.delete(
          'user_skills',
          where: '''
            id = ?
            AND user_id = ?
            AND type = ?
          ''',
          whereArgs: [
            cleanUserSkillId,
            cleanUserId,
            'offered',
          ],
        );

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
                  [
                    skillId,
                  ],
                ),
              ) ??
                  0;

          if (remainingLinks == 0) {
            await txn.delete(
              'skills',
              where: 'id = ?',
              whereArgs: [
                skillId,
              ],
            );
          }
        }
      },
    );

    await ExploreRepository.instance.refresh();
  }

  // ============================================================
  // VALIDATION
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

  String _validateLevel(
      String value,
      ) {
    final String clean =
    _requireText(
      value,
      'Experience level',
    );

    const Set<String> allowed = {
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
  // CATEGORY ICON
  // ============================================================

  IconData _iconForCategory(
      String category,
      ) {
    switch (category) {
      case 'Design & Creative':
        return Icons.design_services_outlined;

      case 'Photography':
        return Icons.camera_alt_outlined;

      case 'Video & Media':
        return Icons.movie_creation_outlined;

      case 'Technology':
        return Icons.code_rounded;

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