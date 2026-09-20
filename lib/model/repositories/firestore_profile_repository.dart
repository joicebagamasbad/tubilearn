import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProfileRepositoryException implements Exception {
  final String message;

  const FirestoreProfileRepositoryException(this.message);

  @override
  String toString() => message;
}

enum FirestoreProfileLookupStatus {
  serverDocument,
  cachedDocument,
  confirmedServerAbsent,
  unavailable,
}

class FirestoreProfileData {
  final String name;
  final String city;
  final String bio;
  final String availability;
  final String language;
  final String preferredMode;
  final String teachingStyle;
  final String memberSince;
  final bool profileCompleted;
  final int schemaVersion;
  final int skillsBootstrapVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FirestoreProfileData({
    required this.name,
    required this.city,
    required this.bio,
    required this.availability,
    required this.language,
    required this.preferredMode,
    required this.teachingStyle,
    required this.memberSince,
    required this.profileCompleted,
    required this.schemaVersion,
    required this.skillsBootstrapVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  FirestoreProfileData copyWith({
    String? name,
    String? city,
    String? bio,
    String? availability,
    String? language,
    String? preferredMode,
    String? teachingStyle,
    String? memberSince,
    bool? profileCompleted,
    int? schemaVersion,
    int? skillsBootstrapVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FirestoreProfileData(
      name: name ?? this.name,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      availability: availability ?? this.availability,
      language: language ?? this.language,
      preferredMode: preferredMode ?? this.preferredMode,
      teachingStyle: teachingStyle ?? this.teachingStyle,
      memberSince: memberSince ?? this.memberSince,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      skillsBootstrapVersion:
          skillsBootstrapVersion ?? this.skillsBootstrapVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FirestoreProfileLookup {
  final FirestoreProfileLookupStatus status;
  final FirestoreProfileData? profile;

  const FirestoreProfileLookup._(this.status, this.profile);

  const FirestoreProfileLookup.server(FirestoreProfileData profile)
    : this._(FirestoreProfileLookupStatus.serverDocument, profile);

  const FirestoreProfileLookup.cache(FirestoreProfileData profile)
    : this._(FirestoreProfileLookupStatus.cachedDocument, profile);

  const FirestoreProfileLookup.absent()
    : this._(FirestoreProfileLookupStatus.confirmedServerAbsent, null);

  const FirestoreProfileLookup.unavailable()
    : this._(FirestoreProfileLookupStatus.unavailable, null);

  bool get hasDocument => profile != null;
}

class FirestoreProfileRepository {
  FirestoreProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final FirestoreProfileRepository instance =
      FirestoreProfileRepository();

  static const int schemaVersion = 1;
  static const int skillsBootstrapVersion = 1;

  final FirebaseFirestore _firestore;

  Future<FirestoreProfileLookup> lookup(String uid) async {
    final String cleanUid = _requireUid(uid);
    final DocumentReference<Map<String, dynamic>> reference = _firestore
        .collection('users')
        .doc(cleanUid);

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await reference
          .get(const GetOptions(source: Source.server));
      if (!snapshot.exists) {
        return const FirestoreProfileLookup.absent();
      }
      return FirestoreProfileLookup.server(_parseSnapshot(snapshot));
    } on FirestoreProfileRepositoryException {
      rethrow;
    } on FirebaseException catch (error) {
      if (!_isAvailabilityFailure(error)) {
        throw const FirestoreProfileRepositoryException(
          'Your cloud profile could not be loaded. Please try again.',
        );
      }
    } catch (_) {
      throw const FirestoreProfileRepositoryException(
        'Your cloud profile could not be loaded. Please try again.',
      );
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> cached = await reference.get(
        const GetOptions(source: Source.cache),
      );
      if (cached.exists) {
        return FirestoreProfileLookup.cache(_parseSnapshot(cached));
      }
    } catch (_) {
      // Cache uncertainty is represented as unavailable, never absent.
    }
    return const FirestoreProfileLookup.unavailable();
  }

  Future<void> createInitialProfile({
    required String uid,
    required String sourceUid,
    required FirestoreProfileData profile,
  }) async {
    final String cleanUid = _requireUid(uid);
    if (_requireUid(sourceUid) != cleanUid) {
      throw const FirestoreProfileRepositoryException(
        'Only the same authenticated local profile can be migrated.',
      );
    }
    _validateEditableProfile(profile);
    final DocumentReference<Map<String, dynamic>> reference = _firestore
        .collection('users')
        .doc(cleanUid);

    try {
      await _firestore.runTransaction<void>((Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> existing =
            await transaction.get(reference);
        if (existing.exists) {
          throw const FirestoreProfileRepositoryException(
            'A cloud profile already exists for this account.',
          );
        }
        transaction.set(reference, <String, Object?>{
          ..._editableFields(profile),
          'schemaVersion': schemaVersion,
          'skillsBootstrapVersion': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirestoreProfileRepositoryException {
      rethrow;
    } on FirebaseException {
      throw const FirestoreProfileRepositoryException(
        'Your cloud profile could not be created. Please try again.',
      );
    } catch (_) {
      throw const FirestoreProfileRepositoryException(
        'Your cloud profile could not be created. Please try again.',
      );
    }
  }

  Future<FirestoreProfileData> updateEditableProfile({
    required String uid,
    required String name,
    required String city,
    required String bio,
    required String availability,
    required String language,
    required String preferredMode,
    required String teachingStyle,
  }) async {
    final String cleanUid = _requireUid(uid);
    final DocumentReference<Map<String, dynamic>> reference = _firestore
        .collection('users')
        .doc(cleanUid);

    try {
      return await _firestore.runTransaction<FirestoreProfileData>((
        Transaction transaction,
      ) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(reference);
        if (!snapshot.exists) {
          throw const FirestoreProfileRepositoryException(
            'Your cloud profile could not be found.',
          );
        }
        final FirestoreProfileData current = _parseSnapshot(snapshot);
        final FirestoreProfileData updated = current.copyWith(
          name: name.trim(),
          city: city.trim(),
          bio: bio.trim(),
          availability: availability.trim(),
          language: language.trim(),
          preferredMode: preferredMode.trim(),
          teachingStyle: teachingStyle.trim(),
          profileCompleted: true,
          updatedAt: DateTime.now().toUtc(),
        );
        _validateEditableProfile(updated);
        transaction.update(reference, <String, Object?>{
          ..._editableFields(updated),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return updated;
      });
    } on FirestoreProfileRepositoryException {
      rethrow;
    } on FirebaseException {
      throw const FirestoreProfileRepositoryException(
        'Your cloud profile could not be saved. Please try again.',
      );
    } catch (_) {
      throw const FirestoreProfileRepositoryException(
        'Your cloud profile could not be saved. Please try again.',
      );
    }
  }

  Future<void> markSkillsBootstrapComplete(String uid) async {
    final String cleanUid = _requireUid(uid);
    final DocumentReference<Map<String, dynamic>> reference = _firestore
        .collection('users')
        .doc(cleanUid);
    try {
      await _firestore.runTransaction<void>((Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(reference);
        if (!snapshot.exists) {
          throw const FirestoreProfileRepositoryException(
            'Your cloud profile could not be found.',
          );
        }
        _parseSnapshot(snapshot);
        transaction.update(reference, <String, Object?>{
          'skillsBootstrapVersion': skillsBootstrapVersion,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirestoreProfileRepositoryException {
      rethrow;
    } on FirebaseException {
      throw const FirestoreProfileRepositoryException(
        'Your skills migration could not be completed. Please try again.',
      );
    } catch (_) {
      throw const FirestoreProfileRepositoryException(
        'Your skills migration could not be completed. Please try again.',
      );
    }
  }

  Map<String, Object?> _editableFields(FirestoreProfileData profile) {
    return <String, Object?>{
      'name': profile.name.trim(),
      'city': profile.city.trim(),
      'bio': profile.bio.trim(),
      'availability': profile.availability.trim(),
      'language': profile.language.trim(),
      'preferredMode': profile.preferredMode.trim(),
      'teachingStyle': profile.teachingStyle.trim(),
      'memberSince': profile.memberSince.trim(),
      'profileCompleted': profile.profileCompleted,
    };
  }

  FirestoreProfileData _parseSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic>? data = snapshot.data();
    if (data == null) {
      throw const FirestoreProfileRepositoryException(
        'The cloud profile is empty or invalid.',
      );
    }
    final FirestoreProfileData profile = FirestoreProfileData(
      name: _requiredString(data, 'name', allowEmpty: false),
      city: _requiredString(data, 'city', allowEmpty: false),
      bio: _requiredString(data, 'bio', allowEmpty: true),
      availability: _requiredString(data, 'availability', allowEmpty: false),
      language: _requiredString(data, 'language', allowEmpty: false),
      preferredMode: _requiredString(data, 'preferredMode', allowEmpty: false),
      teachingStyle: _requiredString(data, 'teachingStyle', allowEmpty: false),
      memberSince: _requiredString(data, 'memberSince', allowEmpty: false),
      profileCompleted: _requiredBool(data, 'profileCompleted'),
      schemaVersion: _requiredInt(data, 'schemaVersion'),
      skillsBootstrapVersion: data.containsKey('skillsBootstrapVersion')
          ? _requiredInt(data, 'skillsBootstrapVersion')
          : 0,
      createdAt: _requiredTimestamp(data, 'createdAt').toDate().toUtc(),
      updatedAt: _requiredTimestamp(data, 'updatedAt').toDate().toUtc(),
    );
    if (profile.schemaVersion != schemaVersion ||
        profile.skillsBootstrapVersion < 0) {
      throw const FirestoreProfileRepositoryException(
        'The cloud profile uses an unsupported data version.',
      );
    }
    _validateEditableProfile(profile, allowIncompleteBio: true);
    return profile;
  }

  void _validateEditableProfile(
    FirestoreProfileData profile, {
    bool allowIncompleteBio = true,
  }) {
    _validateText(profile.name, 'Name', maxLength: 80);
    _validateText(profile.city, 'City', maxLength: 100);
    _validateText(
      profile.bio,
      'Bio',
      maxLength: 500,
      allowEmpty: allowIncompleteBio && !profile.profileCompleted,
    );
    _validateText(profile.availability, 'Availability');
    _validateText(profile.language, 'Language');
    _validateText(profile.preferredMode, 'Preferred mode');
    _validateText(profile.teachingStyle, 'Teaching style');
    _validateText(profile.memberSince, 'Member since');
  }

  void _validateText(
    String value,
    String label, {
    int? maxLength,
    bool allowEmpty = false,
  }) {
    final String clean = value.trim();
    if (!allowEmpty && clean.isEmpty) {
      throw FirestoreProfileRepositoryException('$label is required.');
    }
    if (maxLength != null && clean.length > maxLength) {
      throw FirestoreProfileRepositoryException(
        '$label must be $maxLength characters or less.',
      );
    }
  }

  String _requireUid(String uid) {
    final String clean = uid.trim();
    if (clean.isEmpty || clean == 'user_joice_local') {
      throw const FirestoreProfileRepositoryException(
        'A valid authenticated user ID is required.',
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
      throw FirestoreProfileRepositoryException(
        'Cloud profile field "$key" is invalid.',
      );
    }
    return value.trim();
  }

  bool _requiredBool(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! bool) {
      throw FirestoreProfileRepositoryException(
        'Cloud profile field "$key" is invalid.',
      );
    }
    return value;
  }

  int _requiredInt(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! int) {
      throw FirestoreProfileRepositoryException(
        'Cloud profile field "$key" is invalid.',
      );
    }
    return value;
  }

  Timestamp _requiredTimestamp(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! Timestamp) {
      throw FirestoreProfileRepositoryException(
        'Cloud profile field "$key" is invalid.',
      );
    }
    return value;
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
