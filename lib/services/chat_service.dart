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

class HiddenConversationException
    extends ChatServiceException {
  final String conversationId;
  final String participantUserId;

  const HiddenConversationException({
    required this.conversationId,
    required this.participantUserId,
  }) : super(
    'You previously removed this conversation.',
  );
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

  final List<Conversation> _conversations =
  <Conversation>[];

  static const int _maxUserNameLength = 80;
  static const int _maxInitialsLength = 10;
  static const int _maxCityLength = 120;
  static const int _maxSkillNameLength = 80;
  static const int _maxStatusLength = 40;
  static const int _maxMessageLength = 2000;

  Future<void>? _initializingFuture;

  final Map<String, Future<Conversation>>
  _pendingConversationCreations =
  <String, Future<Conversation>>{};

  final Map<String, Future<void>>
  _pendingConversationHides =
  <String, Future<void>>{};

  final Map<String, Future<void>>
  _pendingMessageSends =
  <String, Future<void>>{};

  final Map<String, Future<Conversation>>
  _pendingConversationMetadataWrites =
  <String, Future<Conversation>>{};

  int _lastMessageIdMicros = 0;
  int _lastConversationIdMicros = 0;

  bool _initialized = false;

  List<Conversation> get conversations =>
      List<Conversation>.unmodifiable(
        _conversations,
      );

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final Future<void>? pendingInitialization =
        _initializingFuture;

    if (pendingInitialization != null) {
      await pendingInitialization;
      return;
    }

    final Future<void> initialization =
    _initializeInternal();

    _initializingFuture =
        initialization;

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
    try {
      await _exploreRepository.refresh();
    } on ExploreRepositoryException catch (_) {
      throw const ChatServiceException(
        'Chat reference data could not be loaded. Please try again.',
      );
    } catch (_) {
      throw const ChatServiceException(
        'Chat reference data could not be loaded. Please try again.',
      );
    }

    final String currentUserId =
    _requireCurrentUserId();

    late final List<Conversation>
    allConversations;

    late final List<Conversation>
    visibleConversations;

    try {
      allConversations =
      await _repository.getAllConversations(
        userId: currentUserId,
        includeHidden: true,
      );

      visibleConversations =
      await _repository.getAllConversations(
        userId: currentUserId,
      );
    } on ChatRepositoryException catch (_) {
      throw const ChatServiceException(
        'Your conversations could not be loaded. Please try again.',
      );
    } catch (_) {
      throw const ChatServiceException(
        'Your conversations could not be loaded. Please try again.',
      );
    }

    // ----------------------------------------------------------
    // BRAND-NEW DATABASE ONLY
    //
    // Empty visible chats does NOT mean there are no chats.
    // Everything may simply be archived.
    // ----------------------------------------------------------

    if (allConversations.isEmpty) {
      _conversations.clear();

      await _createInitialData();

      _syncMessageIdCounterFromLoadedData(
        _conversations,
      );

      _syncConversationIdCounterFromLoadedData(
        _conversations,
      );

      _initialized = true;
      return;
    }

    // ----------------------------------------------------------
    // ALL STORED HISTORY
    //
    // Multiple archived threads for the same participant are
    // valid.
    // ----------------------------------------------------------

    _validateLoadedConversations(
      allConversations,
      requireUniqueParticipants: false,
    );

    // ----------------------------------------------------------
    // VISIBLE THREADS
    //
    // There may only be one visible/current conversation with
    // the same participant.
    // ----------------------------------------------------------

    _validateLoadedConversations(
      visibleConversations,
      requireUniqueParticipants: true,
    );

    _syncMessageIdCounterFromLoadedData(
      allConversations,
    );

    _syncConversationIdCounterFromLoadedData(
      allConversations,
    );

    final List<Conversation> mutableCopies =
    visibleConversations
        .map(
      _mutableConversationCopy,
    )
        .toList(
      growable: false,
    );

    _conversations
      ..clear()
      ..addAll(
        mutableCopies,
      );

    _initialized = true;
  }

  // ============================================================
  // STORED DATA VALIDATION
  // ============================================================

  void _validateLoadedConversations(
      List<Conversation> conversations, {
        required bool requireUniqueParticipants,
      }) {
    final Set<String> conversationIds =
    <String>{};

    final Set<String> stableParticipants =
    <String>{};

    final Set<String> messageIds =
    <String>{};

    final String currentUserId =
    _requireCurrentUserId();

    for (final Conversation conversation
    in conversations) {
      final String conversationId =
      _requireStoredText(
        conversation.id,
        'Stored conversation ID',
      );

      if (!conversationIds.add(
        conversationId,
      )) {
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
      _cleanOptionalText(
        conversation.participantUserId,
      );

      if (participantUserId != null) {
        if (participantUserId ==
            currentUserId) {
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

        if (requireUniqueParticipants &&
            !stableParticipants.add(
              participantUserId,
            )) {
          throw const ChatServiceException(
            'Multiple visible conversations were found for the same user.',
          );
        }

        if (!requireUniqueParticipants) {
          stableParticipants.add(
            participantUserId,
          );
        }
      }

      DateTime? previousMessageTime;

      for (final Message message
      in conversation.messages) {
        final String messageId =
        _requireStoredText(
          message.id,
          'Stored message ID',
        );

        if (!messageIds.add(
          messageId,
        )) {
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
        _cleanOptionalText(
          message.senderUserId,
        );

        if (senderUserId != null) {
          final bool isCurrentUser =
              senderUserId ==
                  currentUserId;

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

        if (message.sentAt
            .millisecondsSinceEpoch <=
            0) {
          throw const ChatServiceException(
            'Stored message has an invalid timestamp.',
          );
        }

        if (previousMessageTime != null &&
            message.sentAt.isBefore(
              previousMessageTime,
            )) {
          throw const ChatServiceException(
            'Stored messages are not in chronological order.',
          );
        }

        previousMessageTime =
            message.sentAt;
      }
    }
  }

  // ============================================================
  // MUTABLE COPY
  // ============================================================

  Conversation _mutableConversationCopy(
      Conversation conversation,
      ) {
    return Conversation(
      id: conversation.id,
      participantUserId:
      conversation.participantUserId,
      userName:
      conversation.userName,
      initials:
      conversation.initials,
      city:
      conversation.city,
      skillWanted:
      conversation.skillWanted,
      skillOffered:
      conversation.skillOffered,
      status:
      conversation.status,
      messages:
      List<Message>.of(
        conversation.messages,
        growable: true,
      ),
    );
  }

  // ============================================================
  // MESSAGE ID COUNTER
  // ============================================================

  void _syncMessageIdCounterFromLoadedData(
      List<Conversation> conversations,
      ) {
    int highest =
        _lastMessageIdMicros;

    for (final Conversation conversation
    in conversations) {
      for (final Message message
      in conversation.messages) {
        final int sentMicros =
            message.sentAt
                .microsecondsSinceEpoch;

        if (sentMicros > highest) {
          highest =
              sentMicros;
        }

        final String id =
        message.id.trim();

        final int lastUnderscore =
        id.lastIndexOf(
          '_',
        );

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
          highest =
              storedCounter;
        }
      }
    }

    _lastMessageIdMicros =
        highest;
  }

  // ============================================================
  // CONVERSATION ID COUNTER
  // ============================================================

  void _syncConversationIdCounterFromLoadedData(
      List<Conversation> conversations,
      ) {
    int highest =
        _lastConversationIdMicros;

    for (final Conversation conversation
    in conversations) {
      final String id =
      conversation.id.trim();

      final int lastUnderscore =
      id.lastIndexOf(
        '_',
      );

      if (lastUnderscore < 0 ||
          lastUnderscore ==
              id.length - 1) {
        continue;
      }

      final int? suffix =
      int.tryParse(
        id.substring(
          lastUnderscore + 1,
        ),
      );

      if (suffix != null &&
          suffix > highest) {
        highest =
            suffix;
      }
    }

    _lastConversationIdMicros =
        highest;
  }

  // ============================================================
  // INITIAL DATA
  // ============================================================

  Future<void> _createInitialData() async {
    final String currentUserId =
    _requireCurrentUserId();

    final User? alex =
    _exploreRepository.findUserById(
      'user_alex_rivera',
    );

    if (alex == null) {
      throw const ChatServiceException(
        'Initial chat participant could not be found.',
      );
    }

    final DateTime now =
    DateTime.now();

    final Conversation alexConversation =
    Conversation(
      id:
      _createLegacyConversationIdForUser(
        alex.id,
      ),
      participantUserId:
      alex.id,
      userName:
      alex.name,
      initials:
      alex.initials,
      city:
      alex.city,
      skillWanted:
      'Photography',
      skillOffered:
      'Graphic Design',
      status:
      'Planning',
      messages:
      <Message>[
        Message(
          id:
          'alex-initial-1',
          text:
          'Hi! I saw that you offer Photography. I’m interested in learning the basics.',
          senderUserId:
          currentUserId,
          sentAt:
          now.subtract(
            const Duration(
              minutes: 20,
            ),
          ),
        ),
        Message(
          id:
          'alex-initial-2',
          text:
          'Sure! I usually start with the practical basics first before going into more advanced topics.',
          senderUserId:
          alex.id,
          sentAt:
          now.subtract(
            const Duration(
              minutes: 17,
            ),
          ),
        ),
      ],
    );

    bool conversationSaved =
    false;

    try {
      await _repository.saveConversation(
        alexConversation,
      );

      conversationSaved =
      true;

      for (final Message message
      in alexConversation.messages) {
        await _repository.saveMessage(
          conversationId:
          alexConversation.id,
          message:
          message,
        );
      }
    } on ChatRepositoryException catch (_) {
      if (conversationSaved) {
        try {
          await _repository
              .deleteConversationPermanently(
            alexConversation.id,
          );
        } catch (_) {}
      }

      throw const ChatServiceException(
        'Initial chat data could not be created. Please try again.',
      );
    } catch (_) {
      if (conversationSaved) {
        try {
          await _repository
              .deleteConversationPermanently(
            alexConversation.id,
          );
        } catch (_) {}
      }

      throw const ChatServiceException(
        'Initial chat data could not be created. Please try again.',
      );
    }

    _conversations.add(
      _mutableConversationCopy(
        alexConversation,
      ),
    );
  }

  // ============================================================
  // GET OR CREATE
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

    final _ValidatedParticipantInput input =
    _validateParticipantInput(
      userId: userId,
      userName: userName,
      initials: initials,
      city: city,
      skillWanted: skillWanted,
      skillOffered: skillOffered,
    );

    final Conversation? existingConversation =
    findConversationByUserId(
      input.userId,
    );

    if (existingConversation != null) {
      return _refreshConversationProfile(
        conversation:
        existingConversation,
        participant:
        input.participant,
      );
    }

    final Conversation? latestHidden =
    await _findLatestHiddenConversationForUser(
      input.userId,
    );

    if (latestHidden != null) {
      throw HiddenConversationException(
        conversationId:
        latestHidden.id,
        participantUserId:
        input.userId,
      );
    }

    return _runParticipantCreation(
      participantUserId:
      input.userId,
      operation:
          () {
        return _createConversationInternal(
          input:
          input,
          useFreshUniqueId:
          false,
        );
      },
    );
  }

  // ============================================================
  // START NEW CONVERSATION
  //
  // Used only after the user explicitly chooses "Start new chat"
  // instead of restoring archived history.
  // ============================================================

  Future<Conversation> startNewConversation({
    required String userId,
    required String userName,
    required String initials,
    required String city,
    required String skillWanted,
    required String skillOffered,
  }) async {
    await initialize();

    final _ValidatedParticipantInput input =
    _validateParticipantInput(
      userId: userId,
      userName: userName,
      initials: initials,
      city: city,
      skillWanted: skillWanted,
      skillOffered: skillOffered,
    );

    final Conversation? visible =
    findConversationByUserId(
      input.userId,
    );

    if (visible != null) {
      return _refreshConversationProfile(
        conversation:
        visible,
        participant:
        input.participant,
      );
    }

    return _runParticipantCreation(
      participantUserId:
      input.userId,
      operation:
          () {
        return _createConversationInternal(
          input:
          input,
          useFreshUniqueId:
          true,
        );
      },
    );
  }

  // ============================================================
  // PARTICIPANT INPUT
  // ============================================================

  _ValidatedParticipantInput _validateParticipantInput({
    required String userId,
    required String userName,
    required String initials,
    required String city,
    required String skillWanted,
    required String skillOffered,
  }) {
    final String currentUserId =
    _requireCurrentUserId();

    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    if (cleanUserId ==
        currentUserId) {
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

    return _ValidatedParticipantInput(
      userId:
      cleanUserId,
      participant:
      participant,
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
      cleanSkillWanted,
      skillOffered:
      cleanSkillOffered,
    );
  }

  // ============================================================
  // SERIALIZE CREATION PER PARTICIPANT
  // ============================================================

  Future<Conversation> _runParticipantCreation({
    required String participantUserId,
    required Future<Conversation> Function()
    operation,
  }) async {
    final Future<Conversation>? pending =
    _pendingConversationCreations[
    participantUserId
    ];

    if (pending != null) {
      return pending;
    }

    final Future<Conversation> creation =
    operation();

    _pendingConversationCreations[
    participantUserId
    ] = creation;

    try {
      return await creation;
    } finally {
      if (identical(
        _pendingConversationCreations[
        participantUserId
        ],
        creation,
      )) {
        _pendingConversationCreations.remove(
          participantUserId,
        );
      }
    }
  }

  // ============================================================
  // LATEST HIDDEN THREAD
  // ============================================================

  Future<Conversation?>
  _findLatestHiddenConversationForUser(
      String participantUserId,
      ) async {
    final String currentUserId =
    _requireCurrentUserId();

    try {
      return await _repository
          .getLatestHiddenConversationForParticipant(
        userId:
        currentUserId,
        participantUserId:
        participantUserId,
      );
    } on ChatRepositoryException catch (_) {
      throw const ChatServiceException(
        'Conversation history could not be checked.',
      );
    } catch (_) {
      throw const ChatServiceException(
        'Conversation history could not be checked.',
      );
    }
  }

  // ============================================================
  // CREATE INTERNAL
  // ============================================================

  Future<Conversation> _createConversationInternal({
    required _ValidatedParticipantInput input,
    required bool useFreshUniqueId,
  }) async {
    final Conversation? visible =
    findConversationByUserId(
      input.userId,
    );

    if (visible != null) {
      return _refreshConversationProfile(
        conversation:
        visible,
        participant:
        input.participant,
      );
    }

    // ----------------------------------------------------------
    // LEGACY ADOPTION
    //
    // Only applies when creating the first/current thread.
    // A deliberate "Start New Chat" must never adopt an old
    // legacy thread.
    // ----------------------------------------------------------

    if (!useFreshUniqueId) {
      final List<Conversation> legacyMatches =
      _conversations.where(
            (
            Conversation conversation,
            ) {
          final String? participantId =
          _cleanOptionalText(
            conversation.participantUserId,
          );

          if (participantId != null) {
            return false;
          }

          return conversation.userName
              .trim()
              .toLowerCase() ==
              input.userName
                  .trim()
                  .toLowerCase();
        },
      ).toList(
        growable: false,
      );

      if (legacyMatches.length > 1) {
        throw const ChatServiceException(
          'Multiple legacy conversations match this user. Automatic migration is unsafe.',
        );
      }

      if (legacyMatches.length == 1) {
        return _adoptLegacyConversation(
          legacyConversation:
          legacyMatches.single,
          participant:
          input.participant,
        );
      }
    }

    final String conversationId =
    useFreshUniqueId
        ? await _createFreshConversationId(
      input.userId,
    )
        : _createLegacyConversationIdForUser(
      input.userId,
    );

    final Conversation newConversation =
    Conversation(
      id:
      conversationId,
      participantUserId:
      input.userId,
      userName:
      input.userName,
      initials:
      input.initials,
      city:
      input.city,
      skillWanted:
      input.skillWanted,
      skillOffered:
      input.skillOffered,
      status:
      'New',
      messages:
      <Message>[],
    );

    try {
      await _repository.saveConversation(
        newConversation,
      );
    } on ChatRepositoryException catch (_) {
      throw const ChatServiceException(
        'Conversation could not be created. Please try again.',
      );
    } catch (_) {
      throw const ChatServiceException(
        'Conversation could not be created. Please try again.',
      );
    }

    final Conversation mutable =
    _mutableConversationCopy(
      newConversation,
    );

    _replaceConversationInMemory(
      mutable,
    );

    return mutable;
  }

  // ============================================================
  // FRESH UNIQUE CONVERSATION ID
  // ============================================================

  Future<String> _createFreshConversationId(
      String userId,
      ) async {
    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    final String currentUserId =
    _requireCurrentUserId();

    late final List<Conversation>
    allConversations;

    try {
      allConversations =
      await _repository.getAllConversations(
        userId:
        currentUserId,
        includeHidden:
        true,
      );
    } on ChatRepositoryException catch (_) {
      throw const ChatServiceException(
        'Conversation history could not be checked before creating a new chat.',
      );
    }

    final Set<String> existingIds =
    allConversations
        .map(
          (
          Conversation conversation,
          ) =>
      conversation.id,
    )
        .toSet();

    while (true) {
      int candidate =
          DateTime.now()
              .microsecondsSinceEpoch;

      if (candidate <=
          _lastConversationIdMicros) {
        candidate =
            _lastConversationIdMicros + 1;
      }

      _lastConversationIdMicros =
          candidate;

      final String id =
          'conversation_${cleanUserId}_$candidate';

      if (!existingIds.contains(
        id,
      )) {
        return id;
      }
    }
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
      operation:
          () async {
        _throwIfConversationHiding(
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
          List<Message>.of(
            current.messages,
            growable: true,
          ),
        );

        try {
          await _repository.saveConversation(
            refreshed,
          );
        } on ChatRepositoryException catch (_) {
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
      operation:
          () async {
        final Conversation current =
            findConversation(
              legacyConversation.id,
            ) ??
                legacyConversation;

        final String? existingParticipant =
        _cleanOptionalText(
          current.participantUserId,
        );

        if (existingParticipant != null) {
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
          List<Message>.of(
            current.messages,
            growable: true,
          ),
        );

        try {
          await _repository.saveConversation(
            adopted,
          );
        } on ChatRepositoryException catch (_) {
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

  // ============================================================
  // SERIALIZED METADATA WRITE
  // ============================================================

  Future<Conversation> _runMetadataWrite({
    required String conversationId,
    required Future<Conversation> Function()
    operation,
  }) async {
    while (true) {
      final Future<Conversation>? pending =
      _pendingConversationMetadataWrites[
      conversationId
      ];

      if (pending == null) {
        break;
      }

      try {
        await pending;
      } catch (_) {}

      _throwIfConversationHiding(
        conversationId,
      );
    }

    _throwIfConversationHiding(
      conversationId,
    );

    final Future<Conversation> write =
    operation();

    _pendingConversationMetadataWrites[
    conversationId
    ] = write;

    try {
      return await write;
    } finally {
      if (identical(
        _pendingConversationMetadataWrites[
        conversationId
        ],
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
    final String? participantId =
    _cleanOptionalText(
      replacement.participantUserId,
    );

    if (participantId != null) {
      _conversations.removeWhere(
            (
            Conversation conversation,
            ) =>
        conversation.id !=
            replacement.id &&
            _cleanOptionalText(
              conversation.participantUserId,
            ) ==
                participantId,
      );
    }

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

    _throwIfConversationHiding(
      cleanConversationId,
    );

    while (true) {
      final Future<void>? pendingSend =
      _pendingMessageSends[
      cleanConversationId
      ];

      if (pendingSend == null) {
        break;
      }

      try {
        await pendingSend;
      } catch (_) {}

      _throwIfConversationHiding(
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
    cleanConversationId
    ] = sendOperation;

    try {
      await sendOperation;
    } finally {
      if (identical(
        _pendingMessageSends[
        cleanConversationId
        ],
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
    _throwIfConversationHiding(
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
    _cleanOptionalText(
      conversation.participantUserId,
    );

    if (participantUserId == null) {
      throw const ChatServiceException(
        'This conversation needs a verified participant before messaging.',
      );
    }

    final String currentUserId =
    _requireCurrentUserId();

    if (participantUserId ==
        currentUserId) {
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

    final Message message =
    Message(
      id:
      _createMessageId(),
      text:
      text,
      senderUserId:
      currentUserId,
      sentAt:
      DateTime.now(),
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
    } on ChatRepositoryException catch (_) {
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

    Conversation? result;

    for (final Conversation conversation
    in _conversations) {
      final String? participantUserId =
      _cleanOptionalText(
        conversation.participantUserId,
      );

      if (participantUserId !=
          cleanUserId) {
        continue;
      }

      if (result != null) {
        throw const ChatServiceException(
          'Multiple visible conversations exist for the same user.',
        );
      }

      result =
          conversation;
    }

    return result;
  }

  // ============================================================
  // USER DELETE = HIDE
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

    final Future<void>? pendingHide =
    _pendingConversationHides[
    cleanConversationId
    ];

    if (pendingHide != null) {
      await pendingHide;
      return;
    }

    final Conversation? conversation =
    findConversation(
      cleanConversationId,
    );

    if (conversation == null) {
      throw const ChatServiceException(
        'Conversation not found.',
      );
    }

    final Future<void> hide =
    _hideConversationInternal(
      cleanConversationId,
    );

    _pendingConversationHides[
    cleanConversationId
    ] = hide;

    try {
      await hide;
    } finally {
      if (identical(
        _pendingConversationHides[
        cleanConversationId
        ],
        hide,
      )) {
        _pendingConversationHides.remove(
          cleanConversationId,
        );
      }
    }
  }

  Future<void> _hideConversationInternal(
      String conversationId,
      ) async {
    final Future<void>? pendingSend =
    _pendingMessageSends[
    conversationId
    ];

    if (pendingSend != null) {
      try {
        await pendingSend;
      } catch (_) {}
    }

    final Future<Conversation>?
    pendingMetadataWrite =
    _pendingConversationMetadataWrites[
    conversationId
    ];

    if (pendingMetadataWrite != null) {
      try {
        await pendingMetadataWrite;
      } catch (_) {}
    }

    if (findConversation(
      conversationId,
    ) ==
        null) {
      throw const ChatServiceException(
        'Conversation not found.',
      );
    }

    final String currentUserId =
    _requireCurrentUserId();

    try {
      await _repository.hideConversation(
        conversationId:
        conversationId,
        userId:
        currentUserId,
      );
    } on ChatRepositoryException catch (_) {
      throw const ChatServiceException(
        'Conversation could not be hidden. Please try again.',
      );
    } catch (_) {
      throw const ChatServiceException(
        'Conversation could not be hidden. Please try again.',
      );
    }

    _conversations.removeWhere(
          (
          Conversation conversation,
          ) =>
      conversation.id ==
          conversationId,
    );
  }

  // ============================================================
  // EXPLICIT RESTORE
  // ============================================================

  Future<Conversation> restoreConversation(
      String conversationId,
      ) async {
    await initialize();

    final String cleanConversationId =
    _requireText(
      conversationId,
      'Conversation ID',
    );

    final Conversation? alreadyVisible =
    findConversation(
      cleanConversationId,
    );

    if (alreadyVisible != null) {
      return alreadyVisible;
    }

    final String currentUserId =
    _requireCurrentUserId();

    late final List<Conversation>
    allConversations;

    try {
      allConversations =
      await _repository.getAllConversations(
        userId:
        currentUserId,
        includeHidden:
        true,
      );
    } on ChatRepositoryException catch (_) {
      throw const ChatServiceException(
        'Conversation history could not be loaded.',
      );
    }

    final List<Conversation> matches =
    allConversations.where(
          (
          Conversation conversation,
          ) =>
      conversation.id ==
          cleanConversationId,
    ).toList(
      growable: false,
    );

    if (matches.length != 1) {
      throw const ChatServiceException(
        'Conversation could not be found.',
      );
    }

    final Conversation target =
        matches.single;

    final String? participantUserId =
    _cleanOptionalText(
      target.participantUserId,
    );

    if (participantUserId == null) {
      throw const ChatServiceException(
        'Archived conversation has no verified participant.',
      );
    }

    final Conversation? currentVisible =
    findConversationByUserId(
      participantUserId,
    );

    if (currentVisible != null &&
        currentVisible.id !=
            target.id) {
      throw const ChatServiceException(
        'A newer conversation with this user is already active.',
      );
    }

    try {
      await _repository.unhideConversation(
        conversationId:
        cleanConversationId,
        userId:
        currentUserId,
      );
    } on ChatRepositoryException catch (_) {
      throw const ChatServiceException(
        'Conversation could not be restored.',
      );
    }

    final Conversation mutable =
    _mutableConversationCopy(
      target,
    );

    _replaceConversationInMemory(
      mutable,
    );

    return mutable;
  }

  void _throwIfConversationHiding(
      String conversationId,
      ) {
    if (_pendingConversationHides.containsKey(
      conversationId,
    )) {
      throw const ChatServiceException(
        'This conversation is being hidden.',
      );
    }
  }

  // ============================================================
  // IDS
  // ============================================================

  String _createLegacyConversationIdForUser(
      String userId,
      ) {
    final String cleanUserId =
    _requireText(
      userId,
      'User ID',
    );

    return 'conversation_$cleanUserId';
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

    _lastMessageIdMicros =
        candidate;

    return 'message_${_requireCurrentUserId()}_$candidate';
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String _requireCurrentUserId() {
    try {
      return _currentUserService
          .requireUserId();
    } on CurrentUserServiceException catch (_) {
      throw const ChatServiceException(
        'Current user identity is unavailable.',
      );
    }
  }

  // ============================================================
  // VALIDATION
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

    if (cleaned.length >
        maxLength) {
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

    if (cleaned.length >
        maxLength) {
      throw ChatServiceException(
        '$fieldName exceeds the allowed length.',
      );
    }
  }

  String? _cleanOptionalText(
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

class _ValidatedParticipantInput {
  final String userId;
  final User participant;
  final String userName;
  final String initials;
  final String city;
  final String skillWanted;
  final String skillOffered;

  const _ValidatedParticipantInput({
    required this.userId,
    required this.participant,
    required this.userName,
    required this.initials,
    required this.city,
    required this.skillWanted,
    required this.skillOffered,
  });
}