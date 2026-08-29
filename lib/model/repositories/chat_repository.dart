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
  // ============================================================

  Future<void> saveConversation(
      Conversation conversation,
      ) async {
    final Database db =
    await _appDatabase.database;

    await db.insert(
      'conversations',
      {
        'id':
        conversation.id,
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
      },
      conflictAlgorithm:
      ConflictAlgorithm.replace,
    );
  }

  // ============================================================
  // SAVE MESSAGE
  // ============================================================

  Future<void> saveMessage({
    required String conversationId,
    required Message message,
  }) async {
    final Database db =
    await _appDatabase.database;

    await db.insert(
      'messages',
      {
        'id':
        message.id,
        'conversation_id':
        conversationId,
        'text':
        message.text,
        'sender_user_id':
        message.senderUserId,
        'sent_at':
        message.sentAt
            .millisecondsSinceEpoch,
      },
      conflictAlgorithm:
      ConflictAlgorithm.replace,
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