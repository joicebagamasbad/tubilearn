import '../model/conversation.dart';
import '../model/message.dart';
import '../model/repositories/explore_repository.dart';
import '../model/user.dart';
import '../services/chat_service.dart';
import '../services/current_user_service.dart';

class ChatControllerException implements Exception {
  final String message;

  const ChatControllerException(
      this.message,
      );

  @override
  String toString() => message;
}

// ============================================================
// MANAGED CONVERSATION
// ============================================================

class ManagedConversation {
  final Conversation conversation;
  final User? participant;

  const ManagedConversation({
    required this.conversation,
    required this.participant,
  });
}

// ============================================================
// CHAT LIST SNAPSHOT
// ============================================================

class ChatListSnapshot {
  final List<ManagedConversation> conversations;

  const ChatListSnapshot({
    required this.conversations,
  });
}

// ============================================================
// SINGLE CONVERSATION SNAPSHOT
// ============================================================

class ConversationSnapshot {
  final Conversation conversation;
  final User? participant;

  const ConversationSnapshot({
    required this.conversation,
    required this.participant,
  });
}

// ============================================================
// CONTROLLER
// ============================================================

class ChatController {
  final ChatService _chatService;
  final ExploreRepository _exploreRepository;
  final CurrentUserService _currentUserService;

  ChatController({
    ChatService? chatService,
    ExploreRepository? exploreRepository,
    CurrentUserService? currentUserService,
  })  : _chatService =
      chatService ??
          ChatService.instance,
        _exploreRepository =
            exploreRepository ??
                ExploreRepository.instance,
        _currentUserService =
            currentUserService ??
                CurrentUserService.instance;

  // ============================================================
  // LOAD CHAT LIST
  // ============================================================

  Future<ChatListSnapshot>
  loadConversations() async {
    try {
      await _exploreRepository.initialize();

      await _chatService.initialize();

      return _buildChatListSnapshot();
    } on ChatServiceException catch (error) {
      throw ChatControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw ChatControllerException(
        error.message,
      );
    } catch (_) {
      throw const ChatControllerException(
        'Messages could not be loaded. Please try again.',
      );
    }
  }

  // ============================================================
  // REFRESH CHAT LIST
  // ============================================================

  Future<ChatListSnapshot>
  refreshConversations() async {
    try {
      try {
        await _exploreRepository.refresh();
      } catch (_) {
        // Chat data can still be shown even if
        // reference profile refresh fails.
      }

      await _chatService.initialize();

      return _buildChatListSnapshot();
    } on ChatServiceException catch (error) {
      throw ChatControllerException(
        error.message,
      );
    } catch (_) {
      throw const ChatControllerException(
        'Messages could not be refreshed. Please try again.',
      );
    }
  }

  // ============================================================
  // CURRENT CHAT LIST
  // ============================================================

  ChatListSnapshot currentChatList() {
    try {
      return _buildChatListSnapshot();
    } catch (_) {
      throw const ChatControllerException(
        'Messages could not be prepared.',
      );
    }
  }

  // ============================================================
  // SEARCH / FILTER
  // ============================================================

  List<ManagedConversation>
  filterConversations({
    required List<ManagedConversation>
    conversations,
    required String query,
  }) {
    final String cleanQuery =
    query
        .trim()
        .toLowerCase();

    if (cleanQuery.isEmpty) {
      return List<ManagedConversation>.of(
        conversations,
        growable: false,
      );
    }

    return conversations.where(
          (
          ManagedConversation managed,
          ) {
        final Conversation conversation =
            managed.conversation;

        return conversation.userName
            .toLowerCase()
            .contains(
          cleanQuery,
        ) ||
            conversation.city
                .toLowerCase()
                .contains(
              cleanQuery,
            ) ||
            conversation.skillWanted
                .toLowerCase()
                .contains(
              cleanQuery,
            ) ||
            conversation.skillOffered
                .toLowerCase()
                .contains(
              cleanQuery,
            ) ||
            conversation.status
                .toLowerCase()
                .contains(
              cleanQuery,
            );
      },
    ).toList(
      growable: false,
    );
  }

  // ============================================================
  // LOAD SINGLE CONVERSATION
  // ============================================================

  Future<ConversationSnapshot>
  loadConversation(
      String conversationId,
      ) async {
    final String cleanConversationId =
    conversationId.trim();

    if (cleanConversationId.isEmpty) {
      throw const ChatControllerException(
        'Conversation ID is required.',
      );
    }

    try {
      await _exploreRepository.initialize();

      await _chatService.initialize();

      return _buildConversationSnapshot(
        cleanConversationId,
      );
    } on ChatServiceException catch (error) {
      throw ChatControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw ChatControllerException(
        error.message,
      );
    } catch (_) {
      throw const ChatControllerException(
        'Conversation could not be loaded. Please try again.',
      );
    }
  }

  // ============================================================
  // CURRENT SINGLE CONVERSATION
  // ============================================================

  ConversationSnapshot currentConversation(
      String conversationId,
      ) {
    final String cleanConversationId =
    conversationId.trim();

    if (cleanConversationId.isEmpty) {
      throw const ChatControllerException(
        'Conversation ID is required.',
      );
    }

    return _buildConversationSnapshot(
      cleanConversationId,
    );
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<ConversationSnapshot> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final String cleanConversationId =
    conversationId.trim();

    final String cleanText =
    text.trim();

    if (cleanConversationId.isEmpty) {
      throw const ChatControllerException(
        'Conversation ID is required.',
      );
    }

    if (cleanText.isEmpty) {
      throw const ChatControllerException(
        'Message cannot be empty.',
      );
    }

    try {
      await _chatService.sendMessage(
        conversationId:
        cleanConversationId,
        text:
        cleanText,
      );

      return _buildConversationSnapshot(
        cleanConversationId,
      );
    } on ChatServiceException catch (error) {
      throw ChatControllerException(
        error.message,
      );
    } catch (_) {
      throw const ChatControllerException(
        'Message could not be sent. Please try again.',
      );
    }
  }

  // ============================================================
  // ARCHIVE
  // ============================================================

  Future<ChatListSnapshot>
  archiveConversation(
      String conversationId,
      ) async {
    final String cleanConversationId =
    conversationId.trim();

    if (cleanConversationId.isEmpty) {
      throw const ChatControllerException(
        'Conversation ID is required.',
      );
    }

    try {
      await _chatService.deleteConversation(
        cleanConversationId,
      );

      return _buildChatListSnapshot();
    } on ChatServiceException catch (error) {
      throw ChatControllerException(
        error.message,
      );
    } catch (_) {
      throw const ChatControllerException(
        'Conversation could not be archived. Please try again.',
      );
    }
  }

  // ============================================================
  // MESSAGE OWNERSHIP
  // ============================================================

  bool isMessageMine(
      Message message,
      ) {
    try {
      final String currentUserId =
          _currentUserService.userId;

      return message.isSentBy(
        currentUserId,
      );
    } on CurrentUserServiceException catch (error) {
      throw ChatControllerException(
        error.message,
      );
    } catch (_) {
      throw const ChatControllerException(
        'Current user could not be identified.',
      );
    }
  }

  // ============================================================
  // PARTICIPANT
  // ============================================================

  User? participantFor(
      Conversation conversation,
      ) {
    final String? participantUserId =
    conversation.participantUserId
        ?.trim();

    if (participantUserId == null ||
        participantUserId.isEmpty) {
      return null;
    }

    return _exploreRepository.findUserById(
      participantUserId,
    );
  }

  // ============================================================
  // PRIVATE - CHAT LIST
  // ============================================================

  ChatListSnapshot
  _buildChatListSnapshot() {
    final List<ManagedConversation>
    managed =
    _chatService.conversations
        .map(
          (
          Conversation conversation,
          ) {
        return ManagedConversation(
          conversation:
          conversation,
          participant:
          participantFor(
            conversation,
          ),
        );
      },
    )
        .toList();

    managed.sort(
          (
          ManagedConversation first,
          ManagedConversation second,
          ) {
        final DateTime firstTime =
        _latestMessageTime(
          first.conversation,
        );

        final DateTime secondTime =
        _latestMessageTime(
          second.conversation,
        );

        return secondTime.compareTo(
          firstTime,
        );
      },
    );

    return ChatListSnapshot(
      conversations:
      List<ManagedConversation>.unmodifiable(
        managed,
      ),
    );
  }

  // ============================================================
  // PRIVATE - SINGLE CONVERSATION
  // ============================================================

  ConversationSnapshot
  _buildConversationSnapshot(
      String conversationId,
      ) {
    final Conversation? conversation =
    _chatService.findConversation(
      conversationId,
    );

    if (conversation == null) {
      throw const ChatControllerException(
        'This conversation is no longer available.',
      );
    }

    return ConversationSnapshot(
      conversation:
      conversation,
      participant:
      participantFor(
        conversation,
      ),
    );
  }

  // ============================================================
  // PRIVATE - LATEST MESSAGE
  // ============================================================

  DateTime _latestMessageTime(
      Conversation conversation,
      ) {
    if (conversation.messages.isEmpty) {
      return DateTime
          .fromMillisecondsSinceEpoch(
        0,
      );
    }

    return conversation
        .messages
        .last
        .sentAt;
  }
}