import 'dart:async';

import '../model/conversation.dart';
import '../model/message.dart';
import '../model/repositories/chat_repository.dart';

class ChatService {
  ChatService._();

  static final ChatService instance =
  ChatService._();

  final ChatRepository _repository =
  ChatRepository();

  final List<Conversation>
  _conversations = [];

  bool _initialized = false;

  List<Conversation>
  get conversations =>
      _conversations;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final savedConversations =
    await _repository
        .getAllConversations();

    if (savedConversations.isEmpty) {
      await _createInitialData();
    } else {
      _conversations
        ..clear()
        ..addAll(
          savedConversations,
        );
    }

    _initialized = true;
  }

  // ============================================================
  // INITIAL SAMPLE CONVERSATION
  // ============================================================

  Future<void>
  _createInitialData() async {
    final DateTime now =
    DateTime.now();

    final alexConversation =
    Conversation(
      id: 'alex-rivera',

      userName:
      'Alex Rivera',

      initials:
      'AR',

      city:
      'Mabalacat City',

      skillWanted:
      'Photography',

      skillOffered:
      'Graphic Design',

      status:
      'Planning',

      messages: [
        Message(
          id: 'alex-initial-1',

          text:
          'Hi! I saw that you offer Photography. I’m interested in learning the basics.',

          isMe:
          true,

          sentAt:
          now.subtract(
            const Duration(
              minutes: 20,
            ),
          ),
        ),

        Message(
          id: 'alex-initial-2',

          text:
          'Sure! I usually start with the practical basics first before going into more advanced topics.',

          isMe:
          false,

          sentAt:
          now.subtract(
            const Duration(
              minutes: 17,
            ),
          ),
        ),
      ],
    );

    _conversations.add(
      alexConversation,
    );

    await _repository
        .saveConversation(
      alexConversation,
    );

    for (final message
    in alexConversation.messages) {
      await _repository.saveMessage(
        conversationId:
        alexConversation.id,

        message:
        message,
      );
    }
  }

  // ============================================================
  // GET OR CREATE CONVERSATION
  // ============================================================

  Conversation
  getOrCreateConversation({
    required String userName,
    required String initials,
    required String city,
    required String skillWanted,
    required String skillOffered,
  }) {
    final String id =
    _createConversationId(
      userName,
    );

    for (final conversation
    in _conversations) {
      if (conversation.id == id) {
        return conversation;
      }
    }

    final newConversation =
    Conversation(
      id: id,

      userName:
      userName,

      initials:
      initials,

      city:
      city,

      skillWanted:
      skillWanted,

      skillOffered:
      skillOffered,

      status:
      'New',

      messages: [],
    );

    _conversations.add(
      newConversation,
    );

    unawaited(
      _repository.saveConversation(
        newConversation,
      ),
    );

    return newConversation;
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  void sendMessage({
    required String conversationId,
    required String text,
  }) {
    final conversation =
    _conversations.firstWhere(
          (conversation) =>
      conversation.id ==
          conversationId,
    );

    final message =
    Message(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),

      text:
      text,

      isMe:
      true,

      sentAt:
      DateTime.now(),
    );

    conversation.messages.add(
      message,
    );

    unawaited(
      _repository.saveMessage(
        conversationId:
        conversationId,

        message:
        message,
      ),
    );
  }

  // ============================================================
  // FIND CONVERSATION
  // ============================================================

  Conversation?
  findConversation(
      String conversationId,
      ) {
    for (final conversation
    in _conversations) {
      if (conversation.id ==
          conversationId) {
        return conversation;
      }
    }

    return null;
  }

  // ============================================================
  // DELETE CONVERSATION
  // ============================================================

  void deleteConversation(
      String conversationId,
      ) {
    _conversations.removeWhere(
          (conversation) =>
      conversation.id ==
          conversationId,
    );

    unawaited(
      _repository.deleteConversation(
        conversationId,
      ),
    );
  }

  // ============================================================
  // CREATE STABLE CONVERSATION ID
  // ============================================================

  String _createConversationId(
      String name,
      ) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(
      RegExp(r'\s+'),
      '-',
    );
  }
}