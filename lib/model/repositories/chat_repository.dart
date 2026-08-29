import 'package:sqflite/sqflite.dart';

import '../conversation.dart';
import '../database/app_database.dart';
import '../message.dart';

class ChatRepository {
  final AppDatabase _appDatabase =
      AppDatabase.instance;

  // ============================================================
  // GET ALL CONVERSATIONS
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

    final List<Conversation>
    conversations = [];

    for (final Map<String, Object?> row
    in conversationRows) {
      final String conversationId =
      row['id'] as String;

      final List<Map<String, Object?>>
      messageRows =
      await db.query(
        'messages',
        where: 'conversation_id = ?',
        whereArgs: [
          conversationId,
        ],
        orderBy: 'sent_at ASC',
      );

      final List<Message> messages =
      messageRows.map(
            (
            Map<String, Object?> messageRow,
            ) {
          return Message(
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
        },
      ).toList();

      conversations.add(
        Conversation(
          id:
          row['id']
          as String,
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
          messages,
        ),
      );
    }

    return conversations;
  }

  // ============================================================
  // SAVE CONVERSATION
  //
  // IMPORTANT:
  // Never use ConflictAlgorithm.replace here.
  //
  // SQLite REPLACE can behave like DELETE + INSERT.
  // Since messages reference conversations with ON DELETE CASCADE,
  // replacing a conversation could unintentionally remove messages.
  //
  // Instead:
  // 1. Try UPDATE using the stable conversation ID.
  // 2. If no row exists, INSERT a new one.
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
          where: 'id = ?',
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
  // Message IDs are treated as stable/immutable identifiers.
  //
  // A duplicate ID should fail instead of replacing an existing
  // message silently.
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
  // ============================================================

  Future<void> deleteConversation(
      String conversationId,
      ) async {
    final String cleanConversationId =
    conversationId.trim();

    if (cleanConversationId.isEmpty) {
      return;
    }

    final Database db =
    await _appDatabase.database;

    await db.delete(
      'conversations',
      where: 'id = ?',
      whereArgs: [
        cleanConversationId,
      ],
    );
  }
}