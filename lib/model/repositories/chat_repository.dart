import 'package:sqflite/sqflite.dart';

import '../conversation.dart';
import '../message.dart';
import '../database/app_database.dart';

class ChatRepository {
  final AppDatabase _appDatabase =
      AppDatabase.instance;

  Future<List<Conversation>> getAllConversations() async {
    final db = await _appDatabase.database;

    final conversationRows = await db.query(
      'conversations',
    );

    final List<Conversation> conversations = [];

    for (final row in conversationRows) {
      final String conversationId =
      row['id'] as String;

      final messageRows = await db.query(
        'messages',
        where: 'conversation_id = ?',
        whereArgs: [
          conversationId,
        ],
        orderBy: 'sent_at ASC',
      );

      final messages = messageRows.map(
            (messageRow) {
          return Message(
            id: messageRow['id'] as String,
            text: messageRow['text'] as String,
            isMe:
            (messageRow['is_me'] as int) == 1,
            sentAt:
            DateTime.fromMillisecondsSinceEpoch(
              messageRow['sent_at'] as int,
            ),
          );
        },
      ).toList();

      conversations.add(
        Conversation(
          id: row['id'] as String,
          userName: row['user_name'] as String,
          initials: row['initials'] as String,
          city: row['city'] as String,
          skillWanted:
          row['skill_wanted'] as String,
          skillOffered:
          row['skill_offered'] as String,
          status: row['status'] as String,
          messages: messages,
        ),
      );
    }

    return conversations;
  }

  Future<void> saveConversation(
      Conversation conversation,
      ) async {
    final db = await _appDatabase.database;

    await db.insert(
      'conversations',
      {
        'id': conversation.id,
        'user_name': conversation.userName,
        'initials': conversation.initials,
        'city': conversation.city,
        'skill_wanted': conversation.skillWanted,
        'skill_offered': conversation.skillOffered,
        'status': conversation.status,
      },
      conflictAlgorithm:
      ConflictAlgorithm.replace,
    );
  }

  Future<void> saveMessage({
    required String conversationId,
    required Message message,
  }) async {
    final db = await _appDatabase.database;

    await db.insert(
      'messages',
      {
        'id': message.id,
        'conversation_id': conversationId,
        'text': message.text,
        'is_me': message.isMe ? 1 : 0,
        'sent_at':
        message.sentAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm:
      ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteConversation(
      String conversationId,
      ) async {
    final db = await _appDatabase.database;

    await db.delete(
      'conversations',
      where: 'id = ?',
      whereArgs: [
        conversationId,
      ],
    );
  }
}