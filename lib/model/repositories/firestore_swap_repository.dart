import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSwapRepositoryException implements Exception {
  final String message;

  const FirestoreSwapRepositoryException(this.message);

  @override
  String toString() => message;
}

enum FirestoreSwapSource { server, cache, unavailable }

/// One raw swap request document as stored in Firestore. Skill IDs here are
/// unresolved remote catalog IDs — resolving them against the local skill
/// catalog is a later projection step's job, not this repository's.
class FirestoreSwapRequestRecord {
  final String id;
  final String requesterUserId;
  final String providerUserId;
  final String? skillToLearnId;
  final String? skillToOfferId;
  final String providerName;
  final String providerInitials;
  final String providerCity;
  final String skillToLearn;
  final String skillToOffer;
  final DateTime proposedAt;
  final String mode;
  final String? meetingDetails;
  final String? note;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FirestoreSwapRequestRecord({
    required this.id,
    required this.requesterUserId,
    required this.providerUserId,
    required this.skillToLearnId,
    required this.skillToOfferId,
    required this.providerName,
    required this.providerInitials,
    required this.providerCity,
    required this.skillToLearn,
    required this.skillToOffer,
    required this.proposedAt,
    required this.mode,
    required this.meetingDetails,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
}

class FirestoreSwapSnapshot {
  final FirestoreSwapSource source;
  final List<FirestoreSwapRequestRecord> records;

  const FirestoreSwapSnapshot({required this.source, required this.records});

  const FirestoreSwapSnapshot.unavailable()
    : source = FirestoreSwapSource.unavailable,
      records = const <FirestoreSwapRequestRecord>[];
}

class FirestoreSwapRepository {
  FirestoreSwapRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final FirestoreSwapRepository instance = FirestoreSwapRepository();

  static const String _collectionPath = 'swapRequests';
  static const String _legacyLocalUid = 'user_joice_local';

  final FirebaseFirestore _firestore;

  // ============================================================
  // READ
  // ============================================================

  Future<FirestoreSwapSnapshot> getSwapRequestsForUser(String uid) async {
    final String cleanUid = _requireUid(uid);

    try {
      return await _loadFromSource(cleanUid, Source.server);
    } on FirestoreSwapRepositoryException {
      rethrow;
    } on FirebaseException catch (error) {
      if (!_isAvailabilityFailure(error)) {
        throw const FirestoreSwapRepositoryException(
          'Your cloud swap requests could not be loaded. Please try again.',
        );
      }
    } catch (_) {
      throw const FirestoreSwapRepositoryException(
        'Your cloud swap requests could not be loaded. Please try again.',
      );
    }

    try {
      return await _loadFromSource(cleanUid, Source.cache);
    } catch (_) {
      return const FirestoreSwapSnapshot.unavailable();
    }
  }

  Future<FirestoreSwapSnapshot> _loadFromSource(
    String uid,
    Source source,
  ) async {
    final CollectionReference<Map<String, dynamic>> collection = _firestore
        .collection(_collectionPath);

    final List<QuerySnapshot<Map<String, dynamic>>> results = await Future.wait(
      <Future<QuerySnapshot<Map<String, dynamic>>>>[
        collection
            .where('requesterUserId', isEqualTo: uid)
            .get(GetOptions(source: source)),
        collection
            .where('providerUserId', isEqualTo: uid)
            .get(GetOptions(source: source)),
      ],
    );

    final QuerySnapshot<Map<String, dynamic>> requesterResults = results[0];
    final QuerySnapshot<Map<String, dynamic>> providerResults = results[1];

    if (source == Source.cache &&
        requesterResults.docs.isEmpty &&
        providerResults.docs.isEmpty) {
      return const FirestoreSwapSnapshot.unavailable();
    }

    final List<FirestoreSwapRequestRecord> records =
        <FirestoreSwapRequestRecord>[];
    final Set<String> seenIds = <String>{};

    for (final QueryDocumentSnapshot<Map<String, dynamic>> snapshot
        in <QueryDocumentSnapshot<Map<String, dynamic>>>[
          ...requesterResults.docs,
          ...providerResults.docs,
        ]) {
      if (!seenIds.add(snapshot.id)) {
        continue;
      }
      records.add(_parseRecord(snapshot));
    }

    return FirestoreSwapSnapshot(
      source: source == Source.server
          ? FirestoreSwapSource.server
          : FirestoreSwapSource.cache,
      records: records,
    );
  }

  // ============================================================
  // CREATE
  // ============================================================

  /// Writes a new swap request document at [_collectionPath]/{data.id},
  /// using data.id as the client-chosen document ID. A plain `.set()` is
  /// used rather than a transaction: unlike the profile/skills repositories
  /// (which guard against races on a shared, singleton-per-uid or
  /// singleton-per-title document), this ID is freshly generated per
  /// request by the caller and collision is not a realistic concern, so a
  /// read-then-write transaction would add overhead without protecting
  /// against anything real.
  Future<void> createSwapRequest(FirestoreSwapRequestRecord data) async {
    final String cleanId = _requireNonEmpty(data.id, 'Swap request ID');
    final DocumentReference<Map<String, dynamic>> reference = _firestore
        .collection(_collectionPath)
        .doc(cleanId);

    try {
      await reference.set(<String, Object?>{
        ..._editableFields(data),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirestoreSwapRepositoryException {
      rethrow;
    } on FirebaseException {
      throw const FirestoreSwapRepositoryException(
        'This swap request could not be created. Please try again.',
      );
    } catch (_) {
      throw const FirestoreSwapRepositoryException(
        'This swap request could not be created. Please try again.',
      );
    }
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  /// Sets [newStatus] and refreshes updatedAt on the existing document.
  /// Trusts its caller entirely — it does not validate that this is a
  /// legal transition from the document's current status; that is the
  /// Service layer's responsibility.
  Future<void> updateStatus(
    String requestId, {
    required String newStatus,
  }) async {
    final String cleanId = _requireNonEmpty(requestId, 'Swap request ID');
    final String cleanStatus = _requireNonEmpty(newStatus, 'Status');
    final DocumentReference<Map<String, dynamic>> reference = _firestore
        .collection(_collectionPath)
        .doc(cleanId);

    try {
      await _firestore.runTransaction<void>((Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(reference);
        if (!snapshot.exists) {
          throw const FirestoreSwapRepositoryException(
            'This swap request could not be found.',
          );
        }
        transaction.update(reference, <String, Object?>{
          'status': cleanStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirestoreSwapRepositoryException {
      rethrow;
    } on FirebaseException {
      throw const FirestoreSwapRepositoryException(
        'This swap request could not be updated. Please try again.',
      );
    } catch (_) {
      throw const FirestoreSwapRepositoryException(
        'This swap request could not be updated. Please try again.',
      );
    }
  }

  // ============================================================
  // UPDATE SCHEDULE
  // ============================================================

  Future<void> updateSchedule(
    String requestId, {
    required DateTime proposedAt,
    required String mode,
    String? meetingDetails,
  }) async {
    final String cleanId = _requireNonEmpty(requestId, 'Swap request ID');
    final String cleanMode = _requireNonEmpty(mode, 'Mode');
    final String? cleanMeetingDetails = _normalizeNullable(meetingDetails);
    final DocumentReference<Map<String, dynamic>> reference = _firestore
        .collection(_collectionPath)
        .doc(cleanId);

    try {
      await _firestore.runTransaction<void>((Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(reference);
        if (!snapshot.exists) {
          throw const FirestoreSwapRepositoryException(
            'This swap request could not be found.',
          );
        }
        transaction.update(reference, <String, Object?>{
          'proposedAt': Timestamp.fromDate(proposedAt.toUtc()),
          'mode': cleanMode,
          'meetingDetails': cleanMeetingDetails,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirestoreSwapRepositoryException {
      rethrow;
    } on FirebaseException {
      throw const FirestoreSwapRepositoryException(
        'This swap request could not be rescheduled. Please try again.',
      );
    } catch (_) {
      throw const FirestoreSwapRepositoryException(
        'This swap request could not be rescheduled. Please try again.',
      );
    }
  }

  // ============================================================
  // FIELD MAPPING
  // ============================================================

  Map<String, Object?> _editableFields(FirestoreSwapRequestRecord data) {
    return <String, Object?>{
      'requesterUserId': _requireNonEmpty(
        data.requesterUserId,
        'Requester user ID',
      ),
      'providerUserId': _requireNonEmpty(
        data.providerUserId,
        'Provider user ID',
      ),
      'skillToLearnId': _normalizeNullable(data.skillToLearnId),
      'skillToOfferId': _normalizeNullable(data.skillToOfferId),
      'providerName': _requireNonEmpty(data.providerName, 'Provider name'),
      'providerInitials': _requireNonEmpty(
        data.providerInitials,
        'Provider initials',
      ),
      'providerCity': _requireNonEmpty(data.providerCity, 'Provider city'),
      'skillToLearn': _requireNonEmpty(data.skillToLearn, 'Skill to learn'),
      'skillToOffer': _requireNonEmpty(data.skillToOffer, 'Skill to offer'),
      'proposedAt': Timestamp.fromDate(data.proposedAt.toUtc()),
      'mode': _requireNonEmpty(data.mode, 'Mode'),
      'meetingDetails': _normalizeNullable(data.meetingDetails),
      'note': _normalizeNullable(data.note),
      'status': _requireNonEmpty(data.status, 'Status'),
    };
  }

  FirestoreSwapRequestRecord _parseRecord(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = snapshot.data();
    return FirestoreSwapRequestRecord(
      id: _requireDocumentId(snapshot.id),
      requesterUserId: _requiredString(
        data,
        'requesterUserId',
        allowEmpty: false,
      ),
      providerUserId: _requiredString(
        data,
        'providerUserId',
        allowEmpty: false,
      ),
      skillToLearnId: _optionalString(data, 'skillToLearnId'),
      skillToOfferId: _optionalString(data, 'skillToOfferId'),
      providerName: _requiredString(data, 'providerName', allowEmpty: false),
      providerInitials: _requiredString(
        data,
        'providerInitials',
        allowEmpty: false,
      ),
      providerCity: _requiredString(data, 'providerCity', allowEmpty: false),
      skillToLearn: _requiredString(data, 'skillToLearn', allowEmpty: false),
      skillToOffer: _requiredString(data, 'skillToOffer', allowEmpty: false),
      proposedAt: _requiredTimestamp(data, 'proposedAt').toDate().toUtc(),
      mode: _requiredString(data, 'mode', allowEmpty: false),
      meetingDetails: _optionalString(data, 'meetingDetails'),
      note: _optionalString(data, 'note'),
      status: _requiredString(data, 'status', allowEmpty: false),
      createdAt: _requiredTimestamp(data, 'createdAt').toDate().toUtc(),
      updatedAt: _requiredTimestamp(data, 'updatedAt').toDate().toUtc(),
    );
  }

  // ============================================================
  // FIELD PARSING HELPERS
  // ============================================================

  String _requireDocumentId(String id) {
    final String clean = id.trim();
    if (clean.isEmpty) {
      throw const FirestoreSwapRepositoryException(
        'A cloud swap request has an invalid document ID.',
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
      throw FirestoreSwapRepositoryException(
        'Cloud swap request field "$key" is invalid.',
      );
    }
    return value.trim();
  }

  String? _optionalString(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FirestoreSwapRepositoryException(
        'Cloud swap request field "$key" is invalid.',
      );
    }
    final String clean = value.trim();
    return clean.isEmpty ? null : clean;
  }

  Timestamp _requiredTimestamp(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! Timestamp) {
      throw FirestoreSwapRepositoryException(
        'Cloud swap request field "$key" is invalid.',
      );
    }
    return value;
  }

  String _requireNonEmpty(String value, String label) {
    final String clean = value.trim();
    if (clean.isEmpty) {
      throw FirestoreSwapRepositoryException('$label is required.');
    }
    return clean;
  }

  String? _normalizeNullable(String? value) {
    if (value == null) {
      return null;
    }
    final String clean = value.trim();
    return clean.isEmpty ? null : clean;
  }

  String _requireUid(String uid) {
    final String clean = uid.trim();
    if (clean.isEmpty || clean == _legacyLocalUid) {
      throw const FirestoreSwapRepositoryException(
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
