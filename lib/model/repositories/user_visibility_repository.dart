import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

class UserVisibilityRepositoryException
    implements Exception {
  final String message;

  const UserVisibilityRepositoryException(
      this.message,
      );

  @override
  String toString() => message;
}

class UserVisibilityRepository {
  UserVisibilityRepository._();

  static final UserVisibilityRepository instance =
  UserVisibilityRepository._();

  final AppDatabase _appDatabase =
      AppDatabase.instance;

  // ============================================================
  // CONVERSATION VISIBILITY
  // ============================================================

  Future<bool> isConversationHidden({
    required String conversationId,
    required String userId,
  }) async {
    final String cleanConversationId =
    _requireText(
      conversationId,
      'Conversation ID',
    );

    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    try {
      final Database db =
      await _appDatabase.database;

      final List<Map<String, Object?>> rows =
      await db.query(
        'conversation_user_visibility',
        columns: <String>[
          'is_hidden',
          'hidden_at',
        ],
        where: '''
          conversation_id = ?
          AND user_id = ?
        ''',
        whereArgs: <Object?>[
          cleanConversationId,
          cleanUserId,
        ],
        limit: 1,
      );

      if (rows.isEmpty) {
        return false;
      }

      final Map<String, Object?> row =
          rows.first;

      final bool isHidden =
      _readRequiredBooleanInt(
        row,
        'is_hidden',
        'Conversation visibility',
      );

      final DateTime? hiddenAt =
      _readOptionalDateTime(
        row,
        'hidden_at',
        'Conversation hidden timestamp',
      );

      _validateVisibilityState(
        isHidden: isHidden,
        hiddenAt: hiddenAt,
        label: 'Conversation visibility',
      );

      return isHidden;
    } on UserVisibilityRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not read conversation visibility.',
      );
    } catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not read conversation visibility.',
      );
    }
  }

  // ============================================================
  // HIDDEN CONVERSATION IDS
  //
  // Set form is useful for filtering visible conversations.
  // ============================================================

  Future<Set<String>> getHiddenConversationIds(
      String userId,
      ) async {
    final List<String> orderedIds =
    await getHiddenConversationIdsNewestFirst(
      userId,
    );

    return Set<String>.unmodifiable(
      orderedIds,
    );
  }

  // ============================================================
  // HIDDEN CONVERSATION IDS - NEWEST FIRST
  //
  // This is important once one participant may have multiple
  // archived conversation threads.
  //
  // hidden_at gives us a deterministic archive order instead of
  // guessing from participant name, message contents, or IDs.
  // ============================================================

  Future<List<String>>
  getHiddenConversationIdsNewestFirst(
      String userId,
      ) async {
    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    try {
      final Database db =
      await _appDatabase.database;

      final List<Map<String, Object?>> rows =
      await db.query(
        'conversation_user_visibility',
        columns: <String>[
          'conversation_id',
          'is_hidden',
          'hidden_at',
        ],
        where: '''
          user_id = ?
          AND is_hidden = 1
        ''',
        whereArgs: <Object?>[
          cleanUserId,
        ],
        orderBy: '''
          hidden_at DESC,
          conversation_id DESC
        ''',
      );

      final List<String> result =
      <String>[];

      final Set<String> seenIds =
      <String>{};

      DateTime? previousHiddenAt;

      for (final Map<String, Object?> row
      in rows) {
        final String conversationId =
        _requireRowString(
          row,
          'conversation_id',
          'Conversation ID',
        );

        final bool isHidden =
        _readRequiredBooleanInt(
          row,
          'is_hidden',
          'Conversation visibility',
        );

        final DateTime? hiddenAt =
        _readOptionalDateTime(
          row,
          'hidden_at',
          'Conversation hidden timestamp',
        );

        _validateVisibilityState(
          isHidden: isHidden,
          hiddenAt: hiddenAt,
          label: 'Conversation visibility',
        );

        if (!isHidden ||
            hiddenAt == null) {
          throw const UserVisibilityRepositoryException(
            'Conversation visibility query returned an invalid hidden row.',
          );
        }

        if (!seenIds.add(
          conversationId,
        )) {
          throw const UserVisibilityRepositoryException(
            'Conversation visibility data contains duplicate rows.',
          );
        }

        if (previousHiddenAt != null &&
            hiddenAt.isAfter(
              previousHiddenAt,
            )) {
          throw const UserVisibilityRepositoryException(
            'Conversation visibility ordering is inconsistent.',
          );
        }

        previousHiddenAt =
            hiddenAt;

        result.add(
          conversationId,
        );
      }

      return List<String>.unmodifiable(
        result,
      );
    } on UserVisibilityRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not load hidden conversations.',
      );
    } catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not load hidden conversations.',
      );
    }
  }

  // ============================================================
  // HIDDEN TIMESTAMP
  //
  // Returns null when:
  // - no visibility row exists, or
  // - the conversation is visible.
  // ============================================================

  Future<DateTime?> getConversationHiddenAt({
    required String conversationId,
    required String userId,
  }) async {
    final String cleanConversationId =
    _requireText(
      conversationId,
      'Conversation ID',
    );

    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    try {
      final Database db =
      await _appDatabase.database;

      final List<Map<String, Object?>> rows =
      await db.query(
        'conversation_user_visibility',
        columns: <String>[
          'is_hidden',
          'hidden_at',
        ],
        where: '''
          conversation_id = ?
          AND user_id = ?
        ''',
        whereArgs: <Object?>[
          cleanConversationId,
          cleanUserId,
        ],
        limit: 1,
      );

      if (rows.isEmpty) {
        return null;
      }

      final Map<String, Object?> row =
          rows.single;

      final bool isHidden =
      _readRequiredBooleanInt(
        row,
        'is_hidden',
        'Conversation visibility',
      );

      final DateTime? hiddenAt =
      _readOptionalDateTime(
        row,
        'hidden_at',
        'Conversation hidden timestamp',
      );

      _validateVisibilityState(
        isHidden: isHidden,
        hiddenAt: hiddenAt,
        label: 'Conversation visibility',
      );

      if (!isHidden) {
        return null;
      }

      if (hiddenAt == null) {
        throw const UserVisibilityRepositoryException(
          'Hidden conversation is missing its archive timestamp.',
        );
      }

      return hiddenAt;
    } on UserVisibilityRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not read conversation archive timestamp.',
      );
    } catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not read conversation archive timestamp.',
      );
    }
  }

  // ============================================================
  // HIDE CONVERSATION
  // ============================================================

  Future<void> hideConversation({
    required String conversationId,
    required String userId,
  }) async {
    final String cleanConversationId =
    _requireText(
      conversationId,
      'Conversation ID',
    );

    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    final DateTime now =
    DateTime.now();

    _validateDateTimeForStorage(
      now,
      'Hidden timestamp',
    );

    try {
      final Database db =
      await _appDatabase.database;

      await db.transaction(
            (
            Transaction txn,
            ) async {
          await _requireUserExists(
            txn,
            cleanUserId,
          );

          await _requireConversationExists(
            txn,
            cleanConversationId,
          );

          final int updatedRows =
          await txn.update(
            'conversation_user_visibility',
            <String, Object?>{
              'is_hidden': 1,
              'hidden_at':
              now.millisecondsSinceEpoch,
            },
            where: '''
              conversation_id = ?
              AND user_id = ?
            ''',
            whereArgs: <Object?>[
              cleanConversationId,
              cleanUserId,
            ],
          );

          if (updatedRows > 1) {
            throw const UserVisibilityRepositoryException(
              'Conversation visibility update affected multiple rows.',
            );
          }

          if (updatedRows == 1) {
            return;
          }

          final int insertedRowId =
          await txn.insert(
            'conversation_user_visibility',
            <String, Object?>{
              'conversation_id':
              cleanConversationId,
              'user_id':
              cleanUserId,
              'is_hidden':
              1,
              'hidden_at':
              now.millisecondsSinceEpoch,
            },
            conflictAlgorithm:
            ConflictAlgorithm.abort,
          );

          if (insertedRowId <= 0) {
            throw const UserVisibilityRepositoryException(
              'Could not hide the conversation.',
            );
          }
        },
      );
    } on UserVisibilityRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not hide the conversation.',
      );
    } catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not hide the conversation.',
      );
    }
  }

  // ============================================================
  // RESTORE CONVERSATION
  // ============================================================

  Future<void> unhideConversation({
    required String conversationId,
    required String userId,
  }) async {
    final String cleanConversationId =
    _requireText(
      conversationId,
      'Conversation ID',
    );

    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    try {
      final Database db =
      await _appDatabase.database;

      await db.transaction(
            (
            Transaction txn,
            ) async {
          await _requireUserExists(
            txn,
            cleanUserId,
          );

          await _requireConversationExists(
            txn,
            cleanConversationId,
          );

          final int updatedRows =
          await txn.update(
            'conversation_user_visibility',
            <String, Object?>{
              'is_hidden': 0,
              'hidden_at': null,
            },
            where: '''
              conversation_id = ?
              AND user_id = ?
            ''',
            whereArgs: <Object?>[
              cleanConversationId,
              cleanUserId,
            ],
          );

          if (updatedRows > 1) {
            throw const UserVisibilityRepositoryException(
              'Conversation visibility update affected multiple rows.',
            );
          }

          // No row means default visibility is already visible.
        },
      );
    } on UserVisibilityRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not restore the conversation.',
      );
    } catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not restore the conversation.',
      );
    }
  }

  // ============================================================
  // SWAP REQUEST VISIBILITY
  // ============================================================

  Future<bool> isSwapRequestHidden({
    required String swapRequestId,
    required String userId,
  }) async {
    final String cleanSwapRequestId =
    _requireText(
      swapRequestId,
      'Swap request ID',
    );

    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    try {
      final Database db =
      await _appDatabase.database;

      final List<Map<String, Object?>> rows =
      await db.query(
        'swap_request_user_visibility',
        columns: <String>[
          'is_hidden',
          'hidden_at',
        ],
        where: '''
          swap_request_id = ?
          AND user_id = ?
        ''',
        whereArgs: <Object?>[
          cleanSwapRequestId,
          cleanUserId,
        ],
        limit: 1,
      );

      if (rows.isEmpty) {
        return false;
      }

      final Map<String, Object?> row =
          rows.first;

      final bool isHidden =
      _readRequiredBooleanInt(
        row,
        'is_hidden',
        'Swap visibility',
      );

      final DateTime? hiddenAt =
      _readOptionalDateTime(
        row,
        'hidden_at',
        'Swap hidden timestamp',
      );

      _validateVisibilityState(
        isHidden: isHidden,
        hiddenAt: hiddenAt,
        label: 'Swap visibility',
      );

      return isHidden;
    } on UserVisibilityRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not read swap visibility.',
      );
    } catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not read swap visibility.',
      );
    }
  }

  Future<Set<String>> getHiddenSwapRequestIds(
      String userId,
      ) async {
    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    try {
      final Database db =
      await _appDatabase.database;

      final List<Map<String, Object?>> rows =
      await db.query(
        'swap_request_user_visibility',
        columns: <String>[
          'swap_request_id',
          'is_hidden',
          'hidden_at',
        ],
        where: '''
          user_id = ?
          AND is_hidden = 1
        ''',
        whereArgs: <Object?>[
          cleanUserId,
        ],
      );

      final Set<String> result =
      <String>{};

      for (final Map<String, Object?> row
      in rows) {
        final String swapRequestId =
        _requireRowString(
          row,
          'swap_request_id',
          'Swap request ID',
        );

        final bool isHidden =
        _readRequiredBooleanInt(
          row,
          'is_hidden',
          'Swap visibility',
        );

        final DateTime? hiddenAt =
        _readOptionalDateTime(
          row,
          'hidden_at',
          'Swap hidden timestamp',
        );

        _validateVisibilityState(
          isHidden: isHidden,
          hiddenAt: hiddenAt,
          label: 'Swap visibility',
        );

        if (!isHidden) {
          throw const UserVisibilityRepositoryException(
            'Swap visibility query returned an unexpected visible row.',
          );
        }

        if (!result.add(
          swapRequestId,
        )) {
          throw const UserVisibilityRepositoryException(
            'Swap visibility data contains duplicate rows.',
          );
        }
      }

      return Set<String>.unmodifiable(
        result,
      );
    } on UserVisibilityRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not load hidden swap requests.',
      );
    } catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not load hidden swap requests.',
      );
    }
  }

  Future<void> hideSwapRequest({
    required String swapRequestId,
    required String userId,
  }) async {
    final String cleanSwapRequestId =
    _requireText(
      swapRequestId,
      'Swap request ID',
    );

    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    final DateTime now =
    DateTime.now();

    _validateDateTimeForStorage(
      now,
      'Hidden timestamp',
    );

    try {
      final Database db =
      await _appDatabase.database;

      await db.transaction(
            (
            Transaction txn,
            ) async {
          await _requireUserExists(
            txn,
            cleanUserId,
          );

          await _requireSwapRequestExists(
            txn,
            cleanSwapRequestId,
          );

          final int updatedRows =
          await txn.update(
            'swap_request_user_visibility',
            <String, Object?>{
              'is_hidden': 1,
              'hidden_at':
              now.millisecondsSinceEpoch,
            },
            where: '''
              swap_request_id = ?
              AND user_id = ?
            ''',
            whereArgs: <Object?>[
              cleanSwapRequestId,
              cleanUserId,
            ],
          );

          if (updatedRows > 1) {
            throw const UserVisibilityRepositoryException(
              'Swap visibility update affected multiple rows.',
            );
          }

          if (updatedRows == 1) {
            return;
          }

          final int insertedRowId =
          await txn.insert(
            'swap_request_user_visibility',
            <String, Object?>{
              'swap_request_id':
              cleanSwapRequestId,
              'user_id':
              cleanUserId,
              'is_hidden':
              1,
              'hidden_at':
              now.millisecondsSinceEpoch,
            },
            conflictAlgorithm:
            ConflictAlgorithm.abort,
          );

          if (insertedRowId <= 0) {
            throw const UserVisibilityRepositoryException(
              'Could not hide the swap request.',
            );
          }
        },
      );
    } on UserVisibilityRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not hide the swap request.',
      );
    } catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not hide the swap request.',
      );
    }
  }

  Future<void> unhideSwapRequest({
    required String swapRequestId,
    required String userId,
  }) async {
    final String cleanSwapRequestId =
    _requireText(
      swapRequestId,
      'Swap request ID',
    );

    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    try {
      final Database db =
      await _appDatabase.database;

      await db.transaction(
            (
            Transaction txn,
            ) async {
          await _requireUserExists(
            txn,
            cleanUserId,
          );

          await _requireSwapRequestExists(
            txn,
            cleanSwapRequestId,
          );

          final int updatedRows =
          await txn.update(
            'swap_request_user_visibility',
            <String, Object?>{
              'is_hidden': 0,
              'hidden_at': null,
            },
            where: '''
              swap_request_id = ?
              AND user_id = ?
            ''',
            whereArgs: <Object?>[
              cleanSwapRequestId,
              cleanUserId,
            ],
          );

          if (updatedRows > 1) {
            throw const UserVisibilityRepositoryException(
              'Swap visibility update affected multiple rows.',
            );
          }

          // Missing row already means visible.
        },
      );
    } on UserVisibilityRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not restore the swap request.',
      );
    } catch (_) {
      throw const UserVisibilityRepositoryException(
        'Could not restore the swap request.',
      );
    }
  }

  // ============================================================
  // RELATIONSHIP CHECKS
  // ============================================================

  Future<void> _requireUserExists(
      Transaction txn,
      String userId,
      ) async {
    final List<Map<String, Object?>> rows =
    await txn.query(
      'users',
      columns: <String>[
        'id',
      ],
      where: 'id = ?',
      whereArgs: <Object?>[
        userId,
      ],
      limit: 1,
    );

    if (rows.length != 1) {
      throw const UserVisibilityRepositoryException(
        'User profile could not be found.',
      );
    }
  }

  Future<void> _requireConversationExists(
      Transaction txn,
      String conversationId,
      ) async {
    final List<Map<String, Object?>> rows =
    await txn.query(
      'conversations',
      columns: <String>[
        'id',
      ],
      where: 'id = ?',
      whereArgs: <Object?>[
        conversationId,
      ],
      limit: 1,
    );

    if (rows.length != 1) {
      throw const UserVisibilityRepositoryException(
        'Conversation could not be found.',
      );
    }
  }

  Future<void> _requireSwapRequestExists(
      Transaction txn,
      String swapRequestId,
      ) async {
    final List<Map<String, Object?>> rows =
    await txn.query(
      'swap_requests',
      columns: <String>[
        'id',
      ],
      where: 'id = ?',
      whereArgs: <Object?>[
        swapRequestId,
      ],
      limit: 1,
    );

    if (rows.length != 1) {
      throw const UserVisibilityRepositoryException(
        'Swap request could not be found.',
      );
    }
  }

  // ============================================================
  // VISIBILITY STATE VALIDATION
  // ============================================================

  void _validateVisibilityState({
    required bool isHidden,
    required DateTime? hiddenAt,
    required String label,
  }) {
    if (isHidden &&
        hiddenAt == null) {
      throw UserVisibilityRepositoryException(
        '$label is inconsistent.',
      );
    }

    if (!isHidden &&
        hiddenAt != null) {
      throw UserVisibilityRepositoryException(
        '$label is inconsistent.',
      );
    }
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
      throw UserVisibilityRepositoryException(
        '$field is required.',
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
      throw UserVisibilityRepositoryException(
        '$label is missing.',
      );
    }

    final Object? value =
    row[key];

    if (value is! String) {
      throw UserVisibilityRepositoryException(
        '$label is invalid.',
      );
    }

    final String clean =
    value.trim();

    if (clean.isEmpty) {
      throw UserVisibilityRepositoryException(
        '$label is required.',
      );
    }

    return clean;
  }

  bool _readRequiredBooleanInt(
      Map<String, Object?> row,
      String key,
      String label,
      ) {
    if (!row.containsKey(
      key,
    )) {
      throw UserVisibilityRepositoryException(
        '$label is missing.',
      );
    }

    final int value =
    _readExactInteger(
      row[key],
      label,
    );

    if (value == 0) {
      return false;
    }

    if (value == 1) {
      return true;
    }

    throw UserVisibilityRepositoryException(
      '$label must be 0 or 1.',
    );
  }

  DateTime? _readOptionalDateTime(
      Map<String, Object?> row,
      String key,
      String label,
      ) {
    if (!row.containsKey(
      key,
    )) {
      throw UserVisibilityRepositoryException(
        '$label is missing.',
      );
    }

    final Object? rawValue =
    row[key];

    if (rawValue == null) {
      return null;
    }

    final int milliseconds =
    _readExactInteger(
      rawValue,
      label,
    );

    if (milliseconds <= 0) {
      throw UserVisibilityRepositoryException(
        '$label is invalid.',
      );
    }

    final DateTime value =
    DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
    );

    if (value.millisecondsSinceEpoch !=
        milliseconds) {
      throw UserVisibilityRepositoryException(
        '$label could not be parsed safely.',
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
        throw UserVisibilityRepositoryException(
          '$label is invalid.',
        );
      }

      return numeric.toInt();
    }

    throw UserVisibilityRepositoryException(
      '$label is invalid.',
    );
  }

  void _validateDateTimeForStorage(
      DateTime value,
      String label,
      ) {
    final int milliseconds =
        value.millisecondsSinceEpoch;

    if (milliseconds <= 0) {
      throw UserVisibilityRepositoryException(
        '$label is invalid.',
      );
    }

    final DateTime roundTrip =
    DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
    );

    if (roundTrip.millisecondsSinceEpoch !=
        milliseconds) {
      throw UserVisibilityRepositoryException(
        '$label could not be stored safely.',
      );
    }
  }
}