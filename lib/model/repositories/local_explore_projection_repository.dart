import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../services/current_user_service.dart';
import '../database/app_database.dart';
import 'firestore_explore_repository.dart';

class LocalExploreProjectionException implements Exception {
  final String message;

  const LocalExploreProjectionException(this.message);

  @override
  String toString() => message;
}

class LocalExploreProjectionRepository {
  LocalExploreProjectionRepository({
    AppDatabase? database,
    CurrentUserService? currentUserService,
  }) : _database = database ?? AppDatabase.instance,
       _currentUserService = currentUserService ?? CurrentUserService.instance;

  static final LocalExploreProjectionRepository instance =
      LocalExploreProjectionRepository();

  static const String _legacyLocalUid = 'user_joice_local';

  final AppDatabase _database;
  final CurrentUserService _currentUserService;

  Future<void> project({
    required String viewerUid,
    required FirestoreExploreSnapshot snapshot,
  }) async {
    final ActiveUserSession session = _captureViewerSession(viewerUid);
    if (snapshot.source == FirestoreExploreSource.unavailable) {
      _requireSameSession(session);
      return;
    }

    _validateSnapshot(session.uid, snapshot);
    _requireSameSession(session);

    try {
      final Database db = await _database.database;
      _requireSameSession(session);

      await db.transaction((Transaction transaction) async {
        _requireSameSession(session);
        await _requireViewerRow(transaction, session);
        _requireSameSession(session);

        for (final FirestoreExploreUserRecord user in snapshot.users) {
          await _projectRemoteUser(transaction, session, user);
          _requireSameSession(session);
        }

        final Map<String, String> effectiveLocalSkillIds = <String, String>{};
        for (final FirestoreExploreSkillRecord skill in snapshot.skills) {
          final String localSkillId = await _projectCatalogSkill(
            transaction,
            session,
            skill,
          );
          _requireSameSession(session);
          effectiveLocalSkillIds[skill.skillId] = localSkillId;
        }

        final Map<String, Set<String>> expectedRelationshipIdsByUser =
            _validateEffectiveRelationshipTuples(
              session.uid,
              snapshot,
              effectiveLocalSkillIds,
            );

        for (final FirestoreExploreSkillLinkRecord link
            in snapshot.skillLinks) {
          final String? effectiveLocalSkillId =
              effectiveLocalSkillIds[link.skillId];
          if (effectiveLocalSkillId == null) {
            throw const LocalExploreProjectionException(
              'A remote Explore relationship has no local catalog mapping.',
            );
          }
          await _projectRemoteRelationship(
            transaction,
            session,
            link,
            effectiveLocalSkillId,
            expectedRelationshipIdsByUser[link.userUid]!,
          );
          _requireSameSession(session);
        }

        if (snapshot.source == FirestoreExploreSource.server) {
          for (final FirestoreExploreUserRecord user in snapshot.users) {
            await _removeStaleRemoteRelationships(
              transaction,
              session,
              user.uid,
              expectedRelationshipIdsByUser[user.uid]!,
            );
            _requireSameSession(session);
          }
        }

        await _updateManifest(transaction, session, snapshot);
        _requireSameSession(session);
      });

      _requireSameSession(session);
    } on LocalExploreProjectionException {
      rethrow;
    } on DatabaseException {
      throw const LocalExploreProjectionException(
        'Remote Explore data could not be saved to the local cache.',
      );
    } catch (_) {
      throw const LocalExploreProjectionException(
        'Remote Explore data could not be saved to the local cache.',
      );
    }
  }

  void _validateSnapshot(String viewerUid, FirestoreExploreSnapshot snapshot) {
    final Set<String> candidateUids = <String>{};
    for (final FirestoreExploreUserRecord user in snapshot.users) {
      final String uid = _requireRemoteUid(user.uid, 'Remote candidate UID');
      if (uid == viewerUid || !candidateUids.add(uid)) {
        throw const LocalExploreProjectionException(
          'Remote Explore candidate identity is invalid.',
        );
      }
      if (!user.profileCompleted ||
          user.name.trim().isEmpty ||
          user.initials.trim().isEmpty ||
          user.city.trim().isEmpty ||
          user.bio.trim().isEmpty ||
          user.memberSince.trim().isEmpty ||
          user.availability.trim().isEmpty ||
          user.language.trim().isEmpty ||
          user.preferredMode.trim().isEmpty ||
          user.teachingStyle.trim().isEmpty ||
          user.rating != 0 ||
          user.reviewCount != 0 ||
          user.completedSwaps != 0 ||
          user.responseRate != 0 ||
          user.emailVerified ||
          user.profileImagePath != null) {
        throw const LocalExploreProjectionException(
          'Remote Explore profile compatibility data is invalid.',
        );
      }
    }

    final Set<String> skillIds = <String>{};
    final Map<String, String> skillIdsByNormalizedTitle = <String, String>{};
    for (final FirestoreExploreSkillRecord skill in snapshot.skills) {
      final String skillId = _requireIdentity(skill.skillId, 'Remote skill ID');
      if (!skillIds.add(skillId)) {
        throw const LocalExploreProjectionException(
          'Remote Explore contains duplicate catalog skills.',
        );
      }
      final String normalizedTitle = _normalizeTitle(skill.title);
      if (normalizedTitle.isEmpty ||
          skill.titleKey != normalizedTitle ||
          skill.category.trim().isEmpty ||
          skill.level.trim().isEmpty ||
          skill.iconCodePoint <= 0 ||
          skill.sessionLength.trim().isEmpty ||
          skill.mode.trim().isEmpty ||
          skill.language.trim().isEmpty ||
          skill.description.trim().isEmpty ||
          skill.learnings.any((String item) => item.trim().isEmpty)) {
        throw const LocalExploreProjectionException(
          'Remote Explore catalog data is invalid.',
        );
      }
      final String? previousSkillId =
          skillIdsByNormalizedTitle[normalizedTitle];
      if (previousSkillId != null && previousSkillId != skillId) {
        throw const LocalExploreProjectionException(
          'Remote Explore contains ambiguous normalized skill titles.',
        );
      }
      skillIdsByNormalizedTitle[normalizedTitle] = skillId;
      final String? ownerUid = skill.ownerUid;
      if (ownerUid != null) {
        _requireRemoteUid(ownerUid, 'Remote skill owner UID');
      }
    }

    final Map<String, Set<String>> relationshipIdsByUser =
        <String, Set<String>>{};
    final Map<String, Set<String>> relationshipKeysByUser =
        <String, Set<String>>{};
    final Set<String> referencedSkillIds = <String>{};
    for (final FirestoreExploreSkillLinkRecord link in snapshot.skillLinks) {
      final String userUid = _requireRemoteUid(
        link.userUid,
        'Remote relationship user UID',
      );
      if (!candidateUids.contains(userUid) || userUid == viewerUid) {
        throw const LocalExploreProjectionException(
          'Remote Explore relationship ownership is invalid.',
        );
      }
      final String relationshipId = _requireIdentity(
        link.relationshipId,
        'Remote relationship ID',
      );
      final String skillId = _requireIdentity(
        link.skillId,
        'Remote relationship skill ID',
      );
      if (!skillIds.contains(skillId) ||
          link.level.trim().isEmpty ||
          link.availability.trim().isEmpty) {
        throw const LocalExploreProjectionException(
          'Remote Explore relationship data is invalid.',
        );
      }
      final Set<String> relationshipIds = relationshipIdsByUser.putIfAbsent(
        userUid,
        () => <String>{},
      );
      final Set<String> relationshipKeys = relationshipKeysByUser.putIfAbsent(
        userUid,
        () => <String>{},
      );
      if (!relationshipIds.add(relationshipId) ||
          !relationshipKeys.add('$skillId:${link.type.name}')) {
        throw const LocalExploreProjectionException(
          'Remote Explore contains duplicate skill relationships.',
        );
      }
      referencedSkillIds.add(skillId);
    }

    if (referencedSkillIds.length != skillIds.length ||
        !referencedSkillIds.containsAll(skillIds)) {
      throw const LocalExploreProjectionException(
        'Remote Explore contains unreferenced catalog data.',
      );
    }
  }

  Future<void> _requireViewerRow(
    Transaction transaction,
    ActiveUserSession session,
  ) async {
    final List<Map<String, Object?>> rows = await transaction.query(
      'users',
      columns: <String>['id'],
      where: 'id = ? AND id != ?',
      whereArgs: <Object?>[session.uid, _legacyLocalUid],
      limit: 2,
    );
    _requireSameSession(session);
    if (rows.length != 1) {
      throw const LocalExploreProjectionException(
        'The active viewer profile is not available in the local cache.',
      );
    }
  }

  Future<void> _projectRemoteUser(
    Transaction transaction,
    ActiveUserSession session,
    FirestoreExploreUserRecord user,
  ) async {
    final String uid = _requireRemoteUid(user.uid, 'Remote candidate UID');
    if (uid == session.uid) {
      throw const LocalExploreProjectionException(
        'The active viewer cannot be projected as a remote candidate.',
      );
    }
    final List<Map<String, Object?>> existing = await transaction.query(
      'users',
      columns: <String>['id'],
      where: 'id = ? AND id != ?',
      whereArgs: <Object?>[uid, _legacyLocalUid],
      limit: 2,
    );
    _requireSameSession(session);
    if (existing.length > 1) {
      throw const LocalExploreProjectionException(
        'A remote candidate is not unique in the local cache.',
      );
    }

    final Map<String, Object?> remoteProfileValues = <String, Object?>{
      'id': uid,
      'name': user.name.trim(),
      'initials': user.initials.trim(),
      'city': user.city.trim(),
      'bio': user.bio.trim(),
      'member_since': user.memberSince.trim(),
      'availability': user.availability.trim(),
      'language': user.language.trim(),
      'preferred_mode': user.preferredMode.trim(),
      'teaching_style': user.teachingStyle.trim(),
      'profile_completed': 1,
    };
    _requireSameSession(session);
    if (existing.isEmpty) {
      await transaction.insert(
        'users',
        <String, Object?>{
          ...remoteProfileValues,
          'rating': 0.0,
          'review_count': 0,
          'completed_swaps': 0,
          'response_rate': 0,
          'email_verified': 0,
          'profile_image_path': null,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } else {
      final int changed = await transaction.update(
        'users',
        remoteProfileValues,
        where: 'id = ? AND id != ?',
        whereArgs: <Object?>[uid, _legacyLocalUid],
      );
      if (changed != 1) {
        throw const LocalExploreProjectionException(
          'A remote candidate could not be updated in the local cache.',
        );
      }
    }
    _requireSameSession(session);
  }

  Future<String> _projectCatalogSkill(
    Transaction transaction,
    ActiveUserSession session,
    FirestoreExploreSkillRecord skill,
  ) async {
    final String skillId = _requireIdentity(skill.skillId, 'Remote skill ID');
    final String? ownerUid = skill.ownerUid;
    if (ownerUid != null) {
      _requireRemoteUid(ownerUid, 'Remote skill owner UID');
    }

    final List<Map<String, Object?>> existing = await transaction.query(
      'skills',
      columns: <String>['id', 'owner_user_id'],
      where: 'id = ?',
      whereArgs: <Object?>[skillId],
      limit: 2,
    );
    _requireSameSession(session);
    final List<Map<String, Object?>> normalizedTitleMatches = await transaction
        .rawQuery(
          '''
          SELECT id
          FROM skills
          WHERE lower(trim(title)) = lower(trim(?))
          ORDER BY id
          LIMIT 2
          ''',
          <Object?>[skill.title],
        );
    _requireSameSession(session);
    if (existing.length > 1 || normalizedTitleMatches.length > 1) {
      throw const LocalExploreProjectionException(
        'Multiple local catalog skills use the same remote identity or title.',
      );
    }

    if (existing.isNotEmpty) {
      if (normalizedTitleMatches.isNotEmpty &&
          _requiredString(normalizedTitleMatches.single, 'id', 'Skill ID') !=
              skillId) {
        throw const LocalExploreProjectionException(
          'A remote skill ID conflicts with an existing local catalog title.',
        );
      }
      final String? existingOwner = _optionalString(
        existing.single,
        'owner_user_id',
        'Skill owner',
      );
      if (existingOwner == _legacyLocalUid || existingOwner != ownerUid) {
        throw const LocalExploreProjectionException(
          'Remote Explore cannot reassign local catalog ownership.',
        );
      }
    } else if (normalizedTitleMatches.isNotEmpty) {
      return _requiredString(normalizedTitleMatches.single, 'id', 'Skill ID');
    }

    if (ownerUid != null) {
      final List<Map<String, Object?>> ownerRows = await transaction.query(
        'users',
        columns: <String>['id'],
        where: 'id = ? AND id != ?',
        whereArgs: <Object?>[ownerUid, _legacyLocalUid],
        limit: 2,
      );
      _requireSameSession(session);
      if (ownerRows.length != 1) {
        throw const LocalExploreProjectionException(
          'A remote custom skill owner is not available in the local cache.',
        );
      }
    }

    final Map<String, Object?> values = <String, Object?>{
      'id': skillId,
      'owner_user_id': ownerUid,
      'title': skill.title.trim(),
      'category': skill.category.trim(),
      'level': skill.level.trim(),
      'icon_code_point': skill.iconCodePoint,
      'session_length': skill.sessionLength.trim(),
      'mode': skill.mode.trim(),
      'language': skill.language.trim(),
      'prerequisite': skill.prerequisite.trim(),
      'description': skill.description.trim(),
    };
    _requireSameSession(session);
    if (existing.isEmpty) {
      await transaction.insert(
        'skills',
        values,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } else {
      final int changed = await transaction.update(
        'skills',
        values,
        where: 'id = ?',
        whereArgs: <Object?>[skillId],
      );
      if (changed != 1) {
        throw const LocalExploreProjectionException(
          'A remote catalog skill could not be updated locally.',
        );
      }
    }
    _requireSameSession(session);

    await transaction.delete(
      'skill_learnings',
      where: 'skill_id = ?',
      whereArgs: <Object?>[skillId],
    );
    _requireSameSession(session);
    for (int index = 0; index < skill.learnings.length; index++) {
      await transaction.insert('skill_learnings', <String, Object?>{
        'skill_id': skillId,
        'position': index,
        'text': skill.learnings[index].trim(),
      }, conflictAlgorithm: ConflictAlgorithm.abort);
      _requireSameSession(session);
    }
    return skillId;
  }

  Map<String, Set<String>> _validateEffectiveRelationshipTuples(
    String viewerUid,
    FirestoreExploreSnapshot snapshot,
    Map<String, String> effectiveLocalSkillIds,
  ) {
    final Map<String, Set<String>> tupleKeysByUser = <String, Set<String>>{};
    final Map<String, Set<String>> expectedIdsByUser = <String, Set<String>>{
      for (final FirestoreExploreUserRecord user in snapshot.users)
        user.uid: <String>{},
    };
    final Set<String> allExpectedIds = <String>{};
    for (final FirestoreExploreSkillLinkRecord link in snapshot.skillLinks) {
      if (link.userUid == viewerUid ||
          !expectedIdsByUser.containsKey(link.userUid)) {
        throw const LocalExploreProjectionException(
          'Remote Explore relationship ownership is invalid.',
        );
      }
      final String? effectiveLocalSkillId =
          effectiveLocalSkillIds[link.skillId];
      if (effectiveLocalSkillId == null) {
        throw const LocalExploreProjectionException(
          'A remote relationship could not resolve its local skill.',
        );
      }
      final Set<String> tupleKeys = tupleKeysByUser.putIfAbsent(
        link.userUid,
        () => <String>{},
      );
      if (!tupleKeys.add('$effectiveLocalSkillId:${link.type.name}')) {
        throw const LocalExploreProjectionException(
          'Remote relationships collapse to the same local skill and type.',
        );
      }
      final String localRelationshipId = _localRelationshipId(
        link.userUid,
        link.relationshipId,
      );
      if (!allExpectedIds.add(localRelationshipId)) {
        throw const LocalExploreProjectionException(
          'Remote relationships produce duplicate local identities.',
        );
      }
      expectedIdsByUser[link.userUid]!.add(localRelationshipId);
    }
    return expectedIdsByUser;
  }

  Future<void> _projectRemoteRelationship(
    Transaction transaction,
    ActiveUserSession session,
    FirestoreExploreSkillLinkRecord link,
    String effectiveLocalSkillId,
    Set<String> expectedRelationshipIds,
  ) async {
    final String localRelationshipId = _localRelationshipId(
      link.userUid,
      link.relationshipId,
    );
    final List<Map<String, Object?>> existingById = await transaction.query(
      'user_skills',
      columns: <String>['id', 'user_id', 'skill_id', 'type'],
      where: 'id = ?',
      whereArgs: <Object?>[localRelationshipId],
      limit: 2,
    );
    _requireSameSession(session);
    if (existingById.length > 1) {
      throw const LocalExploreProjectionException(
        'A projected relationship identity is not unique.',
      );
    }
    if (existingById.isNotEmpty) {
      final Map<String, Object?> row = existingById.single;
      if (_requiredString(row, 'user_id', 'User ID') != link.userUid ||
          _requiredString(row, 'skill_id', 'Skill ID') !=
              effectiveLocalSkillId ||
          _requiredString(row, 'type', 'Relationship type') != link.type.name) {
        throw const LocalExploreProjectionException(
          'A projected relationship ID belongs to incompatible local data.',
        );
      }
    }

    final List<Map<String, Object?>> tupleRows = await transaction.query(
      'user_skills',
      columns: <String>['id'],
      where: 'user_id = ? AND skill_id = ? AND type = ? AND id != ?',
      whereArgs: <Object?>[
        link.userUid,
        effectiveLocalSkillId,
        link.type.name,
        localRelationshipId,
      ],
      limit: 2,
    );
    _requireSameSession(session);
    if (tupleRows.length > 1 ||
        (existingById.isNotEmpty && tupleRows.isNotEmpty)) {
      throw const LocalExploreProjectionException(
        'Local Explore relationships violate the unique skill/type mapping.',
      );
    }

    bool relationshipExists = existingById.isNotEmpty;
    if (tupleRows.isNotEmpty) {
      final String previousId = _requiredString(
        tupleRows.single,
        'id',
        'Relationship ID',
      );
      if (expectedRelationshipIds.contains(previousId)) {
        throw const LocalExploreProjectionException(
          'A local relationship identity conflicts with remote Explore data.',
        );
      }
      final int changed = await transaction.update(
        'user_skills',
        <String, Object?>{
          'id': localRelationshipId,
          'level': link.level.trim(),
          'availability': link.availability.trim(),
        },
        where: 'id = ? AND user_id = ? AND skill_id = ? AND type = ?',
        whereArgs: <Object?>[
          previousId,
          link.userUid,
          effectiveLocalSkillId,
          link.type.name,
        ],
      );
      _requireSameSession(session);
      if (changed != 1) {
        throw const LocalExploreProjectionException(
          'An existing remote relationship could not be reconciled locally.',
        );
      }
      relationshipExists = true;
    }

    final Map<String, Object?> values = <String, Object?>{
      'id': localRelationshipId,
      'user_id': link.userUid,
      'skill_id': effectiveLocalSkillId,
      'type': link.type.name,
      'level': link.level.trim(),
      'availability': link.availability.trim(),
    };
    _requireSameSession(session);
    if (!relationshipExists) {
      await transaction.insert(
        'user_skills',
        values,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } else {
      final int changed = await transaction.update(
        'user_skills',
        values,
        where: 'id = ? AND user_id = ?',
        whereArgs: <Object?>[localRelationshipId, link.userUid],
      );
      if (changed != 1) {
        throw const LocalExploreProjectionException(
          'A remote relationship could not be updated locally.',
        );
      }
    }
    _requireSameSession(session);
  }

  Future<void> _removeStaleRemoteRelationships(
    Transaction transaction,
    ActiveUserSession session,
    String candidateUid,
    Set<String> expectedRelationshipIds,
  ) async {
    final String remotePrefix = _localRelationshipPrefix(candidateUid);
    final List<Map<String, Object?>> rows = await transaction.query(
      'user_skills',
      columns: <String>['id'],
      where: 'user_id = ?',
      whereArgs: <Object?>[candidateUid],
    );
    _requireSameSession(session);
    for (final Map<String, Object?> row in rows) {
      final String relationshipId = _requiredString(
        row,
        'id',
        'Relationship ID',
      );
      if (!relationshipId.startsWith(remotePrefix) ||
          expectedRelationshipIds.contains(relationshipId)) {
        continue;
      }
      final int deleted = await transaction.delete(
        'user_skills',
        where: 'id = ? AND user_id = ?',
        whereArgs: <Object?>[relationshipId, candidateUid],
      );
      _requireSameSession(session);
      if (deleted != 1) {
        throw const LocalExploreProjectionException(
          'A stale remote relationship could not be reconciled locally.',
        );
      }
    }
  }

  Future<void> _updateManifest(
    Transaction transaction,
    ActiveUserSession session,
    FirestoreExploreSnapshot snapshot,
  ) async {
    _requireSameSession(session);
    if (snapshot.source == FirestoreExploreSource.server) {
      await transaction.delete(
        'explore_remote_users',
        where: 'viewer_uid = ?',
        whereArgs: <Object?>[session.uid],
      );
      _requireSameSession(session);
    }

    final int projectedAt = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (final FirestoreExploreUserRecord user in snapshot.users) {
      final Map<String, Object?> values = <String, Object?>{
        'viewer_uid': session.uid,
        'candidate_uid': user.uid,
        'projected_at': projectedAt,
      };
      final int changed = await transaction.update(
        'explore_remote_users',
        values,
        where: 'viewer_uid = ? AND candidate_uid = ?',
        whereArgs: <Object?>[session.uid, user.uid],
      );
      _requireSameSession(session);
      if (changed == 0) {
        await transaction.insert(
          'explore_remote_users',
          values,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        _requireSameSession(session);
      } else if (changed != 1) {
        throw const LocalExploreProjectionException(
          'A remote Explore manifest entry is not unique.',
        );
      }
    }
  }

  ActiveUserSession _captureViewerSession(String viewerUid) {
    final String cleanUid = _requireRemoteUid(viewerUid, 'Active viewer UID');
    try {
      final ActiveUserSession session = _currentUserService.captureSession();
      if (session.uid != cleanUid) {
        throw const LocalExploreProjectionException(
          'The local Explore projection is limited to the active viewer.',
        );
      }
      return session;
    } on LocalExploreProjectionException {
      rethrow;
    } on CurrentUserServiceException catch (error) {
      throw LocalExploreProjectionException(error.message);
    }
  }

  void _requireSameSession(ActiveUserSession session) {
    try {
      _currentUserService.requireSameSession(session);
    } on CurrentUserServiceException catch (error) {
      throw LocalExploreProjectionException(error.message);
    }
  }

  String _requireRemoteUid(String value, String label) {
    final String uid = _requireIdentity(value, label);
    if (uid == _legacyLocalUid) {
      throw LocalExploreProjectionException('$label is invalid.');
    }
    return uid;
  }

  String _requireIdentity(String value, String label) {
    final String clean = value.trim();
    if (clean.isEmpty || clean != value) {
      throw LocalExploreProjectionException('$label is invalid.');
    }
    return clean;
  }

  String _localRelationshipId(String userUid, String relationshipId) {
    return '${_localRelationshipPrefix(userUid)}${_encodeIdentity(relationshipId)}';
  }

  String _localRelationshipPrefix(String userUid) {
    final String encodedUid = _encodeIdentity(userUid);
    return 'remote_explore_v1_${encodedUid.length}_${encodedUid}_';
  }

  String _encodeIdentity(String value) {
    return base64Url.encode(utf8.encode(value)).replaceAll('=', '');
  }

  String _normalizeTitle(String title) => title.trim().toLowerCase();

  String _requiredString(Map<String, Object?> row, String key, String label) {
    final Object? value = row[key];
    if (value is! String || value.trim().isEmpty) {
      throw LocalExploreProjectionException('$label is invalid.');
    }
    return value.trim();
  }

  String? _optionalString(Map<String, Object?> row, String key, String label) {
    if (!row.containsKey(key)) {
      throw LocalExploreProjectionException('$label is missing.');
    }
    final Object? value = row[key];
    if (value == null) return null;
    if (value is! String) {
      throw LocalExploreProjectionException('$label is invalid.');
    }
    final String clean = value.trim();
    return clean.isEmpty ? null : clean;
  }
}
