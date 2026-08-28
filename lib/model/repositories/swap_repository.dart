import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../swap_request.dart';

class SwapRepository {
  final AppDatabase _appDatabase =
      AppDatabase.instance;

  // ============================================================
  // READ ALL SWAP REQUESTS
  // ============================================================

  Future<List<SwapRequest>>
  getAllSwapRequests() async {
    final Database db =
    await _appDatabase.database;

    final bool hasIdentityColumns =
    await _hasIdentityColumns(db);

    final List<Map<String, Object?>>
    rows =
    await db.query(
      'swap_requests',
      orderBy: 'created_at DESC',
    );

    return rows.map(
          (row) {
        return SwapRequest(
          id: row['id'] as String,

          requesterUserId:
          hasIdentityColumns
              ? _readNullableString(
            row[
            'requester_user_id'],
          )
              : null,

          providerUserId:
          hasIdentityColumns
              ? _readNullableString(
            row[
            'provider_user_id'],
          )
              : null,

          skillToLearnId:
          hasIdentityColumns
              ? _readNullableString(
            row[
            'skill_to_learn_id'],
          )
              : null,

          skillToOfferId:
          hasIdentityColumns
              ? _readNullableString(
            row[
            'skill_to_offer_id'],
          )
              : null,

          providerName:
          row['provider_name']
          as String,

          providerInitials:
          row['provider_initials']
          as String,

          providerCity:
          row['provider_city']
          as String,

          skillToLearn:
          row['skill_to_learn']
          as String,

          skillToOffer:
          row['skill_to_offer']
          as String,

          proposedAt:
          DateTime
              .fromMillisecondsSinceEpoch(
            row['proposed_at']
            as int,
          ),

          mode:
          row['mode'] as String,

          meetingDetails:
          row['meeting_details']
          as String?,

          note:
          row['note']
          as String?,

          status:
          SwapRequestStatusExtension
              .fromDatabase(
            row['status']
            as String,
          ),

          createdAt:
          DateTime
              .fromMillisecondsSinceEpoch(
            row['created_at']
            as int,
          ),

          updatedAt:
          DateTime
              .fromMillisecondsSinceEpoch(
            row['updated_at']
            as int,
          ),
        );
      },
    ).toList();
  }

  // ============================================================
  // SAVE SWAP REQUEST
  // ============================================================

  Future<void> saveSwapRequest(
      SwapRequest request,
      ) async {
    final Database db =
    await _appDatabase.database;

    final bool hasIdentityColumns =
    await _hasIdentityColumns(db);

    final Map<String, Object?>
    values =
    <String, Object?>{
      'id':
      request.id,

      'provider_name':
      request.providerName,

      'provider_initials':
      request.providerInitials,

      'provider_city':
      request.providerCity,

      'skill_to_learn':
      request.skillToLearn,

      'skill_to_offer':
      request.skillToOffer,

      'proposed_at':
      request.proposedAt
          .millisecondsSinceEpoch,

      'mode':
      request.mode,

      'meeting_details':
      request.meetingDetails,

      'note':
      request.note,

      'status':
      request.status.databaseValue,

      'created_at':
      request.createdAt
          .millisecondsSinceEpoch,

      'updated_at':
      request.updatedAt
          .millisecondsSinceEpoch,
    };

    // ----------------------------------------------------------
    // These columns only physically exist starting in DB v4.
    //
    // While the database is still v3, we intentionally do not
    // include them in INSERT statements so SQLite will not fail.
    // ----------------------------------------------------------

    if (hasIdentityColumns) {
      values.addAll(
        <String, Object?>{
          'requester_user_id':
          _normalizeNullable(
            request.requesterUserId,
          ),

          'provider_user_id':
          _normalizeNullable(
            request.providerUserId,
          ),

          'skill_to_learn_id':
          _normalizeNullable(
            request.skillToLearnId,
          ),

          'skill_to_offer_id':
          _normalizeNullable(
            request.skillToOfferId,
          ),
        },
      );
    }

    await db.insert(
      'swap_requests',
      values,
      conflictAlgorithm:
      ConflictAlgorithm.abort,
    );
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> updateStatus({
    required String requestId,
    required SwapRequestStatus status,
    required DateTime updatedAt,
  }) async {
    final Database db =
    await _appDatabase.database;

    final int affectedRows =
    await db.update(
      'swap_requests',
      {
        'status':
        status.databaseValue,

        'updated_at':
        updatedAt
            .millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [
        requestId,
      ],
    );

    if (affectedRows != 1) {
      throw StateError(
        'Expected to update 1 swap request, but updated $affectedRows.',
      );
    }
  }

  // ============================================================
  // DELETE
  //
  // Hard delete is not normal cancellation behavior.
  // Normal user cancellation should use status = cancelled.
  // ============================================================

  Future<void> deleteSwapRequest(
      String requestId,
      ) async {
    final Database db =
    await _appDatabase.database;

    final int affectedRows =
    await db.delete(
      'swap_requests',
      where: 'id = ?',
      whereArgs: [
        requestId,
      ],
    );

    if (affectedRows != 1) {
      throw StateError(
        'Expected to delete 1 swap request, but deleted $affectedRows.',
      );
    }
  }

  // ============================================================
  // SCHEMA DETECTION
  //
  // Transitional protection while users may still have a v3 DB.
  // Once DB v4 is fully established, these identity columns will
  // always exist.
  // ============================================================

  Future<bool> _hasIdentityColumns(
      Database db,
      ) async {
    final List<Map<String, Object?>>
    columns =
    await db.rawQuery(
      'PRAGMA table_info(swap_requests)',
    );

    final Set<String> columnNames =
    columns
        .map(
          (column) =>
      column['name']
      as String,
    )
        .toSet();

    return columnNames.contains(
      'requester_user_id',
    ) &&
        columnNames.contains(
          'provider_user_id',
        ) &&
        columnNames.contains(
          'skill_to_learn_id',
        ) &&
        columnNames.contains(
          'skill_to_offer_id',
        );
  }

  // ============================================================
  // VALUE HELPERS
  // ============================================================

  String? _readNullableString(
      Object? value,
      ) {
    if (value == null) {
      return null;
    }

    final String normalized =
    value.toString().trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  String? _normalizeNullable(
      String? value,
      ) {
    if (value == null) {
      return null;
    }

    final String normalized =
    value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}