import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../swap_request.dart';

class SwapRepositoryException implements Exception {
  final String message;

  const SwapRepositoryException(this.message);

  @override
  String toString() => message;
}

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
    await _hasIdentityColumns(
      db,
    );

    final List<Map<String, Object?>> rows;

    try {
      rows = await db.query(
        'swap_requests',
        orderBy: 'created_at DESC',
      );
    } catch (_) {
      throw const SwapRepositoryException(
        'Stored swap requests could not be read.',
      );
    }

    final List<SwapRequest> requests =
    <SwapRequest>[];

    for (final Map<String, Object?> row
    in rows) {
      requests.add(
        _parseSwapRequestRow(
          row,
          hasIdentityColumns:
          hasIdentityColumns,
        ),
      );
    }

    return requests;
  }

  // ============================================================
  // PARSE STORED ROW
  // ============================================================

  SwapRequest _parseSwapRequestRow(
      Map<String, Object?> row, {
        required bool hasIdentityColumns,
      }) {
    try {
      final String id =
      _readRequiredString(
        row,
        'id',
      );

      final String providerName =
      _readRequiredString(
        row,
        'provider_name',
      );

      final String providerInitials =
      _readRequiredString(
        row,
        'provider_initials',
      );

      final String providerCity =
      _readRequiredString(
        row,
        'provider_city',
      );

      final String skillToLearn =
      _readRequiredString(
        row,
        'skill_to_learn',
      );

      final String skillToOffer =
      _readRequiredString(
        row,
        'skill_to_offer',
      );

      final String mode =
      _readRequiredString(
        row,
        'mode',
      );

      final String statusValue =
      _readRequiredString(
        row,
        'status',
      );

      final DateTime proposedAt =
      _readRequiredDateTime(
        row,
        'proposed_at',
      );

      final DateTime createdAt =
      _readRequiredDateTime(
        row,
        'created_at',
      );

      final DateTime updatedAt =
      _readRequiredDateTime(
        row,
        'updated_at',
      );

      final SwapRequestStatus status;

      try {
        status =
            SwapRequestStatusExtension
                .fromDatabase(
              statusValue,
            );
      } on FormatException {
        throw SwapRepositoryException(
          'Swap request "$id" has an invalid stored status.',
        );
      }

      return SwapRequest(
        id:
        id,

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
        providerName,

        providerInitials:
        providerInitials,

        providerCity:
        providerCity,

        skillToLearn:
        skillToLearn,

        skillToOffer:
        skillToOffer,

        proposedAt:
        proposedAt,

        mode:
        mode,

        meetingDetails:
        _readNullableString(
          row['meeting_details'],
        ),

        note:
        _readNullableString(
          row['note'],
        ),

        status:
        status,

        createdAt:
        createdAt,

        updatedAt:
        updatedAt,
      );
    } on SwapRepositoryException {
      rethrow;
    } catch (_) {
      throw const SwapRepositoryException(
        'A stored swap request contains invalid data.',
      );
    }
  }

  // ============================================================
  // SAVE SWAP REQUEST
  // ============================================================

  Future<void> saveSwapRequest(
      SwapRequest request,
      ) async {
    final Database db =
    await _appDatabase.database;

    final String requestId =
    _requireText(
      request.id,
      'Swap request ID',
    );

    final String providerName =
    _requireText(
      request.providerName,
      'Provider name',
    );

    final String providerInitials =
    _requireText(
      request.providerInitials,
      'Provider initials',
    );

    final String providerCity =
    _requireText(
      request.providerCity,
      'Provider city',
    );

    final String skillToLearn =
    _requireText(
      request.skillToLearn,
      'Skill to learn',
    );

    final String skillToOffer =
    _requireText(
      request.skillToOffer,
      'Skill to offer',
    );

    final String mode =
    _requireText(
      request.mode,
      'Session mode',
    );

    final bool hasIdentityColumns =
    await _hasIdentityColumns(
      db,
    );

    final Map<String, Object?> values =
    <String, Object?>{
      'id':
      requestId,

      'provider_name':
      providerName,

      'provider_initials':
      providerInitials,

      'provider_city':
      providerCity,

      'skill_to_learn':
      skillToLearn,

      'skill_to_offer':
      skillToOffer,

      'proposed_at':
      request.proposedAt
          .millisecondsSinceEpoch,

      'mode':
      mode,

      'meeting_details':
      _normalizeNullable(
        request.meetingDetails,
      ),

      'note':
      _normalizeNullable(
        request.note,
      ),

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
    // Identity columns physically exist starting with DB v4.
    // Keep this compatibility guard for older migrated installs.
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

    try {
      final int insertedRowId =
      await db.insert(
        'swap_requests',
        values,
        conflictAlgorithm:
        ConflictAlgorithm.abort,
      );

      if (insertedRowId <= 0) {
        throw const SwapRepositoryException(
          'Swap request was not saved.',
        );
      }
    } on SwapRepositoryException {
      rethrow;
    } catch (_) {
      throw const SwapRepositoryException(
        'Swap request could not be saved.',
      );
    }
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> updateStatus({
    required String requestId,
    required SwapRequestStatus status,
    required DateTime updatedAt,
  }) async {
    final String cleanRequestId =
    _requireText(
      requestId,
      'Swap request ID',
    );

    final Database db =
    await _appDatabase.database;

    final int affectedRows;

    try {
      affectedRows =
      await db.update(
        'swap_requests',
        <String, Object?>{
          'status':
          status.databaseValue,

          'updated_at':
          updatedAt
              .millisecondsSinceEpoch,
        },
        where:
        'id = ?',
        whereArgs:
        <Object?>[
          cleanRequestId,
        ],
      );
    } catch (_) {
      throw const SwapRepositoryException(
        'Swap request status could not be updated.',
      );
    }

    if (affectedRows != 1) {
      throw SwapRepositoryException(
        'Expected to update exactly 1 swap request, but updated $affectedRows.',
      );
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteSwapRequest(
      String requestId,
      ) async {
    final String cleanRequestId =
    _requireText(
      requestId,
      'Swap request ID',
    );

    final Database db =
    await _appDatabase.database;

    final int affectedRows;

    try {
      affectedRows =
      await db.delete(
        'swap_requests',
        where:
        'id = ?',
        whereArgs:
        <Object?>[
          cleanRequestId,
        ],
      );
    } catch (_) {
      throw const SwapRepositoryException(
        'Swap request could not be deleted.',
      );
    }

    if (affectedRows != 1) {
      throw SwapRepositoryException(
        'Expected to delete exactly 1 swap request, but deleted $affectedRows.',
      );
    }
  }

  // ============================================================
  // SCHEMA DETECTION
  // ============================================================

  Future<bool> _hasIdentityColumns(
      Database db,
      ) async {
    final List<Map<String, Object?>>
    columns;

    try {
      columns =
      await db.rawQuery(
        'PRAGMA table_info(swap_requests)',
      );
    } catch (_) {
      throw const SwapRepositoryException(
        'Swap request database schema could not be read.',
      );
    }

    final Set<String> columnNames =
    <String>{};

    for (final Map<String, Object?>
    column in columns) {
      final Object? rawName =
      column['name'];

      if (rawName == null) {
        continue;
      }

      final String name =
      rawName
          .toString()
          .trim();

      if (name.isNotEmpty) {
        columnNames.add(
          name,
        );
      }
    }

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
  // REQUIRED STRING READER
  // ============================================================

  String _readRequiredString(
      Map<String, Object?> row,
      String key,
      ) {
    if (!row.containsKey(key)) {
      throw SwapRepositoryException(
        'Stored swap request is missing "$key".',
      );
    }

    final Object? value =
    row[key];

    if (value == null) {
      throw SwapRepositoryException(
        'Stored swap request has no value for "$key".',
      );
    }

    final String normalized =
    value
        .toString()
        .trim();

    if (normalized.isEmpty) {
      throw SwapRepositoryException(
        'Stored swap request has an empty "$key".',
      );
    }

    return normalized;
  }

  // ============================================================
  // TIMESTAMP READER
  // ============================================================

  DateTime _readRequiredDateTime(
      Map<String, Object?> row,
      String key,
      ) {
    if (!row.containsKey(key)) {
      throw SwapRepositoryException(
        'Stored swap request is missing "$key".',
      );
    }

    final Object? value =
    row[key];

    final int? milliseconds;

    if (value is int) {
      milliseconds =
          value;
    } else if (value is num) {
      milliseconds =
          value.toInt();
    } else if (value != null) {
      milliseconds =
          int.tryParse(
            value.toString(),
          );
    } else {
      milliseconds =
      null;
    }

    if (milliseconds == null ||
        milliseconds < 0) {
      throw SwapRepositoryException(
        'Stored swap request has an invalid "$key".',
      );
    }

    try {
      return DateTime
          .fromMillisecondsSinceEpoch(
        milliseconds,
      );
    } catch (_) {
      throw SwapRepositoryException(
        'Stored swap request has an invalid "$key".',
      );
    }
  }

  // ============================================================
  // VALUE HELPERS
  // ============================================================

  String _requireText(
      String value,
      String fieldName,
      ) {
    final String normalized =
    value.trim();

    if (normalized.isEmpty) {
      throw SwapRepositoryException(
        '$fieldName is required.',
      );
    }

    return normalized;
  }

  String? _readNullableString(
      Object? value,
      ) {
    if (value == null) {
      return null;
    }

    final String normalized =
    value
        .toString()
        .trim();

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