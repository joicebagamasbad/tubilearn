import '../model/conversation.dart';
import '../model/message.dart';
import '../model/repositories/chat_repository.dart';
import '../model/repositories/explore_repository.dart';
import '../model/user.dart';
import 'current_user_service.dart';

class ChatServiceException implements Exception {
  final String message;

  const ChatServiceException(this.message);

  @override
  String toString() => message;
}

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  final ChatRepository _repository = ChatRepository();
  final ExploreRepository _exploreRepository = ExploreRepository.instance;
  final CurrentUserService _currentUserService = CurrentUserService.instance;

  final List<Conversation> _conversations = [];

  static const int _maxUserNameLength = 80;
  static const int _maxInitialsLength = 10;
  static const int _maxCityLength = 120;
  static const int _maxSkillNameLength = 80;
  static const int _maxStatusLength = 40;
  static const int _maxMessageLength = 2000;

  Future<void>? _initializingFuture;

  final Map<String, Future<Conversation>>
  _pendingConversationCreations = {};

  final Map<String, Future<void>>
  _pendingConversationDeletions = {};

  final Map<String, Future<void>>
  _pendingMessageSends = {};

  final Map<String, Future<Conversation>>
  _pendingConversationMetadataWrites = {};

  int _lastMessageIdMicros = 0;
  bool _initialized = false;

  List<Conversation> get conversations =>
      List.unmodifiable(_conversations);

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final pendingInitialization = _initializingFuture;

    if (pendingInitialization != null) {
      await pendingInitialization;
      return;
    }

    final Future<void> initialization = _initializeInternal();

    _initializingFuture = initialization;

    try {
      await initialization;
    } finally {
      if (identical(
        _initializingFuture,
        initialization,
      )) {
        _initializingFuture = null;
      }
    }
  }

  Future<void> _initializeInternal() async {
    final List<Conversation> savedConversations =
    await _repository.getAllConversations();

    if (savedConversations.isEmpty) {
      await _createInitialData();
      _syncMessageIdCounterFromLoadedData(
        _conversations,
      );
    } else {
      _validateLoadedConversations(
        savedConversations,
      );

      _syncMessageIdCounterFromLoadedData(
        savedConversations,
      );

      _conversations
        ..clear()
        ..addAll(savedConversations);
    }

    _initialized = true;
  }

  // ============================================================
  // STORED DATA VALIDATION
  // ============================================================

  void _validateLoadedConversations(
      List<Conversation> conversations,
      ) {
    final Set<String> conversationIds = <String>{};
    final Set<String> stableParticipants = <String>{};
    final Set<String> messageIds = <String>{};

    for (final Conversation conversation in conversations) {
      final String conversationId = _requireStoredText(
        conversation.id,
        'Stored conversation ID',
      );

      if (!conversationIds.add(conversationId)) {
        throw const ChatServiceException(
          'Duplicate stored conversation IDs were found.',
        );
      }

      _validateStoredTextWithLimit(
        conversation.userName,
        'Stored user name',
        _maxUserNameLength,
      );

      _validateStoredTextWithLimit(
        conversation.initials,
        'Stored initials',
        _maxInitialsLength,
      );

      _validateStoredTextWithLimit(
        conversation.city,
        'Stored city',
        _maxCityLength,
      );

      _validateStoredTextWithLimit(
        conversation.skillWanted,
        'Stored wanted skill',
        _maxSkillNameLength,
      );

      _validateStoredTextWithLimit(
        conversation.skillOffered,
        'Stored offered skill',
        _maxSkillNameLength,
      );

      _validateStoredTextWithLimit(
        conversation.status,
        'Stored conversation status',
        _maxStatusLength,
      );

      final String? participantUserId =
      conversation.participantUserId?.trim();

      if (participantUserId != null &&
          participantUserId.isNotEmpty) {
        if (participantUserId ==
            _currentUserService.userId) {
          throw const ChatServiceException(
            'Stored conversation cannot point to the current user.',
          );
        }

        if (_exploreRepository.findUserById(
          participantUserId,
        ) ==
            null) {
          throw const ChatServiceException(
            'Stored conversation points to an unavailable user.',
          );
        }

        if (!stableParticipants.add(
          participantUserId,
        )) {
          throw const ChatServiceException(
            'Duplicate conversations were found for the same user.',
          );
        }
      }

      DateTime? previousMessageTime;

      for (final Message message in conversation.messages) {
        final String messageId = _requireStoredText(
          message.id,
          'Stored message ID',
        );

        if (!messageIds.add(messageId)) {
          throw const ChatServiceException(
            'Duplicate stored message IDs were found.',
          );
        }

        _validateStoredTextWithLimit(
          message.text,
          'Stored message',
          _maxMessageLength,
        );

        final String? senderUserId =
        message.senderUserId?.trim();

        if (senderUserId != null &&
            senderUserId.isNotEmpty) {
          final bool isCurrentUser =
              senderUserId ==
                  _currentUserService.userId;

          final bool isParticipant =
              participantUserId != null &&
                  senderUserId ==
                      participantUserId;

          if (!isCurrentUser &&
              !isParticipant) {
            throw const ChatServiceException(
              'Stored message has an invalid sender.',
            );
          }
        }

        if (previousMessageTime != null &&
            message.sentAt.isBefore(
              previousMessageTime,
            )) {
          throw const ChatServiceException(
            'Stored messages are not in chronological order.',
          );
        }

        previousMessageTime = message.sentAt;
      }
    }
  }

  // ============================================================
  // MESSAGE ID COUNTER RESTORE
  // ============================================================

  void _syncMessageIdCounterFromLoadedData(
      List<Conversation> conversations,
      ) {
    int highest = _lastMessageIdMicros;

    for (final Conversation conversation in conversations) {
      for (final Message message in conversation.messages) {
        final int sentMicros =
            message.sentAt.microsecondsSinceEpoch;

        if (sentMicros > highest) {
          highest = sentMicros;
        }

        final String id = message.id.trim();

        if (!id.startsWith('message_')) {
          continue;
        }

        final int lastUnderscore =
        id.lastIndexOf('_');

        if (lastUnderscore < 0 ||
            lastUnderscore ==
                id.length - 1) {
          continue;
        }

        final int? storedCounter =
        int.tryParse(
          id.substring(
            lastUnderscore + 1,
          ),
        );

        if (storedCounter != null &&
            storedCounter > highest) {
          highest = storedCounter;
        }
      }
    }

    _lastMessageIdMicros = highest;
  }

  // ============================================================
  // INITIAL DATA
  // ============================================================

  Future<void> _createInitialData() async {
    final DateTime now = DateTime.now();

    final Conversation alexConversation =
    Conversation(
      id: _createConversationIdForUser(
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
          id: 'alex-initial-1',
          text:
          'Hi! I saw that you offer Photography. I’m interested in learning the basics.',
          senderUserId:
          _currentUserService.userId,
          sentAt: now.subtract(
            const Duration(
              minutes: 20,
            ),
          ),
        ),
        Message(
          id: 'alex-initial-2',
          text:
          'Sure! I usually start with the practical basics first before going into more advanced topics.',
          senderUserId:
          'user_alex_rivera',
          sentAt: now.subtract(
            const Duration(
              minutes: 17,
            ),
          ),
        ),
      ],
    );

    bool conversationSaved = false;

    try {
      await _repository.saveConversation(
        alexConversation,
      );

      conversationSaved = true;

      for (final Message message
      in alexConversation.messages) {
        await _repository.saveMessage(
          conversationId:
          alexConversation.id,
          message:
          message,
        );
      }
    } catch (_) {
      if (conversationSaved) {
        try {
          await _repository.deleteConversation(
            alexConversation.id,
          );
        } catch (_) {
          // Cleanup is best-effort.
        }
      }

      throw const ChatServiceException(
        'Initial chat data could not be created. Please try again.',
      );
    }

    _conversations.add(
      alexConversation,
    );
  }

  // ============================================================
  // GET / CREATE
  // ============================================================

  Future<Conversation> getOrCreateConversation({
    required String userId,
    required String userName,
    required String initials,
    required String city,
    required String skillWanted,
    required String skillOffered,
  }) async {
    await initialize();

    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    if (cleanUserId ==
        _currentUserService.userId) {
      throw const ChatServiceException(
        'You cannot start a conversation with yourself.',
      );
    }

    _requireTextWithLimit(
      userName,
      'User name',
      _maxUserNameLength,
    );

    _requireTextWithLimit(
      initials,
      'Initials',
      _maxInitialsLength,
    );

    _requireTextWithLimit(
      city,
      'City',
      _maxCityLength,
    );

    final String cleanSkillWanted =
    _requireTextWithLimit(
      skillWanted,
      'Wanted skill',
      _maxSkillNameLength,
    );

    final String cleanSkillOffered =
    _requireTextWithLimit(
      skillOffered,
      'Offered skill',
      _maxSkillNameLength,
    );

    final User? participant =
    _exploreRepository.findUserById(
      cleanUserId,
    );

    if (participant == null) {
      throw const ChatServiceException(
        'Chat participant could not be found.',
      );
    }

    final String canonicalUserName =
    _requireTextWithLimit(
      participant.name,
      'User name',
      _maxUserNameLength,
    );

    final String canonicalInitials =
    _requireTextWithLimit(
      participant.initials,
      'Initials',
      _maxInitialsLength,
    );

    final String canonicalCity =
    _requireTextWithLimit(
      participant.city,
      'City',
      _maxCityLength,
    );

    final Conversation? existingConversation =
    findConversationByUserId(
      cleanUserId,
    );

    if (existingConversation != null) {
      final Future<void>? pendingDeletion =
      _pendingConversationDeletions[
      existingConversation.id];

      if (pendingDeletion != null) {
        try {
          await pendingDeletion;
        } catch (_) {
          throw const ChatServiceException(
            'Conversation is currently unavailable. Please try again.',
          );
        }

        final Conversation? afterDeletion =
        findConversationByUserId(
          cleanUserId,
        );

        if (afterDeletion != null) {
          return _refreshConversationProfile(
            conversation:
            afterDeletion,
            participant:
            participant,
          );
        }
      } else {
        return _refreshConversationProfile(
          conversation:
          existingConversation,
          participant:
          participant,
        );
      }
    }

    final Future<Conversation>? pendingCreation =
    _pendingConversationCreations[
    cleanUserId];

    if (pendingCreation != null) {
      return pendingCreation;
    }

    final Future<Conversation> creation =
    _createConversationInternal(
      userId:
      cleanUserId,
      userName:
      canonicalUserName,
      initials:
      canonicalInitials,
      city:
      canonicalCity,
      skillWanted:
      cleanSkillWanted,
      skillOffered:
      cleanSkillOffered,
      participant:
      participant,
    );

    _pendingConversationCreations[
    cleanUserId] = creation;

    try {
      return await creation;
    } finally {
      if (identical(
        _pendingConversationCreations[
        cleanUserId],
        creation,
      )) {
        _pendingConversationCreations.remove(
          cleanUserId,
        );
      }
    }
  }

  Future<Conversation>
  _createConversationInternal({
    required String userId,
    required String userName,
    required String initials,
    required String city,
    required String skillWanted,
    required String skillOffered,
    required User participant,
  }) async {
    final List<Conversation> legacyMatches =
    _conversations.where(
          (
          Conversation conversation,
          ) {
        if (conversation.participantUserId !=
            null) {
          return false;
        }

        return conversation.userName
            .trim()
            .toLowerCase() ==
            userName.toLowerCase();
      },
    ).toList();

    if (legacyMatches.length > 1) {
      throw const ChatServiceException(
        'Multiple legacy conversations match this user. Automatic migration is unsafe.',
      );
    }

    if (legacyMatches.length == 1) {
      final Conversation legacy =
          legacyMatches.single;

      final Future<void>? pendingDeletion =
      _pendingConversationDeletions[
      legacy.id];

      if (pendingDeletion != null) {
        try {
          await pendingDeletion;
        } catch (_) {
          throw const ChatServiceException(
            'Conversation is currently unavailable. Please try again.',
          );
        }
      } else {
        return _adoptLegacyConversation(
          legacyConversation:
          legacy,
          participant:
          participant,
        );
      }
    }

    final Conversation? existingConversation =
    findConversationByUserId(
      userId,
    );

    if (existingConversation != null) {
      return _refreshConversationProfile(
        conversation:
        existingConversation,
        participant:
        participant,
      );
    }

    final String conversationId =
    _createConversationIdForUser(
      userId,
    );

    final Future<void>? pendingDeletion =
    _pendingConversationDeletions[
    conversationId];

    if (pendingDeletion != null) {
      try {
        await pendingDeletion;
      } catch (_) {
        throw const ChatServiceException(
          'Conversation is currently unavailable. Please try again.',
        );
      }
    }

    final Conversation? afterDeletion =
    findConversationByUserId(
      userId,
    );

    if (afterDeletion != null) {
      return _refreshConversationProfile(
        conversation:
        afterDeletion,
        participant:
        participant,
      );
    }

    final Conversation newConversation =
    Conversation(
      id:
      conversationId,
      participantUserId:
      userId,
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

    final Conversation? conversationAfterSave =
    findConversationByUserId(
      userId,
    );

    if (conversationAfterSave != null) {
      return conversationAfterSave;
    }

    _conversations.add(
      newConversation,
    );

    return newConversation;
  }

  // ============================================================
  // PROFILE REFRESH
  // ============================================================

  Future<Conversation> _refreshConversationProfile({
    required Conversation conversation,
    required User participant,
  }) async {
    return _runMetadataWrite(
      conversationId:
      conversation.id,
      operation: () async {
        _throwIfConversationDeleting(
          conversation.id,
        );

        final Conversation current =
            findConversation(
              conversation.id,
            ) ??
                conversation;

        final String canonicalName =
        _requireTextWithLimit(
          participant.name,
          'User name',
          _maxUserNameLength,
        );

        final String canonicalInitials =
        _requireTextWithLimit(
          participant.initials,
          'Initials',
          _maxInitialsLength,
        );

        final String canonicalCity =
        _requireTextWithLimit(
          participant.city,
          'City',
          _maxCityLength,
        );

        final bool alreadyCurrent =
            current.userName ==
                canonicalName &&
                current.initials ==
                    canonicalInitials &&
                current.city ==
                    canonicalCity;

        if (alreadyCurrent) {
          return current;
        }

        final Conversation refreshed =
        Conversation(
          id:
          current.id,
          participantUserId:
          current.participantUserId,
          userName:
          canonicalName,
          initials:
          canonicalInitials,
          city:
          canonicalCity,
          skillWanted:
          current.skillWanted,
          skillOffered:
          current.skillOffered,
          status:
          current.status,
          messages:
          current.messages,
        );

        _throwIfConversationDeleting(
          current.id,
        );

        try {
          await _repository.saveConversation(
            refreshed,
          );
        } catch (_) {
          throw const ChatServiceException(
            'Conversation profile could not be refreshed.',
          );
        }

        _replaceConversationInMemory(
          refreshed,
        );

        return refreshed;
      },
    );
  }

  // ============================================================
  // LEGACY ADOPTION
  // ============================================================

  Future<Conversation> _adoptLegacyConversation({
    required Conversation legacyConversation,
    required User participant,
  }) async {
    return _runMetadataWrite(
      conversationId:
      legacyConversation.id,
      operation: () async {
        _throwIfConversationDeleting(
          legacyConversation.id,
        );

        final Conversation current =
            findConversation(
              legacyConversation.id,
            ) ??
                legacyConversation;

        if (current.participantUserId !=
            null &&
            current.participantUserId!
                .trim()
                .isNotEmpty) {
          return current;
        }

        final Conversation adopted =
        Conversation(
          id:
          current.id,
          participantUserId:
          participant.id,
          userName:
          _requireTextWithLimit(
            participant.name,
            'User name',
            _maxUserNameLength,
          ),
          initials:
          _requireTextWithLimit(
            participant.initials,
            'Initials',
            _maxInitialsLength,
          ),
          city:
          _requireTextWithLimit(
            participant.city,
            'City',
            _maxCityLength,
          ),
          skillWanted:
          current.skillWanted,
          skillOffered:
          current.skillOffered,
          status:
          current.status,
          messages:
          current.messages,
        );

        _throwIfConversationDeleting(
          current.id,
        );

        try {
          await _repository.saveConversation(
            adopted,
          );
        } catch (_) {
          throw const ChatServiceException(
            'Legacy conversation could not be upgraded safely.',
          );
        }

        _replaceConversationInMemory(
          adopted,
        );

        return adopted;
      },
    );
  }

  Future<Conversation> _runMetadataWrite({
    required String conversationId,
    required Future<Conversation> Function()
    operation,
  }) async {
    while (true) {
      final Future<Conversation>? pending =
      _pendingConversationMetadataWrites[
      conversationId];

      if (pending == null) {
        break;
      }

      try {
        await pending;
      } catch (_) {
        // The previous caller receives its own error.
      }

      _throwIfConversationDeleting(
        conversationId,
      );
    }

    _throwIfConversationDeleting(
      conversationId,
    );

    final Future<Conversation> write =
    operation();

    _pendingConversationMetadataWrites[
    conversationId] = write;

    try {
      return await write;
    } finally {
      if (identical(
        _pendingConversationMetadataWrites[
        conversationId],
        write,
      )) {
        _pendingConversationMetadataWrites.remove(
          conversationId,
        );
      }
    }
  }

  void _replaceConversationInMemory(
      Conversation replacement,
      ) {
    final int index =
    _conversations.indexWhere(
          (
          Conversation conversation,
          ) =>
      conversation.id ==
          replacement.id,
    );

    if (index >= 0) {
      _conversations[index] =
          replacement;
      return;
    }

    _conversations.add(
      replacement,
    );
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    await initialize();

    final String cleanConversationId =
    _requireText(
      conversationId,
      'Conversation ID',
    );

    final String cleanText =
    _requireTextWithLimit(
      text,
      'Message',
      _maxMessageLength,
    );

    _throwIfConversationDeleting(
      cleanConversationId,
    );

    while (true) {
      final Future<void>? pendingSend =
      _pendingMessageSends[
      cleanConversationId];

      if (pendingSend == null) {
        break;
      }

      try {
        await pendingSend;
      } catch (_) {
        // Previous caller handles its own persistence failure.
      }

      _throwIfConversationDeleting(
        cleanConversationId,
      );
    }

    final Future<void> sendOperation =
    _sendMessageInternal(
      conversationId:
      cleanConversationId,
      text:
      cleanText,
    );

    _pendingMessageSends[
    cleanConversationId] =
        sendOperation;

    try {
      await sendOperation;
    } finally {
      if (identical(
        _pendingMessageSends[
        cleanConversationId],
        sendOperation,
      )) {
        _pendingMessageSends.remove(
          cleanConversationId,
        );
      }
    }
  }

  Future<void> _sendMessageInternal({
    required String conversationId,
    required String text,
  }) async {
    _throwIfConversationDeleting(
      conversationId,
    );

    final Conversation? conversation =
    findConversation(
      conversationId,
    );

    if (conversation == null) {
      throw const ChatServiceException(
        'Conversation not found.',
      );
    }

    final String? participantUserId =
    conversation.participantUserId
        ?.trim();

    if (participantUserId == null ||
        participantUserId.isEmpty) {
      throw const ChatServiceException(
        'This conversation needs a verified participant before messaging.',
      );
    }

    if (participantUserId ==
        _currentUserService.userId) {
      throw const ChatServiceException(
        'You cannot send messages to yourself.',
      );
    }

    if (_exploreRepository.findUserById(
      participantUserId,
    ) ==
        null) {
      throw const ChatServiceException(
        'Chat participant is no longer available.',
      );
    }

    final DateTime now = DateTime.now();

    final Message message = Message(
      id:
      _createMessageId(),
      text:
      text,
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
        conversationId,
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
  // FIND
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
      final String? participantUserId =
      conversation.participantUserId
          ?.trim();

      if (participantUserId ==
          cleanUserId) {
        return conversation;
      }
    }

    return null;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteConversation(
      String conversationId,
      ) async {
    await initialize();

    final String cleanConversationId =
    _requireText(
      conversationId,
      'Conversation ID',
    );

    final Future<void>? pendingDeletion =
    _pendingConversationDeletions[
    cleanConversationId];

    if (pendingDeletion != null) {
      await pendingDeletion;
      return;
    }

    await _waitForPendingCreationForConversation(
      cleanConversationId,
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

    late final Future<void> deletion;

    deletion =
        _deleteConversationInternal(
          cleanConversationId,
        );

    _pendingConversationDeletions[
    cleanConversationId] =
        deletion;

    try {
      await deletion;
    } finally {
      if (identical(
        _pendingConversationDeletions[
        cleanConversationId],
        deletion,
      )) {
        _pendingConversationDeletions.remove(
          cleanConversationId,
        );
      }
    }
  }

  Future<void> _waitForPendingCreationForConversation(
      String conversationId,
      ) async {
    const String prefix = 'conversation_';

    if (!conversationId.startsWith(prefix)) {
      return;
    }

    final String userId =
    conversationId.substring(
      prefix.length,
    );

    if (userId.isEmpty) {
      return;
    }

    final Future<Conversation>? pendingCreation =
    _pendingConversationCreations[
    userId];

    if (pendingCreation == null) {
      return;
    }

    try {
      await pendingCreation;
    } catch (_) {
      // The create caller receives the original failure.
      // Delete will perform its normal existence check afterward.
    }
  }

  Future<void> _deleteConversationInternal(
      String conversationId,
      ) async {
    final Future<void>? pendingSend =
    _pendingMessageSends[
    conversationId];

    if (pendingSend != null) {
      try {
        await pendingSend;
      } catch (_) {
        // Failed send already rolls back from memory.
      }
    }

    final Future<Conversation>? pendingMetadataWrite =
    _pendingConversationMetadataWrites[
    conversationId];

    if (pendingMetadataWrite != null) {
      try {
        await pendingMetadataWrite;
      } catch (_) {
        // Failed metadata writes leave persisted conversation intact.
      }
    }

    try {
      await _repository.deleteConversation(
        conversationId,
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
          conversationId,
    );
  }

  void _throwIfConversationDeleting(
      String conversationId,
      ) {
    if (_pendingConversationDeletions
        .containsKey(
      conversationId,
    )) {
      throw const ChatServiceException(
        'This conversation is being deleted.',
      );
    }
  }

  // ============================================================
  // IDS
  // ============================================================

  String _createConversationIdForUser(
      String userId,
      ) {
    return 'conversation_$userId';
  }

  String _createMessageId() {
    int candidate =
        DateTime.now()
            .microsecondsSinceEpoch;

    if (candidate <=
        _lastMessageIdMicros) {
      candidate =
          _lastMessageIdMicros + 1;
    }

    _lastMessageIdMicros = candidate;

    return 'message_${_currentUserService.userId}_$candidate';
  }

  // ============================================================
  // INPUT VALIDATION
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

  String _requireTextWithLimit(
      String value,
      String fieldName,
      int maxLength,
      ) {
    final String cleaned =
    _requireText(
      value,
      fieldName,
    );

    if (cleaned.length > maxLength) {
      throw ChatServiceException(
        '$fieldName must be $maxLength characters or fewer.',
      );
    }

    return cleaned;
  }

  String _requireStoredText(
      String value,
      String fieldName,
      ) {
    final String cleaned =
    value.trim();

    if (cleaned.isEmpty) {
      throw ChatServiceException(
        '$fieldName is invalid.',
      );
    }

    return cleaned;
  }

  void _validateStoredTextWithLimit(
      String value,
      String fieldName,
      int maxLength,
      ) {
    final String cleaned =
    _requireStoredText(
      value,
      fieldName,
    );

    if (cleaned.length > maxLength) {
      throw ChatServiceException(
        '$fieldName exceeds the allowed length.',
      );
    }
  }
}