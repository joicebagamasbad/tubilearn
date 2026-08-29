import 'package:sqflite/sqflite.dart';

import '../conversation.dart';
import '../database/app_database.dart';
import '../message.dart';

class ChatRepository {
  final AppDatabase _appDatabase =
      AppDatabase.instance;

  // ============================================================
  // GET ALL CONVERSATIONS
  //
  // Two bulk queries only:
  // 1. conversations
  // 2. messages
  //
  // Messages are grouped in memory by conversation_id.
  // ============================================================

  Future<List<Conversation>>
  getAllConversations() async {
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

    final Map<String, List<Message>>
    messagesByConversation = {};

    for (final Map<String, Object?> messageRow
    in messageRows) {
      final String conversationId =
      messageRow['conversation_id']
      as String;

      final Message message =
      Message(
        id:
        messageRow['id']
        as String,
        text:
        messageRow['text']
        as String,
        senderUserId:
        messageRow['sender_user_id']
        as String?,
        sentAt:
        DateTime
            .fromMillisecondsSinceEpoch(
          messageRow['sent_at']
          as int,
        ),
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

    final List<Conversation>
    conversations = [];

    for (final Map<String, Object?> row
    in conversationRows) {
      final String conversationId =
      row['id']
      as String;

      conversations.add(
        Conversation(
          id:
          conversationId,
          participantUserId:
          row['participant_user_id']
          as String?,
          userName:
          row['user_name']
          as String,
          initials:
          row['initials']
          as String,
          city:
          row['city']
          as String,
          skillWanted:
          row['skill_wanted']
          as String,
          skillOffered:
          row['skill_offered']
          as String,
          status:
          row['status']
          as String,
          messages:
          messagesByConversation[
          conversationId] ??
              <Message>[],
        ),
      );
    }

    return conversations;
  }

  // ============================================================
  // SAVE CONVERSATION
  //
  // Do not use ConflictAlgorithm.replace.
  //
  // SQLite REPLACE may perform DELETE + INSERT.
  // Because messages use ON DELETE CASCADE, that could remove
  // existing child messages.
  // ============================================================

  Future<void> saveConversation(
      Conversation conversation,
      ) async {
    final String conversationId =
    conversation.id.trim();

    if (conversationId.isEmpty) {
      throw ArgumentError(
        'Conversation ID cannot be empty.',
      );
    }

    final Database db =
    await _appDatabase.database;

    final Map<String, Object?> values = {
      'participant_user_id':
      conversation.participantUserId,
      'user_name':
      conversation.userName,
      'initials':
      conversation.initials,
      'city':
      conversation.city,
      'skill_wanted':
      conversation.skillWanted,
      'skill_offered':
      conversation.skillOffered,
      'status':
      conversation.status,
    };

    await db.transaction(
          (txn) async {
        final int updatedRows =
        await txn.update(
          'conversations',
          values,
          where:
          'id = ?',
          whereArgs: [
            conversationId,
          ],
        );

        if (updatedRows > 0) {
          return;
        }

        await txn.insert(
          'conversations',
          {
            'id':
            conversationId,
            ...values,
          },
          conflictAlgorithm:
          ConflictAlgorithm.abort,
        );
      },
    );
  }

  // ============================================================
  // SAVE MESSAGE
  //
  // Message IDs are stable identifiers.
  // Duplicate IDs fail instead of replacing existing data.
  // ============================================================

  Future<void> saveMessage({
    required String conversationId,
    required Message message,
  }) async {
    final String cleanConversationId =
    conversationId.trim();

    final String cleanMessageId =
    message.id.trim();

    if (cleanConversationId.isEmpty) {
      throw ArgumentError(
        'Conversation ID cannot be empty.',
      );
    }

    if (cleanMessageId.isEmpty) {
      throw ArgumentError(
        'Message ID cannot be empty.',
      );
    }

    final Database db =
    await _appDatabase.database;

    await db.insert(
      'messages',
      {
        'id':
        cleanMessageId,
        'conversation_id':
        cleanConversationId,
        'text':
        message.text,
        'sender_user_id':
        message.senderUserId,
        'sent_at':
        message.sentAt
            .millisecondsSinceEpoch,
      },
      conflictAlgorithm:
      ConflictAlgorithm.abort,
    );
  }

  // ============================================================
  // DELETE CONVERSATION
  //
  // A delete is successful only if one database row was actually
  // removed.
  // ============================================================

  Future<void> deleteConversation(
      String conversationId,
      ) async {
    final String cleanConversationId =
    conversationId.trim();

    if (cleanConversationId.isEmpty) {
      throw ArgumentError(
        'Conversation ID cannot be empty.',
      );
    }

    final Database db =
    await _appDatabase.database;

    final int deletedRows =
    await db.delete(
      'conversations',
      where:
      'id = ?',
      whereArgs: [
        cleanConversationId,
      ],
    );

    if (deletedRows == 0) {
      throw StateError(
        'Conversation does not exist in the database.',
      );
    }

    if (deletedRows > 1) {
      throw StateError(
        'Unexpected number of deleted conversations: $deletedRows.',
      );
    }
  }
}