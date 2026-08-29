import '../model/conversation.dart';
import '../model/message.dart';
import '../model/repositories/chat_repository.dart';
import '../model/repositories/explore_repository.dart';
import '../model/user.dart';
import 'current_user_service.dart';

class ChatServiceException implements Exception {
  final String message;

  const ChatServiceException(
      this.message,
      );

  @override
  String toString() => message;
}

class ChatService {
  ChatService._();

  static final ChatService instance =
  ChatService._();

  final ChatRepository _repository =
  ChatRepository();

  final ExploreRepository _exploreRepository =
      ExploreRepository.instance;

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  final List<Conversation> _conversations = [];

  bool _initialized = false;

  List<Conversation> get conversations =>
      List.unmodifiable(
        _conversations,
      );

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final List<Conversation> savedConversations =
    await _repository.getAllConversations();

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

  Future<void> _createInitialData() async {
    final DateTime now =
    DateTime.now();

    final Conversation alexConversation =
    Conversation(
      id:
      _createConversationIdForUser(
        'user_alex_rivera',
      ),
      participantUserId:
      'user_alex_rivera',
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
          id:
          'alex-initial-1',
          text:
          'Hi! I saw that you offer Photography. I’m interested in learning the basics.',
          senderUserId:
          _currentUserService.userId,
          sentAt:
          now.subtract(
            const Duration(
              minutes:
              20,
            ),
          ),
        ),
        Message(
          id:
          'alex-initial-2',
          text:
          'Sure! I usually start with the practical basics first before going into more advanced topics.',
          senderUserId:
          'user_alex_rivera',
          sentAt:
          now.subtract(
            const Duration(
              minutes:
              17,
            ),
          ),
        ),
      ],
    );

    await _repository.saveConversation(
      alexConversation,
    );

    for (final Message message
    in alexConversation.messages) {
      await _repository.saveMessage(
        conversationId:
        alexConversation.id,
        message:
        message,
      );
    }

    _conversations.add(
      alexConversation,
    );
  }

  // ============================================================
  // GET OR CREATE CONVERSATION
  // ============================================================

  Future<Conversation> getOrCreateConversation({
    String? userId,
    required String userName,
    required String initials,
    required String city,
    required String skillWanted,
    required String skillOffered,
  }) async {
    final String cleanUserName =
    _requireText(
      userName,
      'User name',
    );

    final String cleanInitials =
    _requireText(
      initials,
      'Initials',
    );

    final String cleanCity =
    _requireText(
      city,
      'City',
    );

    final String cleanSkillWanted =
    _requireText(
      skillWanted,
      'Wanted skill',
    );

    final String cleanSkillOffered =
    _requireText(
      skillOffered,
      'Offered skill',
    );

    final String? stableUserId =
    _resolveStableUserId(
      userId:
      userId,
      userName:
      cleanUserName,
    );

    if (stableUserId != null) {
      for (final Conversation conversation
      in _conversations) {
        if (conversation.participantUserId ==
            stableUserId) {
          return conversation;
        }
      }
    }

    for (final Conversation conversation
    in _conversations) {
      if (conversation.participantUserId !=
          null) {
        continue;
      }

      if (conversation.userName
          .trim()
          .toLowerCase() ==
          cleanUserName.toLowerCase()) {
        return conversation;
      }
    }

    final String conversationId =
    stableUserId != null
        ? _createConversationIdForUser(
      stableUserId,
    )
        : _createLegacyConversationId(
      cleanUserName,
    );

    final Conversation newConversation =
    Conversation(
      id:
      conversationId,
      participantUserId:
      stableUserId,
      userName:
      cleanUserName,
      initials:
      cleanInitials,
      city:
      cleanCity,
      skillWanted:
      cleanSkillWanted,
      skillOffered:
      cleanSkillOffered,
      status:
      'New',
      messages:
      [],
    );

    try {
      await _repository.saveConversation(
        newConversation,
      );
    } catch (_) {
      throw const ChatServiceException(
        'Conversation could not be created. Please try again.',
      );
    }

    _conversations.add(
      newConversation,
    );

    return newConversation;
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final String cleanConversationId =
    _requireText(
      conversationId,
      'Conversation ID',
    );

    final String cleanText =
    _requireText(
      text,
      'Message',
    );

    final Conversation? conversation =
    findConversation(
      cleanConversationId,
    );

    if (conversation == null) {
      throw const ChatServiceException(
        'Conversation not found.',
      );
    }

    final DateTime now =
    DateTime.now();

    final Message message =
    Message(
      id:
      now.microsecondsSinceEpoch
          .toString(),
      text:
      cleanText,
      senderUserId:
      _currentUserService.userId,
      sentAt:
      now,
    );

    conversation.messages.add(
      message,
    );

    try {
      await _repository.saveMessage(
        conversationId:
        cleanConversationId,
        message:
        message,
      );
    } catch (_) {
      conversation.messages.removeWhere(
            (
            Message existingMessage,
            ) =>
        existingMessage.id ==
            message.id,
      );

      throw const ChatServiceException(
        'Message could not be saved. Please try again.',
      );
    }
  }

  // ============================================================
  // FIND CONVERSATION
  // ============================================================

  Conversation? findConversation(
      String conversationId,
      ) {
    final String cleanConversationId =
    conversationId.trim();

    if (cleanConversationId.isEmpty) {
      return null;
    }

    for (final Conversation conversation
    in _conversations) {
      if (conversation.id ==
          cleanConversationId) {
        return conversation;
      }
    }

    return null;
  }

  // ============================================================
  // FIND BY PARTICIPANT
  // ============================================================

  Conversation? findConversationByUserId(
      String userId,
      ) {
    final String cleanUserId =
    userId.trim();

    if (cleanUserId.isEmpty) {
      return null;
    }

    for (final Conversation conversation
    in _conversations) {
      if (conversation.participantUserId ==
          cleanUserId) {
        return conversation;
      }
    }

    return null;
  }

  // ============================================================
  // DELETE CONVERSATION
  //
  // Database deletion is awaited BEFORE removing the conversation
  // from memory.
  //
  // If persistence fails, the conversation remains visible and
  // the caller receives an error instead of silently losing sync.
  // ============================================================

  Future<void> deleteConversation(
      String conversationId,
      ) async {
    final String cleanConversationId =
    _requireText(
      conversationId,
      'Conversation ID',
    );

    final Conversation? conversation =
    findConversation(
      cleanConversationId,
    );

    if (conversation == null) {
      throw const ChatServiceException(
        'Conversation not found.',
      );
    }

    try {
      await _repository.deleteConversation(
        cleanConversationId,
      );
    } catch (_) {
      throw const ChatServiceException(
        'Conversation could not be deleted. Please try again.',
      );
    }

    _conversations.removeWhere(
          (
          Conversation existingConversation,
          ) =>
      existingConversation.id ==
          cleanConversationId,
    );
  }

  // ============================================================
  // RESOLVE STABLE USER ID
  // ============================================================

  String? _resolveStableUserId({
    required String? userId,
    required String userName,
  }) {
    final String? cleanUserId =
    _cleanNullableText(
      userId,
    );

    if (cleanUserId != null) {
      final User? user =
      _exploreRepository.findUserById(
        cleanUserId,
      );

      if (user == null) {
        throw const ChatServiceException(
          'Chat participant could not be found.',
        );
      }

      return user.id;
    }

    final String normalizedName =
    userName
        .trim()
        .toLowerCase();

    User? matchedUser;

    for (final User user
    in _exploreRepository.users) {
      if (user.name
          .trim()
          .toLowerCase() !=
          normalizedName) {
        continue;
      }

      if (matchedUser != null) {
        return null;
      }

      matchedUser =
          user;
    }

    return matchedUser?.id;
  }

  // ============================================================
  // CONVERSATION IDS
  // ============================================================

  String _createConversationIdForUser(
      String userId,
      ) {
    return 'conversation_$userId';
  }

  String _createLegacyConversationId(
      String name,
      ) {
    return 'legacy_${name.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      '-',
    )}';
  }

  // ============================================================
  // TEXT VALIDATION
  // ============================================================

  String _requireText(
      String value,
      String fieldName,
      ) {
    final String cleaned =
    value.trim();

    if (cleaned.isEmpty) {
      throw ChatServiceException(
        '$fieldName is required.',
      );
    }

    return cleaned;
  }

  String? _cleanNullableText(
      String? value,
      ) {
    if (value == null) {
      return null;
    }

    final String cleaned =
    value.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    return cleaned;
  }
}