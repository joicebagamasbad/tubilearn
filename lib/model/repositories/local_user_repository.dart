import 'package:sqflite/sqflite.dart';

import '../../services/current_user_service.dart';
import '../auth_session.dart';
import '../database/app_database.dart';

class LocalUserRepository {
  final AppDatabase _database = AppDatabase.instance;

  Future<Set<String>> findExistingUserIds(Set<String> userIds) async {
    final CurrentUserService currentUserService =
        CurrentUserService.instance;
    final ActiveUserSession session = currentUserService.captureSession();
    final List<String> cleanIds = userIds
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (cleanIds.isEmpty) {
      return <String>{};
    }

    final Database db = await _database.database;
    currentUserService.requireSameSession(session);

    const int queryBatchSize = 400;
    final Set<String> existingIds = <String>{};

    for (int offset = 0; offset < cleanIds.length; offset += queryBatchSize) {
      final int end = (offset + queryBatchSize < cleanIds.length)
          ? offset + queryBatchSize
          : cleanIds.length;
      final List<String> batch = cleanIds.sublist(offset, end);
      final String placeholders =
          List<String>.filled(batch.length, '?').join(',');
      final List<Map<String, Object?>> rows = await db.query(
        'users',
        columns: <String>['id'],
        where: 'id IN ($placeholders)',
        whereArgs: batch,
      );
      currentUserService.requireSameSession(session);

      for (final Map<String, Object?> row in rows) {
        final Object? rawId = row['id'];
        if (rawId is! String || rawId.trim().isEmpty) {
          throw StateError('Stored local user ID is invalid.');
        }
        existingIds.add(rawId.trim());
      }
    }

    currentUserService.requireSameSession(session);
    return Set<String>.unmodifiable(existingIds);
  }

  Future<void> provision(AuthSession session) async {
    final String uid = session.uid.trim();
    if (uid.isEmpty || uid == 'user_joice_local') {
      throw StateError('Invalid authenticated user ID.');
    }

    final Database db = await _database.database;
    final List<Map<String, Object?>> existing = await db.query(
      'users', columns: <String>['id'], where: 'id = ?',
      whereArgs: <Object?>[uid], limit: 1,
    );
    if (existing.isNotEmpty) {
      await db.update(
        'users',
        <String, Object?>{'email_verified': session.emailVerified ? 1 : 0},
        where: 'id = ?',
        whereArgs: <Object?>[uid],
      );
      return;
    }

    final String? displayName = session.displayName?.trim();
    final String? emailName = session.email?.split('@').first.trim();
    final String name = displayName != null && displayName.isNotEmpty
        ? displayName
        : emailName != null && emailName.isNotEmpty
            ? emailName
            : 'TubiLearn member';
    final String initials = name
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .take(2)
        .map((String part) => part[0].toUpperCase())
        .join();

    await db.insert('users', <String, Object?>{
      'id': uid,
      'name': name,
      'initials': initials,
      'city': 'Not set',
      'bio': '',
      'rating': 0.0,
      'review_count': 0,
      'completed_swaps': 0,
      'response_rate': 0,
      'member_since': DateTime.now().year.toString(),
      'availability': 'Not set',
      'language': 'Not set',
      'preferred_mode': 'Not set',
      'teaching_style': 'Not set',
      'email_verified': session.emailVerified ? 1 : 0,
      'profile_completed': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    final List<Map<String, Object?>> stored = await db.query(
      'users', columns: <String>['id'], where: 'id = ?',
      whereArgs: <Object?>[uid], limit: 1,
    );
    if (stored.length != 1) {
      throw StateError('Could not prepare the local user profile.');
    }
  }
}
