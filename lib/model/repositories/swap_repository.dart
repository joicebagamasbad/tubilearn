import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../swap_request.dart';
import 'user_visibility_repository.dart';

class SwapRepositoryException implements Exception {
  final String message;

  const SwapRepositoryException(
      this.message,
      );

  @override
  String toString() => message;
}

class SwapRepository {
  final AppDatabase _appDatabase =
      AppDatabase.instance;

  final UserVisibilityRepository
  _visibilityRepository =
      UserVisibilityRepository.instance;

  // ============================================================
  // READ SWAP REQUESTS
  // ============================================================

  Future<List<SwapRequest>> getAllSwapRequests({
    String? userId,
    bool includeHidden = false,
  }) async {
    final String? cleanUserId =
    _normalizeNullable(
      userId,
    );

    if (!includeHidden &&
        cleanUserId == null) {
      throw const SwapRepositoryException(
        'User ID is required when loading visible swap requests.',
      );
    }

    try {
      final Database db =
      await _appDatabase.database;

      final bool hasIdentityColumns =
      await _hasIdentityColumns(
        db,
      );

      final List<Map<String, Object?>> rows =
      await db.query(
        'swap_requests',
        orderBy: 'created_at DESC',
      );

      final List<SwapRequest> allRequests =
      <SwapRequest>[];

      final Set<String> requestIds =
      <String>{};

      for (final Map<String, Object?> row
      in rows) {
        final SwapRequest request =
        _parseSwapRequestRow(
          row,
          hasIdentityColumns:
          hasIdentityColumns,
        );

        if (!requestIds.add(
          request.id,
        )) {
          throw const SwapRepositoryException(
            'Stored swap data contains duplicate request IDs.',
          );
        }

        allRequests.add(
          request,
        );
      }

      if (includeHidden ||
          cleanUserId == null) {
        return List<SwapRequest>.unmodifiable(
          allRequests,
        );
      }

      final Set<String> hiddenRequestIds;

      try {
        hiddenRequestIds =
        await _visibilityRepository
            .getHiddenSwapRequestIds(
          cleanUserId,
        );
      } on UserVisibilityRepositoryException catch (_) {
        throw const SwapRepositoryException(
          'Could not load swap visibility settings.',
        );
      }

      final List<SwapRequest> visibleRequests =
      allRequests
          .where(
            (
            SwapRequest request,
            ) =>
        !hiddenRequestIds.contains(
          request.id,
        ),
      )
          .toList(
        growable: false,
      );

      return List<SwapRequest>.unmodifiable(
        visibleRequests,
      );
    } on SwapRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const SwapRepositoryException(
        'Stored swap requests could not be read.',
      );
    } catch (_) {
      throw const SwapRepositoryException(
        'Stored swap requests could not be read.',
      );
    }
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

      final String? requesterUserId =
      hasIdentityColumns
          ? _readNullableStoredString(
        row,
        'requester_user_id',
      )
          : null;

      final String? providerUserId =
      hasIdentityColumns
          ? _readNullableStoredString(
        row,
        'provider_user_id',
      )
          : null;

      final String? skillToLearnId =
      hasIdentityColumns
          ? _readNullableStoredString(
        row,
        'skill_to_learn_id',
      )
          : null;

      final String? skillToOfferId =
      hasIdentityColumns
          ? _readNullableStoredString(
        row,
        'skill_to_offer_id',
      )
          : null;

      final int presentIdentityValues =
          <String?>[
            requesterUserId,
            providerUserId,
            skillToLearnId,
            skillToOfferId,
          ].where(
                (
                String? value,
                ) =>
            value != null,
          ).length;

      if (presentIdentityValues != 0 &&
          presentIdentityValues != 4) {
        throw SwapRepositoryException(
          'Swap request "$id" has incomplete identity data.',
        );
      }

      return SwapRequest(
        id: id,
        requesterUserId: requesterUserId,
        providerUserId: providerUserId,
        skillToLearnId: skillToLearnId,
        skillToOfferId: skillToOfferId,
        providerName: providerName,
        providerInitials: providerInitials,
        providerCity: providerCity,
        skillToLearn: skillToLearn,
        skillToOffer: skillToOffer,
        proposedAt: proposedAt,
        mode: mode,
        meetingDetails:
        _readNullableStoredString(
          row,
          'meeting_details',
        ),
        note:
        _readNullableStoredString(
          row,
          'note',
        ),
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
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

    final String? requesterUserId =
    _normalizeNullable(
      request.requesterUserId,
    );

    final String? providerUserId =
    _normalizeNullable(
      request.providerUserId,
    );

    final String? skillToLearnId =
    _normalizeNullable(
      request.skillToLearnId,
    );

    final String? skillToOfferId =
    _normalizeNullable(
      request.skillToOfferId,
    );

    _validateIdentityGroup(
      requesterUserId:
      requesterUserId,
      providerUserId:
      providerUserId,
      skillToLearnId:
      skillToLearnId,
      skillToOfferId:
      skillToOfferId,
    );

    final int proposedAt =
    _dateTimeToMilliseconds(
      request.proposedAt,
      'Proposed schedule',
    );

    final int createdAt =
    _dateTimeToMilliseconds(
      request.createdAt,
      'Created timestamp',
    );

    final int updatedAt =
    _dateTimeToMilliseconds(
      request.updatedAt,
      'Updated timestamp',
    );

    if (updatedAt <
        createdAt) {
      throw const SwapRepositoryException(
        'Updated timestamp cannot be before created timestamp.',
      );
    }

    final String? meetingDetails =
    _normalizeNullable(
      request.meetingDetails,
    );

    final String? note =
    _normalizeNullable(
      request.note,
    );

    if (meetingDetails != null &&
        meetingDetails.length > 150) {
      throw const SwapRepositoryException(
        'Meeting details must be 150 characters or less.',
      );
    }

    if (note != null &&
        note.length > 300) {
      throw const SwapRepositoryException(
        'Message must be 300 characters or less.',
      );
    }

    try {
      final Database db =
      await _appDatabase.database;

      final bool hasIdentityColumns =
      await _hasIdentityColumns(
        db,
      );

      if (!hasIdentityColumns) {
        throw const SwapRepositoryException(
          'Current swap request schema does not support stable identity.',
        );
      }

      final int insertedRowId =
      await db.insert(
        'swap_requests',
        <String, Object?>{
          'id': requestId,
          'requester_user_id':
          requesterUserId,
          'provider_user_id':
          providerUserId,
          'skill_to_learn_id':
          skillToLearnId,
          'skill_to_offer_id':
          skillToOfferId,
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
          proposedAt,
          'mode':
          mode,
          'meeting_details':
          meetingDetails,
          'note':
          note,
          'status':
          request.status.databaseValue,
          'created_at':
          createdAt,
          'updated_at':
          updatedAt,
        },
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
    } on DatabaseException catch (_) {
      throw const SwapRepositoryException(
        'Swap request could not be saved.',
      );
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

    final int cleanUpdatedAt =
    _dateTimeToMilliseconds(
      updatedAt,
      'Updated timestamp',
    );

    try {
      final Database db =
      await _appDatabase.database;

      final int affectedRows =
      await db.update(
        'swap_requests',
        <String, Object?>{
          'status':
          status.databaseValue,
          'updated_at':
          cleanUpdatedAt,
        },
        where: 'id = ?',
        whereArgs: <Object?>[
          cleanRequestId,
        ],
      );

      if (affectedRows != 1) {
        throw SwapRepositoryException(
          'Expected to update exactly 1 swap request, but updated $affectedRows.',
        );
      }
    } on SwapRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const SwapRepositoryException(
        'Swap request status could not be updated.',
      );
    } catch (_) {
      throw const SwapRepositoryException(
        'Swap request status could not be updated.',
      );
    }
  }

  // ============================================================
  // HIDE
  // ============================================================

  Future<void> hideSwapRequest({
    required String requestId,
    required String userId,
  }) async {
    final String cleanRequestId =
    _requireText(
      requestId,
      'Swap request ID',
    );

    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    try {
      await _visibilityRepository
          .hideSwapRequest(
        swapRequestId:
        cleanRequestId,
        userId:
        cleanUserId,
      );
    } on UserVisibilityRepositoryException catch (_) {
      throw const SwapRepositoryException(
        'Swap request could not be hidden.',
      );
    } catch (_) {
      throw const SwapRepositoryException(
        'Swap request could not be hidden.',
      );
    }
  }

  // ============================================================
  // UNHIDE
  // ============================================================

  Future<void> unhideSwapRequest({
    required String requestId,
    required String userId,
  }) async {
    final String cleanRequestId =
    _requireText(
      requestId,
      'Swap request ID',
    );

    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    try {
      await _visibilityRepository
          .unhideSwapRequest(
        swapRequestId:
        cleanRequestId,
        userId:
        cleanUserId,
      );
    } on UserVisibilityRepositoryException catch (_) {
      throw const SwapRepositoryException(
        'Swap request could not be restored.',
      );
    } catch (_) {
      throw const SwapRepositoryException(
        'Swap request could not be restored.',
      );
    }
  }

  // ============================================================
  // PERMANENT DELETE
  // ============================================================

  Future<void> deleteSwapRequestPermanently(
      String requestId,
      ) async {
    final String cleanRequestId =
    _requireText(
      requestId,
      'Swap request ID',
    );

    try {
      final Database db =
      await _appDatabase.database;

      final int affectedRows =
      await db.delete(
        'swap_requests',
        where: 'id = ?',
        whereArgs: <Object?>[
          cleanRequestId,
        ],
      );

      if (affectedRows != 1) {
        throw SwapRepositoryException(
          'Expected to delete exactly 1 swap request, but deleted $affectedRows.',
        );
      }
    } on SwapRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const SwapRepositoryException(
        'Swap request could not be permanently deleted.',
      );
    } catch (_) {
      throw const SwapRepositoryException(
        'Swap request could not be permanently deleted.',
      );
    }
  }

  // ============================================================
  // SCHEMA DETECTION
  // ============================================================

  Future<bool> _hasIdentityColumns(
      Database db,
      ) async {
    final List<Map<String, Object?>> columns;

    try {
      columns =
      await db.rawQuery(
        'PRAGMA table_info(swap_requests)',
      );
    } on DatabaseException catch (_) {
      throw const SwapRepositoryException(
        'Swap request database schema could not be read.',
      );
    } catch (_) {
      throw const SwapRepositoryException(
        'Swap request database schema could not be read.',
      );
    }

    final Set<String> columnNames =
    <String>{};

    for (final Map<String, Object?> column
    in columns) {
      final Object? rawName =
      column['name'];

      if (rawName is! String) {
        continue;
      }

      final String name =
      rawName.trim();

      if (name.isNotEmpty) {
        columnNames.add(
          name,
        );
      }
    }

    const Set<String> identityColumns =
    <String>{
      'requester_user_id',
      'provider_user_id',
      'skill_to_learn_id',
      'skill_to_offer_id',
    };

    final int presentCount =
        identityColumns
            .where(
          columnNames.contains,
        )
            .length;

    if (presentCount == 0) {
      return false;
    }

    if (presentCount !=
        identityColumns.length) {
      throw const SwapRepositoryException(
        'Swap request database schema has incomplete identity columns.',
      );
    }

    return true;
  }

  // ============================================================
  // IDENTITY VALIDATION
  // ============================================================

  void _validateIdentityGroup({
    required String? requesterUserId,
    required String? providerUserId,
    required String? skillToLearnId,
    required String? skillToOfferId,
  }) {
    final List<String?> values =
    <String?>[
      requesterUserId,
      providerUserId,
      skillToLearnId,
      skillToOfferId,
    ];

    final int presentCount =
        values.where(
              (
              String? value,
              ) =>
          value != null,
        ).length;

    if (presentCount != 0 &&
        presentCount != 4) {
      throw const SwapRepositoryException(
        'Swap request identity is incomplete.',
      );
    }

    if (presentCount == 0) {
      return;
    }

    if (requesterUserId ==
        providerUserId) {
      throw const SwapRepositoryException(
        'Requester and provider must be different users.',
      );
    }

    if (skillToLearnId ==
        skillToOfferId) {
      throw const SwapRepositoryException(
        'Skill to learn and skill to offer must be different.',
      );
    }
  }

  // ============================================================
  // REQUIRED STRING
  // ============================================================

  String _readRequiredString(
      Map<String, Object?> row,
      String key,
      ) {
    if (!row.containsKey(
      key,
    )) {
      throw SwapRepositoryException(
        'Stored swap request is missing "$key".',
      );
    }

    final Object? value =
    row[key];

    if (value is! String) {
      throw SwapRepositoryException(
        'Stored swap request has an invalid "$key".',
      );
    }

    final String normalized =
    value.trim();

    if (normalized.isEmpty) {
      throw SwapRepositoryException(
        'Stored swap request has an empty "$key".',
      );
    }

    return normalized;
  }

  // ============================================================
  // OPTIONAL STRING
  // ============================================================

  String? _readNullableStoredString(
      Map<String, Object?> row,
      String key,
      ) {
    if (!row.containsKey(
      key,
    )) {
      throw SwapRepositoryException(
        'Stored swap request is missing "$key".',
      );
    }

    final Object? value =
    row[key];

    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw SwapRepositoryException(
        'Stored swap request has an invalid "$key".',
      );
    }

    final String normalized =
    value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ============================================================
  // TIMESTAMP
  // ============================================================

  DateTime _readRequiredDateTime(
      Map<String, Object?> row,
      String key,
      ) {
    if (!row.containsKey(
      key,
    )) {
      throw SwapRepositoryException(
        'Stored swap request is missing "$key".',
      );
    }

    final int milliseconds =
    _readExactInteger(
      row[key],
      key,
    );

    if (milliseconds <= 0) {
      throw SwapRepositoryException(
        'Stored swap request has an invalid "$key".',
      );
    }

    final DateTime value =
    DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
    );

    if (value.millisecondsSinceEpoch !=
        milliseconds) {
      throw SwapRepositoryException(
        'Stored swap request has an invalid "$key".',
      );
    }

    return value;
  }

  int _readExactInteger(
      Object? value,
      String label,
      ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      final double numeric =
      value.toDouble();

      if (!numeric.isFinite ||
          numeric !=
              numeric.truncateToDouble()) {
        throw SwapRepositoryException(
          'Stored swap request has an invalid "$label".',
        );
      }

      return numeric.toInt();
    }

    if (value is String) {
      final int? parsed =
      int.tryParse(
        value.trim(),
      );

      if (parsed != null) {
        return parsed;
      }
    }

    throw SwapRepositoryException(
      'Stored swap request has an invalid "$label".',
    );
  }

  int _dateTimeToMilliseconds(
      DateTime value,
      String label,
      ) {
    final int milliseconds =
        value.millisecondsSinceEpoch;

    if (milliseconds <= 0) {
      throw SwapRepositoryException(
        '$label is invalid.',
      );
    }

    final DateTime roundTrip =
    DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
    );

    if (roundTrip.millisecondsSinceEpoch !=
        milliseconds) {
      throw SwapRepositoryException(
        '$label could not be stored safely.',
      );
    }

    return milliseconds;
  }

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