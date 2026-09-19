import 'package:sqflite/sqflite.dart';

import '../auth_session.dart';
import '../database/app_database.dart';

class LocalUserRepository {
  final AppDatabase _database = AppDatabase.instance;

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
