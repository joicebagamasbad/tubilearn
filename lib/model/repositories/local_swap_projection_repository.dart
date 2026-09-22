import 'package:sqflite/sqflite.dart';

import '../../services/current_user_service.dart';
import '../database/app_database.dart';
import 'firestore_swap_repository.dart';

class LocalSwapProjectionException implements Exception {
  final String message;

  const LocalSwapProjectionException(this.message);

  @override
  String toString() => message;
}

class LocalSwapProjectionRepository {
  LocalSwapProjectionRepository({
    AppDatabase? database,
    CurrentUserService? currentUserService,
  }) : _database = database ?? AppDatabase.instance,
       _currentUserService = currentUserService ?? CurrentUserService.instance;

  static final LocalSwapProjectionRepository instance =
      LocalSwapProjectionRepository();

  static const String _legacyLocalUid = 'user_joice_local';

  // Sourced from the app's confirmed six-state SwapRequestStatus enum.
  // This repository stays decoupled from that enum (consistent with
  // FirestoreSwapRepository's own decoupling) and compares raw strings.
  static const Set<String> _activeStatuses = <String>{
    'pending',
    'accepted',
    'scheduled',
  };
  static const Set<String> _terminalStatuses = <String>{
    'declined',
    'completed',
    'cancelled',
  };

  final AppDatabase _database;
  final CurrentUserService _currentUserService;

  Future<void> project({
    required String viewerUid,
    required FirestoreSwapSnapshot snapshot,
  }) async {
    final ActiveUserSession session = _captureViewerSession(viewerUid);
    if (snapshot.source == FirestoreSwapSource.unavailable) {
      _requireSameSession(session);
      return;
    }

    try {
      final Database db = await _database.database;
      _requireSameSession(session);

      await db.transaction((Transaction transaction) async {
        _requireSameSession(session);

        for (final FirestoreSwapRequestRecord record in snapshot.records) {
          await _projectRecord(transaction, session, record);
          _requireSameSession(session);
        }
      });

      _requireSameSession(session);
    } on LocalSwapProjectionException {
      rethrow;
    } on DatabaseException {
      throw const LocalSwapProjectionException(
        'Cloud swap requests could not be saved to the local cache.',
      );
    } catch (_) {
      throw const LocalSwapProjectionException(
        'Cloud swap requests could not be saved to the local cache.',
      );
    }
  }

  Future<void> _projectRecord(
    Transaction transaction,
    ActiveUserSession session,
    FirestoreSwapRequestRecord record,
  ) async {
    final String status = _requireStatus(record.status);
    final bool isActive = _activeStatuses.contains(status);

    final ({String? localId, bool unresolved}) learnResolution =
        await _resolveSkillAlias(
          transaction,
          record.skillToLearnId,
          record.skillToLearn,
        );
    _requireSameSession(session);
    final ({String? localId, bool unresolved}) offerResolution =
        await _resolveSkillAlias(
          transaction,
          record.skillToOfferId,
          record.skillToOffer,
        );
    _requireSameSession(session);

    if (isActive &&
        (learnResolution.unresolved || offerResolution.unresolved)) {
      // Deliberate skip, not a bug: an active swap whose skill identity
      // cannot be resolved at all (zero local matches, as opposed to the
      // ambiguous multiple-matches case, which throws above) is excluded
      // from local projection entirely rather than written with a
      // dangling/null skill reference.
      return;
    }

    final Map<String, Object?> values = <String, Object?>{
      'id': record.id,
      'requester_user_id': record.requesterUserId,
      'provider_user_id': record.providerUserId,
      'skill_to_learn_id': learnResolution.localId,
      'skill_to_offer_id': offerResolution.localId,
      'provider_name': record.providerName,
      'provider_initials': record.providerInitials,
      'provider_city': record.providerCity,
      'skill_to_learn': record.skillToLearn,
      'skill_to_offer': record.skillToOffer,
      'proposed_at': record.proposedAt.toUtc().millisecondsSinceEpoch,
      'mode': record.mode,
      'meeting_details': record.meetingDetails,
      'note': record.note,
      'status': status,
      'created_at': record.createdAt.toUtc().millisecondsSinceEpoch,
      'updated_at': record.updatedAt.toUtc().millisecondsSinceEpoch,
    };

    final List<Map<String, Object?>> existing = await transaction.query(
      'swap_requests',
      columns: <String>['id'],
      where: 'id = ?',
      whereArgs: <Object?>[record.id],
      limit: 2,
    );
    _requireSameSession(session);
    if (existing.length > 1) {
      throw const LocalSwapProjectionException(
        'A projected swap request identity is not unique locally.',
      );
    }

    if (existing.isEmpty) {
      await transaction.insert(
        'swap_requests',
        values,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } else {
      final int changed = await transaction.update(
        'swap_requests',
        values,
        where: 'id = ?',
        whereArgs: <Object?>[record.id],
      );
      if (changed != 1) {
        throw const LocalSwapProjectionException(
          'A cloud swap request could not be updated locally.',
        );
      }
    }
  }

  /// Resolves [remoteSkillId] (paired with its denormalized [remoteTitle])
  /// against the local `skills` table using the same three-branch alias
  /// logic as LocalExploreProjectionRepository._projectCatalogSkill: an
  /// exact local ID match is used as-is; failing that, exactly one local
  /// skill sharing the same normalized title is reused as an alias; more
  /// than one match on either query is a fatal ambiguity. A null
  /// [remoteSkillId] is "no skill to resolve" and is propagated forward
  /// untouched — not an error, not an ambiguity, not a failed resolution.
  Future<({String? localId, bool unresolved})> _resolveSkillAlias(
    Transaction transaction,
    String? remoteSkillId,
    String remoteTitle,
  ) async {
    final String? cleanSkillId = remoteSkillId?.trim();
    if (cleanSkillId == null || cleanSkillId.isEmpty) {
      return (localId: null, unresolved: false);
    }

    final List<Map<String, Object?>> existing = await transaction.query(
      'skills',
      columns: <String>['id'],
      where: 'id = ?',
      whereArgs: <Object?>[cleanSkillId],
      limit: 2,
    );
    final List<Map<String, Object?>> normalizedTitleMatches = await transaction
        .rawQuery(
          '''
          SELECT id
          FROM skills
          WHERE lower(trim(title)) = lower(trim(?))
          ORDER BY id
          LIMIT 2
          ''',
          <Object?>[remoteTitle],
        );
    if (existing.length > 1 || normalizedTitleMatches.length > 1) {
      throw const LocalSwapProjectionException(
        'Multiple local catalog skills share the same remote identity or '
        'title.',
      );
    }

    if (existing.isNotEmpty) {
      return (localId: cleanSkillId, unresolved: false);
    }

    if (normalizedTitleMatches.isNotEmpty) {
      final Object? aliasId = normalizedTitleMatches.single['id'];
      if (aliasId is! String || aliasId.trim().isEmpty) {
        throw const LocalSwapProjectionException(
          'A local catalog skill has an invalid ID.',
        );
      }
      return (localId: aliasId.trim(), unresolved: false);
    }

    return (localId: null, unresolved: true);
  }

  ActiveUserSession _captureViewerSession(String viewerUid) {
    final String cleanUid = _requireRemoteUid(viewerUid, 'Active viewer UID');
    try {
      final ActiveUserSession session = _currentUserService.captureSession();
      if (session.uid != cleanUid) {
        throw const LocalSwapProjectionException(
          'The local swap projection is limited to the active viewer.',
        );
      }
      return session;
    } on LocalSwapProjectionException {
      rethrow;
    } on CurrentUserServiceException catch (error) {
      throw LocalSwapProjectionException(error.message);
    }
  }

  void _requireSameSession(ActiveUserSession session) {
    try {
      _currentUserService.requireSameSession(session);
    } on CurrentUserServiceException catch (error) {
      throw LocalSwapProjectionException(error.message);
    }
  }

  String _requireRemoteUid(String value, String label) {
    final String clean = value.trim();
    if (clean.isEmpty || clean != value || clean == _legacyLocalUid) {
      throw LocalSwapProjectionException('$label is invalid.');
    }
    return clean;
  }

  String _requireStatus(String status) {
    final String clean = status.trim();
    if (!_activeStatuses.contains(clean) && !_terminalStatuses.contains(clean)) {
      throw LocalSwapProjectionException(
        'A cloud swap request has an unrecognized status.',
      );
    }
    return clean;
  }
}
