import 'package:sqflite/sqflite.dart';

import '../conversation.dart';
import '../database/app_database.dart';
import '../message.dart';
import 'user_visibility_repository.dart';

class ChatRepositoryException implements Exception {
  final String message;

  const ChatRepositoryException(
      this.message,
      );

  @override
  String toString() => message;
}

class ChatRepository {
  final AppDatabase _appDatabase =
      AppDatabase.instance;

  final UserVisibilityRepository
  _visibilityRepository =
      UserVisibilityRepository.instance;

  // ============================================================
  // GET CONVERSATIONS
  //
  // Underlying conversations and messages remain preserved.
  // Visibility is resolved separately for the current user.
  // ============================================================

  Future<List<Conversation>> getAllConversations({
    required String userId,
    bool includeHidden = false,
  }) async {
    final String cleanUserId =
    _requireInputText(
      userId,
      'User ID',
    );

    final List<Conversation> allConversations =
    await _loadAllConversations();

    if (includeHidden) {
      return List<Conversation>.unmodifiable(
        allConversations,
      );
    }

    final Set<String> hiddenConversationIds;

    try {
      hiddenConversationIds =
      await _visibilityRepository
          .getHiddenConversationIds(
        cleanUserId,
      );
    } on UserVisibilityRepositoryException catch (_) {
      throw const ChatRepositoryException(
        'Could not load chat visibility settings.',
      );
    }

    final List<Conversation> visibleConversations =
    allConversations
        .where(
          (
          Conversation conversation,
          ) =>
      !hiddenConversationIds.contains(
        conversation.id,
      ),
    )
        .toList(
      growable: false,
    );

    return List<Conversation>.unmodifiable(
      visibleConversations,
    );
  }

  // ============================================================
  // GET CONVERSATIONS FOR ONE PARTICIPANT
  //
  // Multiple stored conversations may now belong to the same
  // participant. This is intentional because a user may archive
  // an old thread and start a fresh one.
  // ============================================================

  Future<List<Conversation>>
  getConversationsForParticipant({
    required String userId,
    required String participantUserId,
    bool includeHidden = false,
  }) async {
    final String cleanUserId =
    _requireInputText(
      userId,
      'User ID',
    );

    final String cleanParticipantUserId =
    _requireInputText(
      participantUserId,
      'Participant user ID',
    );

    final List<Conversation> allConversations =
    await _loadAllConversations();

    final List<Conversation> participantConversations =
    allConversations
        .where(
          (
          Conversation conversation,
          ) =>
      conversation.participantUserId
          ?.trim() ==
          cleanParticipantUserId,
    )
        .toList(
      growable: false,
    );

    if (includeHidden) {
      return List<Conversation>.unmodifiable(
        participantConversations,
      );
    }

    final Set<String> hiddenConversationIds;

    try {
      hiddenConversationIds =
      await _visibilityRepository
          .getHiddenConversationIds(
        cleanUserId,
      );
    } on UserVisibilityRepositoryException catch (_) {
      throw const ChatRepositoryException(
        'Could not load chat visibility settings.',
      );
    }

    final List<Conversation> visibleConversations =
    participantConversations
        .where(
          (
          Conversation conversation,
          ) =>
      !hiddenConversationIds.contains(
        conversation.id,
      ),
    )
        .toList(
      growable: false,
    );

    return List<Conversation>.unmodifiable(
      visibleConversations,
    );
  }

  // ============================================================
  // GET HIDDEN CONVERSATIONS FOR ONE PARTICIPANT
  //
  // Returned newest-hidden first.
  //
  // This allows the service/UI to offer:
  // - Restore latest archived chat
  // - Start a new chat
  //
  // without guessing which historical thread is the most recent.
  // ============================================================

  Future<List<Conversation>>
  getHiddenConversationsForParticipant({
    required String userId,
    required String participantUserId,
  }) async {
    final String cleanUserId =
    _requireInputText(
      userId,
      'User ID',
    );

    final String cleanParticipantUserId =
    _requireInputText(
      participantUserId,
      'Participant user ID',
    );

    final List<Conversation> allConversations =
    await _loadAllConversations();

    late final List<String> hiddenIdsNewestFirst;

    try {
      hiddenIdsNewestFirst =
      await _visibilityRepository
          .getHiddenConversationIdsNewestFirst(
        cleanUserId,
      );
    } on UserVisibilityRepositoryException catch (_) {
      throw const ChatRepositoryException(
        'Could not load archived conversations.',
      );
    }

    if (hiddenIdsNewestFirst.isEmpty) {
      return const <Conversation>[];
    }

    final Map<String, Conversation>
    conversationsById =
    <String, Conversation>{};

    for (final Conversation conversation
    in allConversations) {
      if (conversationsById.containsKey(
        conversation.id,
      )) {
        throw const ChatRepositoryException(
          'Saved chat data contains duplicate conversation IDs.',
        );
      }

      conversationsById[
      conversation.id
      ] = conversation;
    }

    final List<Conversation> result =
    <Conversation>[];

    for (final String conversationId
    in hiddenIdsNewestFirst) {
      final Conversation? conversation =
      conversationsById[
      conversationId
      ];

      if (conversation == null) {
        throw const ChatRepositoryException(
          'Archived chat visibility points to a missing conversation.',
        );
      }

      final String? participantUserId =
      conversation.participantUserId
          ?.trim();

      if (participantUserId ==
          cleanParticipantUserId) {
        result.add(
          conversation,
        );
      }
    }

    return List<Conversation>.unmodifiable(
      result,
    );
  }

  // ============================================================
  // GET LATEST HIDDEN CONVERSATION FOR PARTICIPANT
  // ============================================================

  Future<Conversation?>
  getLatestHiddenConversationForParticipant({
    required String userId,
    required String participantUserId,
  }) async {
    final List<Conversation> hiddenConversations =
    await getHiddenConversationsForParticipant(
      userId:
      userId,
      participantUserId:
      participantUserId,
    );

    if (hiddenConversations.isEmpty) {
      return null;
    }

    return hiddenConversations.first;
  }

  // ============================================================
  // LOAD ALL CONVERSATIONS
  //
  // Centralized database parsing so every repository query gets
  // the same integrity checks.
  // ============================================================

  Future<List<Conversation>>
  _loadAllConversations() async {
    try {
      final Database db =
      await _appDatabase.database;

      final List<Map<String, Object?>>
      conversationRows =
      await db.query(
        'conversations',
      );

      final List<Map<String, Object?>>
      messageRows =
      await db.query(
        'messages',
        orderBy:
        'conversation_id ASC, sent_at ASC',
      );

      final Set<String> conversationIds =
      <String>{};

      // --------------------------------------------------------
      // VALIDATE CONVERSATION IDS
      // --------------------------------------------------------

      for (final Map<String, Object?> row
      in conversationRows) {
        final String conversationId =
        _requireString(
          row,
          'id',
          'Conversation ID',
        );

        if (!conversationIds.add(
          conversationId,
        )) {
          throw const ChatRepositoryException(
            'Saved chat data contains duplicate conversation IDs.',
          );
        }
      }

      // --------------------------------------------------------
      // GROUP + VALIDATE MESSAGES
      // --------------------------------------------------------

      final Map<String, List<Message>>
      messagesByConversation =
      <String, List<Message>>{};

      final Set<String> messageIds =
      <String>{};

      for (final Map<String, Object?> messageRow
      in messageRows) {
        final String conversationId =
        _requireString(
          messageRow,
          'conversation_id',
          'Message conversation ID',
        );

        if (!conversationIds.contains(
          conversationId,
        )) {
          throw const ChatRepositoryException(
            'Saved chat data contains a message linked to a missing conversation.',
          );
        }

        final String messageId =
        _requireString(
          messageRow,
          'id',
          'Message ID',
        );

        if (!messageIds.add(
          messageId,
        )) {
          throw const ChatRepositoryException(
            'Saved chat data contains duplicate message IDs.',
          );
        }

        final String text =
        _requireString(
          messageRow,
          'text',
          'Message text',
        );

        final String? senderUserId =
        _readOptionalString(
          messageRow,
          'sender_user_id',
          'Message sender',
        );

        final DateTime sentAt =
        _dateTimeFromMilliseconds(
          _requireInt(
            messageRow,
            'sent_at',
            'Message timestamp',
          ),
          'Message timestamp',
        );

        final Message message =
        Message(
          id:
          messageId,
          text:
          text,
          senderUserId:
          senderUserId,
          sentAt:
          sentAt,
        );

        messagesByConversation
            .putIfAbsent(
          conversationId,
              () => <Message>[],
        )
            .add(
          message,
        );
      }

      // --------------------------------------------------------
      // BUILD FULL CONVERSATION COLLECTION
      // --------------------------------------------------------

      final List<Conversation> conversations =
      <Conversation>[];

      for (final Map<String, Object?> row
      in conversationRows) {
        final String conversationId =
        _requireString(
          row,
          'id',
          'Conversation ID',
        );

        final List<Message> messages =
            messagesByConversation[
            conversationId] ??
                const <Message>[];

        conversations.add(
          Conversation(
            id:
            conversationId,
            participantUserId:
            _readOptionalString(
              row,
              'participant_user_id',
              'Conversation participant',
            ),
            userName:
            _requireString(
              row,
              'user_name',
              'Conversation user name',
            ),
            initials:
            _requireString(
              row,
              'initials',
              'Conversation initials',
            ),
            city:
            _requireString(
              row,
              'city',
              'Conversation city',
            ),
            skillWanted:
            _requireString(
              row,
              'skill_wanted',
              'Wanted skill',
            ),
            skillOffered:
            _requireString(
              row,
              'skill_offered',
              'Offered skill',
            ),
            status:
            _requireString(
              row,
              'status',
              'Conversation status',
            ),
            messages:
            List<Message>.unmodifiable(
              messages,
            ),
          ),
        );
      }

      return List<Conversation>.unmodifiable(
        conversations,
      );
    } on ChatRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const ChatRepositoryException(
        'Could not load your conversations.',
      );
    } catch (_) {
      throw const ChatRepositoryException(
        'Could not load your conversations.',
      );
    }
  }

  // ============================================================
  // SAVE CONVERSATION
  //
  // Never use SQLite REPLACE here.
  //
  // REPLACE may perform DELETE + INSERT, which could trigger
  // ON DELETE CASCADE and destroy existing child messages.
  // ============================================================

  Future<void> saveConversation(
      Conversation conversation,
      ) async {
    final String conversationId =
    _requireInputText(
      conversation.id,
      'Conversation ID',
    );

    final String? participantUserId =
    _cleanOptionalInput(
      conversation.participantUserId,
    );

    final String userName =
    _requireInputText(
      conversation.userName,
      'Conversation user name',
    );

    final String initials =
    _requireInputText(
      conversation.initials,
      'Conversation initials',
    );

    final String city =
    _requireInputText(
      conversation.city,
      'Conversation city',
    );

    final String skillWanted =
    _requireInputText(
      conversation.skillWanted,
      'Wanted skill',
    );

    final String skillOffered =
    _requireInputText(
      conversation.skillOffered,
      'Offered skill',
    );

    final String status =
    _requireInputText(
      conversation.status,
      'Conversation status',
    );

    try {
      final Database db =
      await _appDatabase.database;

      final Map<String, Object?> values =
      <String, Object?>{
        'participant_user_id':
        participantUserId,
        'user_name':
        userName,
        'initials':
        initials,
        'city':
        city,
        'skill_wanted':
        skillWanted,
        'skill_offered':
        skillOffered,
        'status':
        status,
      };

      await db.transaction(
            (
            Transaction txn,
            ) async {
          final int updatedRows =
          await txn.update(
            'conversations',
            values,
            where:
            'id = ?',
            whereArgs: <Object?>[
              conversationId,
            ],
          );

          if (updatedRows > 1) {
            throw const ChatRepositoryException(
              'Conversation update affected multiple rows.',
            );
          }

          if (updatedRows == 1) {
            return;
          }

          final int insertedRowId =
          await txn.insert(
            'conversations',
            <String, Object?>{
              'id':
              conversationId,
              ...values,
            },
            conflictAlgorithm:
            ConflictAlgorithm.abort,
          );

          if (insertedRowId <= 0) {
            throw const ChatRepositoryException(
              'Could not save the conversation.',
            );
          }
        },
      );
    } on ChatRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const ChatRepositoryException(
        'Could not save the conversation.',
      );
    } catch (_) {
      throw const ChatRepositoryException(
        'Could not save the conversation.',
      );
    }
  }

  // ============================================================
  // SAVE MESSAGE
  // ============================================================

  Future<void> saveMessage({
    required String conversationId,
    required Message message,
  }) async {
    final String cleanConversationId =
    _requireInputText(
      conversationId,
      'Conversation ID',
    );

    final String cleanMessageId =
    _requireInputText(
      message.id,
      'Message ID',
    );

    final String cleanText =
    _requireInputText(
      message.text,
      'Message text',
    );

    final String? cleanSenderUserId =
    _cleanOptionalInput(
      message.senderUserId,
    );

    final int sentAt =
        message.sentAt
            .millisecondsSinceEpoch;

    if (sentAt <= 0) {
      throw const ChatRepositoryException(
        'Message timestamp is invalid.',
      );
    }

    final DateTime roundTrip =
    DateTime.fromMillisecondsSinceEpoch(
      sentAt,
    );

    if (roundTrip.millisecondsSinceEpoch !=
        sentAt) {
      throw const ChatRepositoryException(
        'Message timestamp could not be stored safely.',
      );
    }

    try {
      final Database db =
      await _appDatabase.database;

      await db.transaction(
            (
            Transaction txn,
            ) async {
          // ----------------------------------------------------
          // PARENT CONVERSATION MUST EXIST
          // ----------------------------------------------------

          final List<Map<String, Object?>>
          conversationRows =
          await txn.query(
            'conversations',
            columns: <String>[
              'id',
            ],
            where:
            'id = ?',
            whereArgs: <Object?>[
              cleanConversationId,
            ],
            limit: 1,
          );

          if (conversationRows.length != 1) {
            throw const ChatRepositoryException(
              'The conversation could not be found.',
            );
          }

          // ----------------------------------------------------
          // MESSAGE IDS ARE STABLE
          // ----------------------------------------------------

          final List<Map<String, Object?>>
          duplicateRows =
          await txn.query(
            'messages',
            columns: <String>[
              'id',
            ],
            where:
            'id = ?',
            whereArgs: <Object?>[
              cleanMessageId,
            ],
            limit: 1,
          );

          if (duplicateRows.isNotEmpty) {
            throw const ChatRepositoryException(
              'A message with this ID already exists.',
            );
          }

          final int insertedRowId =
          await txn.insert(
            'messages',
            <String, Object?>{
              'id':
              cleanMessageId,
              'conversation_id':
              cleanConversationId,
              'text':
              cleanText,
              'sender_user_id':
              cleanSenderUserId,
              'sent_at':
              sentAt,
            },
            conflictAlgorithm:
            ConflictAlgorithm.abort,
          );

          if (insertedRowId <= 0) {
            throw const ChatRepositoryException(
              'Could not save the message.',
            );
          }
        },
      );
    } on ChatRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const ChatRepositoryException(
        'Could not save the message.',
      );
    } catch (_) {
      throw const ChatRepositoryException(
        'Could not save the message.',
      );
    }
  }

  // ============================================================
  // HIDE CONVERSATION FOR ONE USER
  // ============================================================

  Future<void> hideConversation({
    required String conversationId,
    required String userId,
  }) async {
    final String cleanConversationId =
    _requireInputText(
      conversationId,
      'Conversation ID',
    );

    final String cleanUserId =
    _requireInputText(
      userId,
      'User ID',
    );

    try {
      await _visibilityRepository
          .hideConversation(
        conversationId:
        cleanConversationId,
        userId:
        cleanUserId,
      );
    } on UserVisibilityRepositoryException catch (_) {
      throw const ChatRepositoryException(
        'Could not hide the conversation.',
      );
    } catch (_) {
      throw const ChatRepositoryException(
        'Could not hide the conversation.',
      );
    }
  }

  // ============================================================
  // RESTORE HIDDEN CONVERSATION
  // ============================================================

  Future<void> unhideConversation({
    required String conversationId,
    required String userId,
  }) async {
    final String cleanConversationId =
    _requireInputText(
      conversationId,
      'Conversation ID',
    );

    final String cleanUserId =
    _requireInputText(
      userId,
      'User ID',
    );

    try {
      await _visibilityRepository
          .unhideConversation(
        conversationId:
        cleanConversationId,
        userId:
        cleanUserId,
      );
    } on UserVisibilityRepositoryException catch (_) {
      throw const ChatRepositoryException(
        'Could not restore the conversation.',
      );
    } catch (_) {
      throw const ChatRepositoryException(
        'Could not restore the conversation.',
      );
    }
  }

  // ============================================================
  // PERMANENT DELETE
  //
  // Maintenance/data-lifecycle operation only.
  // Normal user-facing removal should always use hideConversation.
  // ============================================================

  Future<void> deleteConversationPermanently(
      String conversationId,
      ) async {
    final String cleanConversationId =
    _requireInputText(
      conversationId,
      'Conversation ID',
    );

    try {
      final Database db =
      await _appDatabase.database;

      final int deletedRows =
      await db.delete(
        'conversations',
        where:
        'id = ?',
        whereArgs: <Object?>[
          cleanConversationId,
        ],
      );

      if (deletedRows == 0) {
        throw const ChatRepositoryException(
          'Conversation could not be found.',
        );
      }

      if (deletedRows != 1) {
        throw ChatRepositoryException(
          'Unexpected number of deleted conversations: '
              '$deletedRows.',
        );
      }
    } on ChatRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const ChatRepositoryException(
        'Could not permanently delete the conversation.',
      );
    } catch (_) {
      throw const ChatRepositoryException(
        'Could not permanently delete the conversation.',
      );
    }
  }

  // ============================================================
  // REQUIRED STRING
  // ============================================================

  String _requireString(
      Map<String, Object?> row,
      String key,
      String label,
      ) {
    if (!row.containsKey(
      key,
    )) {
      throw ChatRepositoryException(
        '$label is missing.',
      );
    }

    final Object? value =
    row[key];

    if (value is! String) {
      throw ChatRepositoryException(
        '$label is invalid.',
      );
    }

    final String clean =
    value.trim();

    if (clean.isEmpty) {
      throw ChatRepositoryException(
        '$label is required.',
      );
    }

    return clean;
  }

  // ============================================================
  // OPTIONAL STRING
  // ============================================================

  String? _readOptionalString(
      Map<String, Object?> row,
      String key,
      String label,
      ) {
    if (!row.containsKey(
      key,
    )) {
      throw ChatRepositoryException(
        '$label is missing.',
      );
    }

    final Object? value =
    row[key];

    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw ChatRepositoryException(
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
  // REQUIRED INTEGER
  // ============================================================

  int _requireInt(
      Map<String, Object?> row,
      String key,
      String label,
      ) {
    if (!row.containsKey(
      key,
    )) {
      throw ChatRepositoryException(
        '$label is missing.',
      );
    }

    final Object? value =
    row[key];

    if (value is int) {
      return value;
    }

    if (value is num) {
      final double number =
      value.toDouble();

      if (!number.isFinite ||
          number !=
              number.truncateToDouble()) {
        throw ChatRepositoryException(
          '$label is invalid.',
        );
      }

      return number.toInt();
    }

    throw ChatRepositoryException(
      '$label is invalid.',
    );
  }

  // ============================================================
  // DATETIME
  // ============================================================

  DateTime _dateTimeFromMilliseconds(
      int milliseconds,
      String label,
      ) {
    if (milliseconds <= 0) {
      throw ChatRepositoryException(
        '$label is invalid.',
      );
    }

    final DateTime value =
    DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
    );

    if (value.millisecondsSinceEpoch !=
        milliseconds) {
      throw ChatRepositoryException(
        '$label could not be parsed safely.',
      );
    }

    return value;
  }

  // ============================================================
  // INPUT TEXT
  // ============================================================

  String _requireInputText(
      String value,
      String label,
      ) {
    final String clean =
    value.trim();

    if (clean.isEmpty) {
      throw ChatRepositoryException(
        '$label is required.',
      );
    }

    return clean;
  }

  String? _cleanOptionalInput(
      String? value,
      ) {
    if (value == null) {
      return null;
    }

    final String clean =
    value.trim();

    if (clean.isEmpty) {
      return null;
    }

    return clean;
  }
}