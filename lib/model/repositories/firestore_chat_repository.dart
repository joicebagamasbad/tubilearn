import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreChatRepositoryException implements Exception {
  final String message;

  const FirestoreChatRepositoryException(this.message);

  @override
  String toString() => message;
}

enum FirestoreChatSource { server, cache, unavailable }

/// One message document as stored in a conversation's messages
/// subcollection. Messages are immutable once created.
class FirestoreChatMessageRecord {
  final String id;
  final String conversationId;
  final String senderUid;
  final String text;
  final DateTime sentAt;

  const FirestoreChatMessageRecord({
    required this.id,
    required this.conversationId,
    required this.senderUid,
    required this.text,
    required this.sentAt,
  });
}

/// One conversation document as stored in Firestore. Holds only the
/// shared identity (participants, creation time) and its messages —
/// per-viewer display fields (name, initials, city, skills, status) are
/// never stored here; resolving those against each viewer's own data is a
/// later projection step's job, not this repository's.
class FirestoreChatConversationRecord {
  final String id;
  final List<String> participantUids;
  final DateTime createdAt;
  final List<FirestoreChatMessageRecord> messages;

  const FirestoreChatConversationRecord({
    required this.id,
    required this.participantUids,
    required this.createdAt,
    required this.messages,
  });
}

class FirestoreChatSnapshot {
  final FirestoreChatSource source;
  final List<FirestoreChatConversationRecord> conversations;

  const FirestoreChatSnapshot({
    required this.source,
    required this.conversations,
  });

  const FirestoreChatSnapshot.unavailable()
    : source = FirestoreChatSource.unavailable,
      conversations = const <FirestoreChatConversationRecord>[];
}

class FirestoreChatRepository {
  FirestoreChatRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final FirestoreChatRepository instance = FirestoreChatRepository();

  static const String _conversationsCollectionPath = 'conversations';
  static const String _messagesSubcollectionPath = 'messages';
  static const String _legacyLocalUid = 'user_joice_local';
  static const int _maxMessageLength = 2000;

  final FirebaseFirestore _firestore;

  // ============================================================
  // READ
  // ============================================================

  Future<FirestoreChatSnapshot> getConversationsForUser(String uid) async {
    final String cleanUid = _requireUid(uid);

    try {
      return await _loadFromSource(cleanUid, Source.server);
    } on FirestoreChatRepositoryException {
      rethrow;
    } on FirebaseException catch (error) {
      if (!_isAvailabilityFailure(error)) {
        throw const FirestoreChatRepositoryException(
          'Your conversations could not be loaded. Please try again.',
        );
      }
    } catch (_) {
      throw const FirestoreChatRepositoryException(
        'Your conversations could not be loaded. Please try again.',
      );
    }

    try {
      return await _loadFromSource(cleanUid, Source.cache);
    } catch (_) {
      return const FirestoreChatSnapshot.unavailable();
    }
  }

  Future<FirestoreChatSnapshot> _loadFromSource(
    String uid,
    Source source,
  ) async {
    final CollectionReference<Map<String, dynamic>> conversationsCollection =
        _firestore.collection(_conversationsCollectionPath);

    final QuerySnapshot<Map<String, dynamic>> conversationResults =
        await conversationsCollection
            .where('participantUids', arrayContains: uid)
            .get(GetOptions(source: source));

    if (source == Source.cache && conversationResults.docs.isEmpty) {
      return const FirestoreChatSnapshot.unavailable();
    }

    final List<FirestoreChatConversationRecord> conversations =
        <FirestoreChatConversationRecord>[];

    for (final QueryDocumentSnapshot<Map<String, dynamic>> conversationDoc
        in conversationResults.docs) {
      final List<String> participantUids = _parseParticipantUids(
        conversationDoc,
        uid,
      );

      final DateTime createdAt = _requiredTimestamp(
        conversationDoc.data(),
        'createdAt',
      ).toDate().toUtc();

      final QuerySnapshot<Map<String, dynamic>> messageResults =
          await conversationDoc.reference
              .collection(_messagesSubcollectionPath)
              .orderBy('sentAt')
              .get(GetOptions(source: source));

      final List<FirestoreChatMessageRecord> messages = messageResults.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> messageDoc) =>
                _parseMessageRecord(messageDoc, conversationDoc.id),
          )
          .toList(growable: false);

      conversations.add(
        FirestoreChatConversationRecord(
          id: conversationDoc.id,
          participantUids: participantUids,
          createdAt: createdAt,
          messages: messages,
        ),
      );
    }

    return FirestoreChatSnapshot(
      source: source == Source.server
          ? FirestoreChatSource.server
          : FirestoreChatSource.cache,
      conversations: conversations,
    );
  }

  // ============================================================
  // GET OR CREATE CONVERSATION
  // ============================================================

  /// Returns the canonical conversation ID for [uidA]/[uidB], creating the
  /// document if it does not exist yet. Safe to call concurrently from
  /// both participants: Firestore transactions resolve the race, and the
  /// read-before-write check means whichever call loses the race simply
  /// observes the already-created document instead of failing.
  Future<String> createConversationIfMissing(String uidA, String uidB) async {
    final List<String> pair = sortedParticipantPair(uidA, uidB);
    final String canonicalId = '${pair[0]}_${pair[1]}';
    final DocumentReference<Map<String, dynamic>> reference = _firestore
        .collection(_conversationsCollectionPath)
        .doc(canonicalId);

    try {
      await _firestore.runTransaction<void>((Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(reference);

        if (snapshot.exists) {
          final Map<String, dynamic>? data = snapshot.data();
          final Object? rawParticipantUids = data == null
              ? null
              : data['participantUids'];

          if (rawParticipantUids is! List ||
              rawParticipantUids.length != 2 ||
              rawParticipantUids[0] != pair[0] ||
              rawParticipantUids[1] != pair[1]) {
            throw const FirestoreChatRepositoryException(
              'This conversation already exists with different participants.',
            );
          }

          return;
        }

        transaction.set(reference, <String, Object?>{
          'participantUids': pair,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      return canonicalId;
    } on FirestoreChatRepositoryException {
      rethrow;
    } on FirebaseException {
      throw const FirestoreChatRepositoryException(
        'This conversation could not be started. Please try again.',
      );
    } catch (_) {
      throw const FirestoreChatRepositoryException(
        'This conversation could not be started. Please try again.',
      );
    }
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<String> sendMessage({
    required String conversationId,
    required String senderUid,
    required String text,
  }) async {
    final String cleanConversationId = _requireNonEmpty(
      conversationId,
      'Conversation ID',
    );
    final String cleanSenderUid = _requireUid(senderUid);
    final String cleanText = text.trim();

    if (cleanText.isEmpty || cleanText.length > _maxMessageLength) {
      throw const FirestoreChatRepositoryException(
        'Message must be between 1 and 2000 characters.',
      );
    }

    final DocumentReference<Map<String, dynamic>> messageReference =
        _firestore
            .collection(_conversationsCollectionPath)
            .doc(cleanConversationId)
            .collection(_messagesSubcollectionPath)
            .doc();

    try {
      // A plain .set() would succeed immediately against Firestore's
      // offline cache and queue the write for later delivery, so an
      // offline send would appear to hang (or, on retry, double-send)
      // instead of failing fast. Transactions have no offline cache
      // fallback, so this fails immediately when there's no connection —
      // same philosophy as the swap repository's transactional updates.
      await _firestore.runTransaction<void>((Transaction transaction) async {
        transaction.set(messageReference, <String, Object?>{
          'senderUid': cleanSenderUid,
          'text': cleanText,
          'sentAt': FieldValue.serverTimestamp(),
        });
      });

      return messageReference.id;
    } on FirebaseException {
      throw const FirestoreChatRepositoryException(
        'Your message could not be sent. Please try again.',
      );
    } catch (_) {
      throw const FirestoreChatRepositoryException(
        'Your message could not be sent. Please try again.',
      );
    }
  }

  // ============================================================
  // WATCH CONVERSATION MESSAGES
  // ============================================================

  /// Streams the newest 100 messages for one conversation, server-
  /// confirmed snapshots only. `includeMetadataChanges` is true on
  /// purpose: without it, Firestore suppresses metadata-only updates,
  /// so the follow-up event that flips a snapshot from cache/pending to
  /// server-confirmed would never arrive — we need that cache -> server
  /// flip to be its own event, not silently dropped.
  Stream<List<FirestoreChatMessageRecord>> watchConversationMessages({
    required String viewerUid,
    required String participantUid,
  }) async* {
    final String canonicalId = canonicalConversationId(
      viewerUid,
      participantUid,
    );

    final Stream<QuerySnapshot<Map<String, dynamic>>> snapshots = _firestore
        .collection(_conversationsCollectionPath)
        .doc(canonicalId)
        .collection(_messagesSubcollectionPath)
        .orderBy('sentAt')
        .limitToLast(100)
        .snapshots(includeMetadataChanges: true);

    try {
      await for (final QuerySnapshot<Map<String, dynamic>> snapshot
          in snapshots) {
        if (snapshot.metadata.isFromCache ||
            snapshot.metadata.hasPendingWrites) {
          // Not server-confirmed yet (this also covers our own
          // optimistic writes, whose pending serverTimestamp() reads
          // back as null) — skip; the confirmed follow-up event will
          // arrive once the server round-trip completes.
          continue;
        }

        final List<FirestoreChatMessageRecord> messages;

        try {
          messages = snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    _parseMessageRecord(doc, canonicalId),
              )
              .toList(growable: false);
        } on FirestoreChatRepositoryException {
          // A single malformed document must not kill the stream: the
          // same persistently-malformed data is also exactly what would
          // make a manual refresh (getConversationsForUser) throw, so
          // skipping here and waiting for the next event is no worse.
          continue;
        }

        yield messages;
      }
    } on FirebaseException {
      throw const FirestoreChatRepositoryException(
        'Live updates are unavailable right now.',
      );
    } catch (_) {
      throw const FirestoreChatRepositoryException(
        'Live updates are unavailable right now.',
      );
    }
  }

  // ============================================================
  // CANONICAL CONVERSATION ID
  // ============================================================

  static String canonicalConversationId(String uidA, String uidB) {
    final List<String> pair = sortedParticipantPair(uidA, uidB);
    return '${pair[0]}_${pair[1]}';
  }

  static List<String> sortedParticipantPair(String uidA, String uidB) {
    final String cleanA = _requireUidStatic(uidA);
    final String cleanB = _requireUidStatic(uidB);

    if (cleanA == cleanB) {
      throw const FirestoreChatRepositoryException(
        'A conversation requires two distinct participants.',
      );
    }

    final List<String> pair = <String>[cleanA, cleanB]..sort();
    return List<String>.unmodifiable(pair);
  }

  // ============================================================
  // FIELD PARSING HELPERS
  // ============================================================

  List<String> _parseParticipantUids(
    QueryDocumentSnapshot<Map<String, dynamic>> conversationDoc,
    String requestingUid,
  ) {
    final Object? raw = conversationDoc.data()['participantUids'];

    if (raw is! List || raw.length != 2) {
      throw const FirestoreChatRepositoryException(
        'A cloud conversation has invalid participants.',
      );
    }

    final List<String> uids = <String>[];
    for (final Object? entry in raw) {
      if (entry is! String || entry != entry.trim() || entry.isEmpty) {
        throw const FirestoreChatRepositoryException(
          'A cloud conversation has invalid participants.',
        );
      }
      uids.add(entry);
    }

    if (uids[0] == uids[1] || uids[0].compareTo(uids[1]) >= 0) {
      throw const FirestoreChatRepositoryException(
        'A cloud conversation has invalid participants.',
      );
    }

    if (!uids.contains(requestingUid)) {
      throw const FirestoreChatRepositoryException(
        'A cloud conversation does not include the requesting user.',
      );
    }

    final String expectedId = canonicalConversationId(uids[0], uids[1]);
    if (conversationDoc.id != expectedId) {
      throw const FirestoreChatRepositoryException(
        'A cloud conversation ID does not match its participants.',
      );
    }

    return List<String>.unmodifiable(uids);
  }

  FirestoreChatMessageRecord _parseMessageRecord(
    QueryDocumentSnapshot<Map<String, dynamic>> messageDoc,
    String conversationId,
  ) {
    final Map<String, dynamic> data = messageDoc.data();

    return FirestoreChatMessageRecord(
      id: _requireDocumentId(messageDoc.id),
      conversationId: conversationId,
      senderUid: _requiredString(data, 'senderUid', allowEmpty: false),
      text: _requiredString(data, 'text', allowEmpty: false),
      sentAt: _requiredTimestamp(data, 'sentAt').toDate().toUtc(),
    );
  }

  String _requireDocumentId(String id) {
    final String clean = id.trim();
    if (clean.isEmpty) {
      throw const FirestoreChatRepositoryException(
        'A cloud chat document has an invalid document ID.',
      );
    }
    return clean;
  }

  String _requiredString(
    Map<String, dynamic> data,
    String key, {
    required bool allowEmpty,
  }) {
    final Object? value = data[key];
    if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
      throw FirestoreChatRepositoryException(
        'Cloud chat field "$key" is invalid.',
      );
    }
    return value.trim();
  }

  Timestamp _requiredTimestamp(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! Timestamp) {
      throw FirestoreChatRepositoryException(
        'Cloud chat field "$key" is invalid.',
      );
    }
    return value;
  }

  String _requireNonEmpty(String value, String label) {
    final String clean = value.trim();
    if (clean.isEmpty) {
      throw FirestoreChatRepositoryException('$label is required.');
    }
    return clean;
  }

  String _requireUid(String uid) => _requireUidStatic(uid);

  static String _requireUidStatic(String uid) {
    final String clean = uid.trim();
    if (clean.isEmpty || clean == _legacyLocalUid) {
      throw const FirestoreChatRepositoryException(
        'A valid authenticated user ID is required.',
      );
    }
    return clean;
  }

  bool _isAvailabilityFailure(FirebaseException error) {
    return const <String>{
      'aborted',
      'cancelled',
      'deadline-exceeded',
      'network-request-failed',
      'resource-exhausted',
      'unavailable',
      'unknown',
    }.contains(error.code);
  }
}
