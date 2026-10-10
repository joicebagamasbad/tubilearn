import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreReviewRepositoryException implements Exception {
  final String message;

  const FirestoreReviewRepositoryException(this.message);

  @override
  String toString() => message;
}

enum FirestoreReviewSource { server, cache, unavailable }

/// One review document as stored in Firestore. Reviews are immutable —
/// one per (swapRequestId, reviewerUid) pair, enforced by the
/// deterministic document ID.
class FirestoreReviewRecord {
  final String id;
  final String swapRequestId;
  final String reviewerUid;
  final String revieweeUid;
  final String reviewerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const FirestoreReviewRecord({
    required this.id,
    required this.swapRequestId,
    required this.reviewerUid,
    required this.revieweeUid,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

class FirestoreReviewSnapshot {
  final FirestoreReviewSource source;
  final List<FirestoreReviewRecord> reviews;

  const FirestoreReviewSnapshot({
    required this.source,
    required this.reviews,
  });

  const FirestoreReviewSnapshot.unavailable()
    : source = FirestoreReviewSource.unavailable,
      reviews = const <FirestoreReviewRecord>[];
}

class FirestoreReviewRepository {
  FirestoreReviewRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final FirestoreReviewRepository instance =
      FirestoreReviewRepository();

  static const String _collectionPath = 'reviews';
  static const String _legacyLocalUid = 'user_joice_local';
  static const int _maxReviewerNameLength = 80;
  static const int _maxCommentLength = 500;

  final FirebaseFirestore _firestore;

  // ============================================================
  // CREATE
  // ============================================================

  Future<String> createReview({
    required String swapRequestId,
    required String reviewerUid,
    required String revieweeUid,
    required String reviewerName,
    required int rating,
    String? comment,
  }) async {
    final String cleanSwapRequestId = _requireNonEmpty(
      swapRequestId,
      'Swap request ID',
    );
    final String cleanReviewerUid = _requireUid(reviewerUid);
    final String cleanRevieweeUid = _requireUid(revieweeUid);

    if (cleanReviewerUid == cleanRevieweeUid) {
      throw const FirestoreReviewRepositoryException(
        'You cannot review yourself.',
      );
    }

    final String cleanReviewerName = _requireNonEmpty(
      reviewerName,
      'Reviewer name',
    );

    if (cleanReviewerName.length > _maxReviewerNameLength) {
      throw const FirestoreReviewRepositoryException(
        'Reviewer name must be 80 characters or less.',
      );
    }

    if (rating < 1 || rating > 5) {
      throw const FirestoreReviewRepositoryException(
        'Rating must be between 1 and 5 stars.',
      );
    }

    final String? cleanComment = _normalizeComment(comment);

    final String documentId = reviewDocumentId(
      cleanSwapRequestId,
      cleanReviewerUid,
    );
    final DocumentReference<Map<String, dynamic>> reference = _firestore
        .collection(_collectionPath)
        .doc(documentId);

    try {
      await _firestore.runTransaction<void>((Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> existing =
            await transaction.get(reference);

        if (existing.exists) {
          throw const FirestoreReviewRepositoryException(
            'You have already reviewed this swap.',
          );
        }

        transaction.set(reference, <String, Object?>{
          'swapRequestId': cleanSwapRequestId,
          'reviewerUid': cleanReviewerUid,
          'revieweeUid': cleanRevieweeUid,
          'reviewerName': cleanReviewerName,
          'rating': rating,
          'comment': ?cleanComment,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      return documentId;
    } on FirestoreReviewRepositoryException {
      rethrow;
    } on FirebaseException {
      throw const FirestoreReviewRepositoryException(
        'Your review could not be submitted. Please try again.',
      );
    } catch (_) {
      throw const FirestoreReviewRepositoryException(
        'Your review could not be submitted. Please try again.',
      );
    }
  }

  // ============================================================
  // READ
  // ============================================================

  Future<FirestoreReviewSnapshot> getReviewsReceivedBy(String uid) async {
    final String cleanUid = _requireUid(uid);

    try {
      return await _loadFromSource(cleanUid, Source.server);
    } on FirestoreReviewRepositoryException {
      rethrow;
    } on FirebaseException catch (error) {
      if (!_isAvailabilityFailure(error)) {
        throw const FirestoreReviewRepositoryException(
          'Reviews could not be loaded. Please try again.',
        );
      }
    } catch (_) {
      throw const FirestoreReviewRepositoryException(
        'Reviews could not be loaded. Please try again.',
      );
    }

    try {
      return await _loadFromSource(cleanUid, Source.cache);
    } catch (_) {
      return const FirestoreReviewSnapshot.unavailable();
    }
  }

  Future<FirestoreReviewSnapshot> _loadFromSource(
    String uid,
    Source source,
  ) async {
    // No orderBy here: sorting by createdAt in the query would need a
    // composite index (on revieweeUid + createdAt). Sorting the already
    // -small per-user result set in Dart avoids that entirely.
    final QuerySnapshot<Map<String, dynamic>> results = await _firestore
        .collection(_collectionPath)
        .where('revieweeUid', isEqualTo: uid)
        .get(GetOptions(source: source));

    if (source == Source.cache && results.docs.isEmpty) {
      return const FirestoreReviewSnapshot.unavailable();
    }

    final List<FirestoreReviewRecord> reviews = results.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              _parseRecord(doc, uid),
        )
        .toList(growable: false);

    reviews.sort(
      (FirestoreReviewRecord a, FirestoreReviewRecord b) =>
          b.createdAt.compareTo(a.createdAt),
    );

    return FirestoreReviewSnapshot(
      source: source == Source.server
          ? FirestoreReviewSource.server
          : FirestoreReviewSource.cache,
      reviews: reviews,
    );
  }

  // ============================================================
  // DOCUMENT ID
  // ============================================================

  static String reviewDocumentId(String swapRequestId, String reviewerUid) {
    final String cleanSwapRequestId = _requireNonEmptyStatic(
      swapRequestId,
      'Swap request ID',
    );
    final String cleanReviewerUid = _requireUidStatic(reviewerUid);
    return '${cleanSwapRequestId}_$cleanReviewerUid';
  }

  // ============================================================
  // FIELD PARSING HELPERS
  // ============================================================

  FirestoreReviewRecord _parseRecord(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String requestedUid,
  ) {
    final Map<String, dynamic> data = doc.data();

    final String swapRequestId = _requiredString(
      data,
      'swapRequestId',
      allowEmpty: false,
    );
    final String reviewerUid = _requiredString(
      data,
      'reviewerUid',
      allowEmpty: false,
    );
    final String revieweeUid = _requiredString(
      data,
      'revieweeUid',
      allowEmpty: false,
    );

    if (revieweeUid != requestedUid) {
      throw const FirestoreReviewRepositoryException(
        'A cloud review does not belong to the requested user.',
      );
    }

    final String expectedId = reviewDocumentId(swapRequestId, reviewerUid);
    if (doc.id != expectedId) {
      throw const FirestoreReviewRepositoryException(
        'A cloud review ID does not match its swap and reviewer.',
      );
    }

    final String reviewerName = _requiredString(
      data,
      'reviewerName',
      allowEmpty: false,
    );

    final int rating = _requiredInt(data, 'rating');
    if (rating < 1 || rating > 5) {
      throw const FirestoreReviewRepositoryException(
        'A cloud review has an invalid rating.',
      );
    }

    final String? comment = _optionalString(data, 'comment');

    return FirestoreReviewRecord(
      id: doc.id,
      swapRequestId: swapRequestId,
      reviewerUid: reviewerUid,
      revieweeUid: revieweeUid,
      reviewerName: reviewerName,
      rating: rating,
      comment: comment,
      createdAt: _requiredTimestamp(data, 'createdAt').toDate().toUtc(),
    );
  }

  String _requiredString(
    Map<String, dynamic> data,
    String key, {
    required bool allowEmpty,
  }) {
    final Object? value = data[key];
    if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
      throw FirestoreReviewRepositoryException(
        'Cloud review field "$key" is invalid.',
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
      throw FirestoreReviewRepositoryException(
        'Cloud review field "$key" is invalid.',
      );
    }
    final String clean = value.trim();
    return clean.isEmpty ? null : clean;
  }

  int _requiredInt(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! int) {
      throw FirestoreReviewRepositoryException(
        'Cloud review field "$key" is invalid.',
      );
    }
    return value;
  }

  Timestamp _requiredTimestamp(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! Timestamp) {
      throw FirestoreReviewRepositoryException(
        'Cloud review field "$key" is invalid.',
      );
    }
    return value;
  }

  String? _normalizeComment(String? value) {
    if (value == null) {
      return null;
    }
    final String clean = value.trim();
    if (clean.isEmpty) {
      return null;
    }
    if (clean.length > _maxCommentLength) {
      throw const FirestoreReviewRepositoryException(
        'Review comment must be 500 characters or less.',
      );
    }
    return clean;
  }

  String _requireNonEmpty(String value, String label) =>
      _requireNonEmptyStatic(value, label);

  String _requireUid(String uid) => _requireUidStatic(uid);

  static String _requireNonEmptyStatic(String value, String label) {
    final String clean = value.trim();
    if (clean.isEmpty) {
      throw FirestoreReviewRepositoryException('$label is required.');
    }
    return clean;
  }

  static String _requireUidStatic(String uid) {
    final String clean = uid.trim();
    if (clean.isEmpty || clean == _legacyLocalUid) {
      throw const FirestoreReviewRepositoryException(
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
