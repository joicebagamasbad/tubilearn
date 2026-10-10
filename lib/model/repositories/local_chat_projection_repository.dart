import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../services/current_user_service.dart';
import '../database/app_database.dart';
import 'firestore_chat_repository.dart';
import 'firestore_profile_repository.dart';

class LocalChatProjectionException implements Exception {
  final String message;

  const LocalChatProjectionException(this.message);

  @override
  String toString() => message;
}

/// Tally of what a single [LocalChatProjectionRepository.project] call did.
/// `projectedConversations`/`projectedMessages` count only rows newly
/// inserted into SQLite by this call — a conversation or message that
/// already existed locally (e.g. a re-sync of previously-projected data)
/// counts as neither projected nor skipped. `skippedConversations`/
/// `skippedMessages` count rows rejected as unresolved or invalid (an
/// unmatched participant, an invalid sender, empty/oversized text, etc.)
/// — never a reason to fail the whole projection.
class LocalChatProjectionResult {
  final int projectedConversations;
  final int skippedConversations;
  final int projectedMessages;
  final int skippedMessages;

  const LocalChatProjectionResult({
    required this.projectedConversations,
    required this.skippedConversations,
    required this.projectedMessages,
    required this.skippedMessages,
  });

  static const LocalChatProjectionResult zero = LocalChatProjectionResult(
    projectedConversations: 0,
    skippedConversations: 0,
    projectedMessages: 0,
    skippedMessages: 0,
  );
}

class _ConversationProjectionOutcome {
  final bool conversationSkipped;
  final bool conversationNewlyInserted;
  final int projectedMessageCount;
  final int skippedMessageCount;

  const _ConversationProjectionOutcome({
    required this.conversationSkipped,
    required this.conversationNewlyInserted,
    required this.projectedMessageCount,
    required this.skippedMessageCount,
  });

  const _ConversationProjectionOutcome.skipped()
    : conversationSkipped = true,
      conversationNewlyInserted = false,
      projectedMessageCount = 0,
      skippedMessageCount = 0;
}

/// Projects server-confirmed Firestore chat snapshots into local SQLite.
/// Local-only: never calls Firestore itself. Local conversation/message IDs
/// are deterministic and owner-scoped (see [localConversationId] /
/// [localMessageId]) because `conversations.id` and `messages.id` are
/// global primary keys shared by every account on this device's one
/// SQLite file.
class LocalChatProjectionRepository {
  LocalChatProjectionRepository({
    AppDatabase? database,
    CurrentUserService? currentUserService,
  }) : _database = database ?? AppDatabase.instance,
       _currentUserService = currentUserService ?? CurrentUserService.instance;

  static final LocalChatProjectionRepository instance =
      LocalChatProjectionRepository();

  static const String _legacyLocalUid = 'user_joice_local';
  static const String _conversationLiteralPrefix = 'remote_chat_v1_';
  static const String _messageLiteralPrefix = 'remote_chat_msg_v1_';

  static const int _maxUserNameLength = 80;
  static const int _maxInitialsLength = 10;
  static const int _maxCityLength = 120;
  static const int _maxMessageLength = 2000;

  final AppDatabase _database;
  final CurrentUserService _currentUserService;

  // ============================================================
  // DETERMINISTIC LOCAL IDS
  // ============================================================

  static String localConversationId(
    String ownerUid,
    String canonicalConversationId,
  ) {
    final String cleanOwner = _requireOwnerUidStatic(ownerUid);
    final String cleanCanonicalId = _requireIdentityStatic(
      canonicalConversationId,
      'Canonical conversation ID',
    );
    return '${_conversationPrefixFor(cleanOwner)}${_encodeIdentity(cleanCanonicalId)}';
  }

  static String localMessageId(String ownerUid, String firestoreMessageId) {
    final String cleanOwner = _requireOwnerUidStatic(ownerUid);
    final String cleanMessageId = _requireIdentityStatic(
      firestoreMessageId,
      'Firestore message ID',
    );
    return '${_messagePrefixFor(cleanOwner)}${_encodeIdentity(cleanMessageId)}';
  }

  static bool isRemoteLocalConversationId(String id) =>
      id.startsWith(_conversationLiteralPrefix);

  static String _conversationPrefixFor(String ownerUid) {
    final String encodedOwner = _encodeIdentity(ownerUid);
    return '$_conversationLiteralPrefix${encodedOwner.length}_${encodedOwner}_';
  }

  static String _messagePrefixFor(String ownerUid) {
    final String encodedOwner = _encodeIdentity(ownerUid);
    return '$_messageLiteralPrefix${encodedOwner.length}_${encodedOwner}_';
  }

  static String _encodeIdentity(String value) {
    return base64Url.encode(utf8.encode(value)).replaceAll('=', '');
  }

  // ============================================================
  // PROJECT
  // ============================================================

  Future<LocalChatProjectionResult> project({
    required String viewerUid,
    required FirestoreChatSnapshot snapshot,
    required Map<String, FirestoreProfileData> participantProfiles,
  }) async {
    final ActiveUserSession session = _captureViewerSession(viewerUid);
    if (snapshot.source == FirestoreChatSource.unavailable) {
      _requireSameSession(session);
      return LocalChatProjectionResult.zero;
    }

    int projectedConversations = 0;
    int skippedConversations = 0;
    int projectedMessages = 0;
    int skippedMessages = 0;

    try {
      final Database db = await _database.database;
      _requireSameSession(session);

      await db.transaction((Transaction transaction) async {
        _requireSameSession(session);

        for (final FirestoreChatConversationRecord record
            in snapshot.conversations) {
          final _ConversationProjectionOutcome outcome =
              await _projectConversation(
                transaction,
                session,
                session.uid,
                record,
                participantProfiles,
              );
          _requireSameSession(session);

          if (outcome.conversationSkipped) {
            skippedConversations++;
            skippedMessages += record.messages.length;
            continue;
          }

          if (outcome.conversationNewlyInserted) {
            projectedConversations++;
          }
          projectedMessages += outcome.projectedMessageCount;
          skippedMessages += outcome.skippedMessageCount;
        }
      });

      _requireSameSession(session);
    } on LocalChatProjectionException {
      rethrow;
    } on DatabaseException {
      throw const LocalChatProjectionException(
        'Cloud conversations could not be saved to the local cache.',
      );
    } catch (_) {
      throw const LocalChatProjectionException(
        'Cloud conversations could not be saved to the local cache.',
      );
    }

    return LocalChatProjectionResult(
      projectedConversations: projectedConversations,
      skippedConversations: skippedConversations,
      projectedMessages: projectedMessages,
      skippedMessages: skippedMessages,
    );
  }

  // ============================================================
  // PROJECT ONE CONVERSATION
  // ============================================================

  Future<_ConversationProjectionOutcome> _projectConversation(
    Transaction transaction,
    ActiveUserSession session,
    String viewerUid,
    FirestoreChatConversationRecord record,
    Map<String, FirestoreProfileData> participantProfiles,
  ) async {
    // ----------------------------------------------------------
    // a) RESOLVE THE OTHER PARTICIPANT
    // ----------------------------------------------------------

    if (record.participantUids.length != 2 ||
        !record.participantUids.contains(viewerUid)) {
      return const _ConversationProjectionOutcome.skipped();
    }

    final List<String> others = record.participantUids
        .where((String uid) => uid != viewerUid)
        .toList(growable: false);

    if (others.length != 1) {
      return const _ConversationProjectionOutcome.skipped();
    }

    final String otherUid = others.single;
    if (otherUid == viewerUid) {
      return const _ConversationProjectionOutcome.skipped();
    }

    // ----------------------------------------------------------
    // b) ENSURE A LOCAL users ROW FOR THE OTHER PARTICIPANT
    // ----------------------------------------------------------

    final List<Map<String, Object?>> existingUserRows = await transaction
        .query(
          'users',
          columns: <String>['id', 'name', 'initials', 'city'],
          where: 'id = ?',
          whereArgs: <Object?>[otherUid],
          limit: 2,
        );
    _requireSameSession(session);

    if (existingUserRows.length > 1) {
      throw const LocalChatProjectionException(
        'A chat participant is not unique locally.',
      );
    }

    String displayName;
    String displayInitials;
    String displayCity;

    if (existingUserRows.isNotEmpty) {
      final Map<String, Object?> row = existingUserRows.single;
      displayName = _requireRowString(row, 'name');
      displayInitials = _requireRowString(row, 'initials');
      displayCity = _requireRowString(row, 'city');
    } else {
      final FirestoreProfileData? profile = participantProfiles[otherUid];
      if (profile == null) {
        return const _ConversationProjectionOutcome.skipped();
      }

      final String trimmedName = profile.name.trim();
      if (trimmedName.isEmpty) {
        return const _ConversationProjectionOutcome.skipped();
      }

      final String trimmedBio = profile.bio.trim();
      final String trimmedMemberSince = profile.memberSince.trim();
      final String trimmedAvailability = profile.availability.trim();
      final String trimmedLanguage = profile.language.trim();
      final String trimmedPreferredMode = profile.preferredMode.trim();
      final String trimmedTeachingStyle = profile.teachingStyle.trim();

      if (trimmedMemberSince.isEmpty ||
          trimmedAvailability.isEmpty ||
          trimmedLanguage.isEmpty ||
          trimmedPreferredMode.isEmpty ||
          trimmedTeachingStyle.isEmpty) {
        // These columns are NOT NULL + non-empty in the local schema and
        // there is no safe placeholder to invent for them, unlike city
        // (which has the existing 'Not set' convention below) — so an
        // incomplete profile here means skipping, not guessing.
        return const _ConversationProjectionOutcome.skipped();
      }

      final String trimmedCity = profile.city.trim();
      final String effectiveCity = trimmedCity.isEmpty
          ? 'Not set'
          : trimmedCity;
      final String initials = _buildInitials(trimmedName);

      await transaction.insert('users', <String, Object?>{
        'id': otherUid,
        'name': trimmedName,
        'initials': initials,
        'city': effectiveCity,
        'bio': trimmedBio,
        'member_since': trimmedMemberSince,
        'availability': trimmedAvailability,
        'language': trimmedLanguage,
        'preferred_mode': trimmedPreferredMode,
        'teaching_style': trimmedTeachingStyle,
        'profile_completed': 1,
        'rating': 0.0,
        'review_count': 0,
        'completed_swaps': 0,
        'response_rate': 0,
        'email_verified': 0,
        'profile_image_path': null,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      _requireSameSession(session);

      displayName = trimmedName;
      displayInitials = initials;
      displayCity = effectiveCity;
    }

    // ----------------------------------------------------------
    // c) CLAMP DISPLAY STRINGS TO ChatService'S VALIDATION LIMITS
    // ----------------------------------------------------------

    displayName = _clamp(displayName, _maxUserNameLength);
    displayInitials = _clamp(displayInitials, _maxInitialsLength);
    displayCity = _clamp(displayCity, _maxCityLength);

    // ----------------------------------------------------------
    // d) CONVERSATION ROW
    // ----------------------------------------------------------

    final String localConvId = localConversationId(viewerUid, record.id);

    final List<Map<String, Object?>> existingConversationRows =
        await transaction.query(
          'conversations',
          columns: <String>['id', 'owner_user_id', 'participant_user_id'],
          where: 'id = ?',
          whereArgs: <Object?>[localConvId],
          limit: 2,
        );
    _requireSameSession(session);

    if (existingConversationRows.length > 1) {
      throw const LocalChatProjectionException(
        'A projected conversation identity is not unique locally.',
      );
    }

    bool conversationNewlyInserted = false;

    if (existingConversationRows.isNotEmpty) {
      final Map<String, Object?> row = existingConversationRows.single;
      final String? existingOwner = _optionalRowString(row, 'owner_user_id');
      final String? existingParticipant = _optionalRowString(
        row,
        'participant_user_id',
      );
      if (existingOwner != viewerUid || existingParticipant != otherUid) {
        throw const LocalChatProjectionException(
          'A projected conversation does not match its expected owner or '
          'participant.',
        );
      }
      // Never update an existing row — Firestore is authoritative for
      // this conversation's identity, but display fields on an existing
      // local row may already carry a user-visible edit history we must
      // not stomp on from a background re-sync.
    } else {
      await transaction.insert('conversations', <String, Object?>{
        'id': localConvId,
        'owner_user_id': viewerUid,
        'participant_user_id': otherUid,
        'user_name': displayName,
        'initials': displayInitials,
        'city': displayCity,
        'skill_wanted': 'Skill',
        'skill_offered': 'Skill',
        'status': 'New',
        // A newly projected remote thread starts as nothing read.
        // Projection never updates this column on an existing row — see
        // the "never update an existing row" comment above.
        'last_read_at': null,
      }, conflictAlgorithm: ConflictAlgorithm.abort);
      _requireSameSession(session);
      conversationNewlyInserted = true;
    }

    // ----------------------------------------------------------
    // e) AUTO-HIDE ANY VISIBLE LEGACY THREAD FOR THE SAME PARTICIPANT
    //
    // Only on first insert: ChatService.findConversationByUserId throws
    // if more than one visible conversation exists for the same
    // participant, so a newly-arrived remote thread and an
    // already-visible legacy thread can never be allowed to coexist
    // visibly. Hiding, never deleting — and never done again once this
    // remote thread already exists, so a user who later re-hides this
    // remote thread themselves is never silently un-hidden by a re-sync.
    // ----------------------------------------------------------

    if (conversationNewlyInserted) {
      final List<Map<String, Object?>> legacyVisibleRows = await transaction
          .rawQuery(
            '''
            SELECT c.id
            FROM conversations AS c
            WHERE c.owner_user_id = ?
              AND c.participant_user_id = ?
              AND c.id NOT GLOB ?
              AND NOT EXISTS (
                SELECT 1
                FROM conversation_user_visibility AS v
                WHERE v.conversation_id = c.id
                  AND v.user_id = ?
                  AND v.is_hidden = 1
              )
            ''',
            <Object?>[
              viewerUid,
              otherUid,
              '$_conversationLiteralPrefix*',
              viewerUid,
            ],
          );
      _requireSameSession(session);

      final int hiddenAtMillis = DateTime.now().millisecondsSinceEpoch;

      for (final Map<String, Object?> legacyRow in legacyVisibleRows) {
        final String legacyConversationId = _requireRowString(
          legacyRow,
          'id',
        );

        final int updatedRows = await transaction.update(
          'conversation_user_visibility',
          <String, Object?>{'is_hidden': 1, 'hidden_at': hiddenAtMillis},
          where: 'conversation_id = ? AND user_id = ?',
          whereArgs: <Object?>[legacyConversationId, viewerUid],
        );
        _requireSameSession(session);

        if (updatedRows > 1) {
          throw const LocalChatProjectionException(
            'Legacy conversation visibility is not unique locally.',
          );
        }

        if (updatedRows == 0) {
          await transaction.insert('conversation_user_visibility', <String, Object?>{
            'conversation_id': legacyConversationId,
            'user_id': viewerUid,
            'is_hidden': 1,
            'hidden_at': hiddenAtMillis,
          }, conflictAlgorithm: ConflictAlgorithm.abort);
          _requireSameSession(session);
        }
      }
    }

    // ----------------------------------------------------------
    // f) MESSAGES
    // ----------------------------------------------------------

    int projectedMessageCount = 0;
    int skippedMessageCount = 0;

    for (final FirestoreChatMessageRecord message in record.messages) {
      final String trimmedText = message.text.trim();
      final bool validSender =
          message.senderUid == viewerUid || message.senderUid == otherUid;
      final int sentAtMillis = message.sentAt.toUtc().millisecondsSinceEpoch;

      if (!validSender ||
          trimmedText.isEmpty ||
          trimmedText.length > _maxMessageLength ||
          sentAtMillis <= 0) {
        skippedMessageCount++;
        continue;
      }

      final String localMsgId = localMessageId(viewerUid, message.id);

      final int insertedRowId = await transaction.insert('messages', <String, Object?>{
        'id': localMsgId,
        'conversation_id': localConvId,
        'text': trimmedText,
        'sender_user_id': message.senderUid,
        'sent_at': sentAtMillis,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      _requireSameSession(session);

      // insertedRowId == 0 means the ignore fired (already projected by
      // an earlier sync) — that is a successful no-op, not a skip: the
      // message is already present locally, so it is counted as neither
      // newly projected nor rejected for being invalid.
      if (insertedRowId > 0) {
        projectedMessageCount++;
      }
    }

    return _ConversationProjectionOutcome(
      conversationSkipped: false,
      conversationNewlyInserted: conversationNewlyInserted,
      projectedMessageCount: projectedMessageCount,
      skippedMessageCount: skippedMessageCount,
    );
  }

  // ============================================================
  // INITIALS (mirrors local_user_data_projection_repository.dart's
  // _buildInitials; duplicated rather than shared, per scope)
  // ============================================================

  String _buildInitials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      throw const LocalChatProjectionException('Profile name is invalid.');
    }
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _clamp(String value, int maxLength) {
    return value.length <= maxLength ? value : value.substring(0, maxLength);
  }

  // ============================================================
  // SESSION FENCING
  // ============================================================

  ActiveUserSession _captureViewerSession(String viewerUid) {
    final String cleanUid = _requireOwnerUidStatic(viewerUid);
    try {
      final ActiveUserSession session = _currentUserService.captureSession();
      if (session.uid != cleanUid) {
        throw const LocalChatProjectionException(
          'The local chat projection is limited to the active viewer.',
        );
      }
      return session;
    } on LocalChatProjectionException {
      rethrow;
    } on CurrentUserServiceException catch (error) {
      throw LocalChatProjectionException(error.message);
    }
  }

  void _requireSameSession(ActiveUserSession session) {
    try {
      _currentUserService.requireSameSession(session);
    } on CurrentUserServiceException catch (error) {
      throw LocalChatProjectionException(error.message);
    }
  }

  // ============================================================
  // ROW PARSING HELPERS
  // ============================================================

  String _requireRowString(Map<String, Object?> row, String key) {
    final Object? value = row[key];
    if (value is! String || value.trim().isEmpty) {
      throw LocalChatProjectionException(
        'Local chat field "$key" is invalid.',
      );
    }
    return value;
  }

  String? _optionalRowString(Map<String, Object?> row, String key) {
    final Object? value = row[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw LocalChatProjectionException(
        'Local chat field "$key" is invalid.',
      );
    }
    final String clean = value.trim();
    return clean.isEmpty ? null : clean;
  }

  // ============================================================
  // IDENTITY VALIDATION
  // ============================================================

  static String _requireIdentityStatic(String value, String label) {
    final String clean = value.trim();
    if (clean.isEmpty || clean != value) {
      throw LocalChatProjectionException('$label is invalid.');
    }
    return clean;
  }

  static String _requireOwnerUidStatic(String value) {
    final String clean = value.trim();
    if (clean.isEmpty || clean != value || clean == _legacyLocalUid) {
      throw const LocalChatProjectionException('Owner UID is invalid.');
    }
    return clean;
  }
}
