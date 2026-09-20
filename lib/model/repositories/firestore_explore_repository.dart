import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreExploreRepositoryException implements Exception {
  final String message;

  const FirestoreExploreRepositoryException(this.message);

  @override
  String toString() => message;
}

enum FirestoreExploreSource { server, cache, unavailable }

enum FirestoreExploreSkillLinkType { offered, wanted }

class FirestoreExploreUserRecord {
  final String uid;
  final String name;
  final String initials;
  final String city;
  final String bio;
  final double rating;
  final int reviewCount;
  final int completedSwaps;
  final int responseRate;
  final String memberSince;
  final String availability;
  final String language;
  final String preferredMode;
  final String teachingStyle;
  final bool emailVerified;
  final bool profileCompleted;
  final String? profileImagePath;
  final int schemaVersion;
  final int skillsBootstrapVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FirestoreExploreUserRecord({
    required this.uid,
    required this.name,
    required this.initials,
    required this.city,
    required this.bio,
    required this.rating,
    required this.reviewCount,
    required this.completedSwaps,
    required this.responseRate,
    required this.memberSince,
    required this.availability,
    required this.language,
    required this.preferredMode,
    required this.teachingStyle,
    required this.emailVerified,
    required this.profileCompleted,
    required this.profileImagePath,
    required this.schemaVersion,
    required this.skillsBootstrapVersion,
    required this.createdAt,
    required this.updatedAt,
  });
}

class FirestoreExploreSkillRecord {
  final String skillId;
  final String? ownerUid;
  final String title;
  final String titleKey;
  final String category;
  final String level;
  final int iconCodePoint;
  final String sessionLength;
  final String mode;
  final String language;
  final String prerequisite;
  final String description;
  final List<String> learnings;
  final int linkCount;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  FirestoreExploreSkillRecord({
    required this.skillId,
    required this.ownerUid,
    required this.title,
    required this.titleKey,
    required this.category,
    required this.level,
    required this.iconCodePoint,
    required this.sessionLength,
    required this.mode,
    required this.language,
    required this.prerequisite,
    required this.description,
    required List<String> learnings,
    required this.linkCount,
    required this.schemaVersion,
    required this.createdAt,
    required this.updatedAt,
  }) : learnings = List<String>.unmodifiable(learnings);
}

class FirestoreExploreSkillLinkRecord {
  final String relationshipId;
  final String userUid;
  final String skillId;
  final FirestoreExploreSkillLinkType type;
  final String level;
  final String availability;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FirestoreExploreSkillLinkRecord({
    required this.relationshipId,
    required this.userUid,
    required this.skillId,
    required this.type,
    required this.level,
    required this.availability,
    required this.schemaVersion,
    required this.createdAt,
    required this.updatedAt,
  });
}

class FirestoreExploreSnapshot {
  final FirestoreExploreSource source;
  final List<FirestoreExploreUserRecord> users;
  final List<FirestoreExploreSkillRecord> skills;
  final List<FirestoreExploreSkillLinkRecord> skillLinks;

  FirestoreExploreSnapshot({
    required this.source,
    required List<FirestoreExploreUserRecord> users,
    required List<FirestoreExploreSkillRecord> skills,
    required List<FirestoreExploreSkillLinkRecord> skillLinks,
  }) : users = List<FirestoreExploreUserRecord>.unmodifiable(users),
       skills = List<FirestoreExploreSkillRecord>.unmodifiable(skills),
       skillLinks = List<FirestoreExploreSkillLinkRecord>.unmodifiable(
         skillLinks,
       );

  const FirestoreExploreSnapshot.unavailable()
    : source = FirestoreExploreSource.unavailable,
      users = const <FirestoreExploreUserRecord>[],
      skills = const <FirestoreExploreSkillRecord>[],
      skillLinks = const <FirestoreExploreSkillLinkRecord>[];

  bool get isConfirmedServer => source == FirestoreExploreSource.server;
}

class FirestoreExploreRepository {
  FirestoreExploreRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final FirestoreExploreRepository instance =
      FirestoreExploreRepository();

  static const int profileSchemaVersion = 1;
  static const int skillSchemaVersion = 1;
  static const String legacyLocalUid = 'user_joice_local';

  final FirebaseFirestore _firestore;

  Future<FirestoreExploreSnapshot> load(String activeUid) async {
    final String cleanActiveUid = _requireActiveUid(activeUid);

    try {
      return await _loadFromSource(cleanActiveUid, Source.server);
    } on FirestoreExploreRepositoryException {
      rethrow;
    } on FirebaseException catch (error) {
      if (!_isAvailabilityFailure(error)) {
        throw const FirestoreExploreRepositoryException(
          'Remote Explore data could not be loaded. Please try again.',
        );
      }
    } catch (_) {
      throw const FirestoreExploreRepositoryException(
        'Remote Explore data could not be loaded. Please try again.',
      );
    }

    try {
      return await _loadFromSource(cleanActiveUid, Source.cache);
    } catch (_) {
      return const FirestoreExploreSnapshot.unavailable();
    }
  }

  Future<FirestoreExploreSnapshot> _loadFromSource(
    String activeUid,
    Source source,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> userSnapshots = await _firestore
        .collection('users')
        .where('profileCompleted', isEqualTo: true)
        .get(GetOptions(source: source));

    if (source == Source.cache && userSnapshots.docs.isEmpty) {
      return const FirestoreExploreSnapshot.unavailable();
    }

    final List<FirestoreExploreUserRecord> users =
        <FirestoreExploreUserRecord>[];
    final Set<String> userIds = <String>{};

    for (final QueryDocumentSnapshot<Map<String, dynamic>> snapshot
        in userSnapshots.docs) {
      final String uid = _requireDocumentId(snapshot.id, 'Remote user ID');
      if (uid == activeUid || uid == legacyLocalUid) {
        continue;
      }
      if (!userIds.add(uid)) {
        throw const FirestoreExploreRepositoryException(
          'Remote Explore contains duplicate user IDs.',
        );
      }
      users.add(_parseUser(snapshot));
    }

    if (source == Source.cache && users.isEmpty) {
      return const FirestoreExploreSnapshot.unavailable();
    }

    final List<List<FirestoreExploreSkillLinkRecord>> linksByUser =
        await Future.wait(
          users.map(
            (FirestoreExploreUserRecord user) => _loadLinks(
              user.uid,
              source,
            ),
          ),
        );
    if (source == Source.cache &&
        linksByUser.any(
          (List<FirestoreExploreSkillLinkRecord> links) => links.isEmpty,
        )) {
      return const FirestoreExploreSnapshot.unavailable();
    }
    final List<FirestoreExploreSkillLinkRecord> skillLinks = linksByUser
        .expand((List<FirestoreExploreSkillLinkRecord> links) => links)
        .toList(growable: false);

    final List<String> skillIds = skillLinks
        .map((FirestoreExploreSkillLinkRecord link) => link.skillId)
        .toSet()
        .toList(growable: false)
      ..sort();
    final List<DocumentSnapshot<Map<String, dynamic>>> skillSnapshots =
        await Future.wait(
          skillIds.map(
            (String skillId) => _firestore
                .collection('skills')
                .doc(skillId)
                .get(GetOptions(source: source)),
          ),
        );

    final List<FirestoreExploreSkillRecord> skills =
        <FirestoreExploreSkillRecord>[];
    final Set<String> loadedSkillIds = <String>{};
    for (final DocumentSnapshot<Map<String, dynamic>> snapshot
        in skillSnapshots) {
      if (!snapshot.exists) {
        throw const FirestoreExploreRepositoryException(
          'A remote skill relationship points to a missing catalog entry.',
        );
      }
      final FirestoreExploreSkillRecord skill = _parseSkill(snapshot);
      if (!loadedSkillIds.add(skill.skillId)) {
        throw const FirestoreExploreRepositoryException(
          'Remote Explore contains duplicate skill IDs.',
        );
      }
      skills.add(skill);
    }

    for (final FirestoreExploreSkillLinkRecord link in skillLinks) {
      if (!loadedSkillIds.contains(link.skillId)) {
        throw const FirestoreExploreRepositoryException(
          'A remote skill relationship could not be resolved.',
        );
      }
    }

    users.sort(
      (FirestoreExploreUserRecord first, FirestoreExploreUserRecord second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );
    skills.sort(
      (
        FirestoreExploreSkillRecord first,
        FirestoreExploreSkillRecord second,
      ) => first.title.toLowerCase().compareTo(second.title.toLowerCase()),
    );
    skillLinks.sort((
      FirestoreExploreSkillLinkRecord first,
      FirestoreExploreSkillLinkRecord second,
    ) {
      final int userComparison = first.userUid.compareTo(second.userUid);
      if (userComparison != 0) return userComparison;
      return first.relationshipId.compareTo(second.relationshipId);
    });

    return FirestoreExploreSnapshot(
      source: source == Source.server
          ? FirestoreExploreSource.server
          : FirestoreExploreSource.cache,
      users: users,
      skills: skills,
      skillLinks: skillLinks,
    );
  }

  Future<List<FirestoreExploreSkillLinkRecord>> _loadLinks(
    String uid,
    Source source,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshots = await _firestore
        .collection('users')
        .doc(uid)
        .collection('skillLinks')
        .get(GetOptions(source: source));
    final List<FirestoreExploreSkillLinkRecord> links =
        <FirestoreExploreSkillLinkRecord>[];
    final Set<String> relationshipIds = <String>{};
    final Set<String> relationshipKeys = <String>{};

    for (final QueryDocumentSnapshot<Map<String, dynamic>> snapshot
        in snapshots.docs) {
      final FirestoreExploreSkillLinkRecord link = _parseLink(uid, snapshot);
      final String key = '${link.skillId}:${link.type.name}';
      if (!relationshipIds.add(link.relationshipId) ||
          !relationshipKeys.add(key)) {
        throw const FirestoreExploreRepositoryException(
          'Remote Explore contains duplicate skill relationships.',
        );
      }
      links.add(link);
    }
    return links;
  }

  FirestoreExploreUserRecord _parseUser(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final String uid = _requireDocumentId(snapshot.id, 'Remote user ID');
    final Map<String, dynamic>? data = snapshot.data();
    if (data == null) {
      throw const FirestoreExploreRepositoryException(
        'A remote Explore profile is empty or invalid.',
      );
    }
    final String name = _requiredString(data, 'name', maxLength: 80);
    final String city = _requiredString(data, 'city', maxLength: 100);
    final String bio = _requiredString(data, 'bio', maxLength: 500);
    final bool profileCompleted = _requiredBool(data, 'profileCompleted');
    if (!profileCompleted) {
      throw const FirestoreExploreRepositoryException(
        'An ineligible profile was returned as a remote Explore candidate.',
      );
    }
    final int schemaVersion = _requiredInt(data, 'schemaVersion');
    final int skillsBootstrapVersion = data.containsKey(
      'skillsBootstrapVersion',
    )
        ? _requiredInt(data, 'skillsBootstrapVersion')
        : 0;
    if (schemaVersion != profileSchemaVersion || skillsBootstrapVersion < 0) {
      throw const FirestoreExploreRepositoryException(
        'A remote Explore profile uses an unsupported data version.',
      );
    }

    return FirestoreExploreUserRecord(
      uid: uid,
      name: name,
      initials: _buildInitials(name),
      city: city,
      bio: bio,
      rating: 0,
      reviewCount: 0,
      completedSwaps: 0,
      responseRate: 0,
      memberSince: _requiredString(data, 'memberSince'),
      availability: _requiredString(data, 'availability'),
      language: _requiredString(data, 'language'),
      preferredMode: _requiredString(data, 'preferredMode'),
      teachingStyle: _requiredString(data, 'teachingStyle'),
      emailVerified: false,
      profileCompleted: profileCompleted,
      profileImagePath: null,
      schemaVersion: schemaVersion,
      skillsBootstrapVersion: skillsBootstrapVersion,
      createdAt: _requiredTimestamp(data, 'createdAt').toDate().toUtc(),
      updatedAt: _requiredTimestamp(data, 'updatedAt').toDate().toUtc(),
    );
  }

  FirestoreExploreSkillLinkRecord _parseLink(
    String uid,
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final String relationshipId = _requireDocumentId(
      snapshot.id,
      'Remote skill relationship ID',
    );
    final Map<String, dynamic>? data = snapshot.data();
    if (data == null) {
      throw const FirestoreExploreRepositoryException(
        'A remote skill relationship is empty or invalid.',
      );
    }
    final FirestoreExploreSkillLinkType type;
    switch (_requiredString(data, 'type')) {
      case 'offered':
        type = FirestoreExploreSkillLinkType.offered;
        break;
      case 'wanted':
        type = FirestoreExploreSkillLinkType.wanted;
        break;
      default:
        throw const FirestoreExploreRepositoryException(
          'A remote skill relationship type is invalid.',
        );
    }
    final int schemaVersion = _requiredInt(data, 'schemaVersion');
    if (schemaVersion != skillSchemaVersion) {
      throw const FirestoreExploreRepositoryException(
        'A remote skill relationship version is unsupported.',
      );
    }

    return FirestoreExploreSkillLinkRecord(
      relationshipId: relationshipId,
      userUid: uid,
      skillId: _requiredDocumentReferenceId(data, 'skillId'),
      type: type,
      level: _requiredExperienceLevel(data, 'level'),
      availability: _requiredString(data, 'availability'),
      schemaVersion: schemaVersion,
      createdAt: _requiredTimestamp(data, 'createdAt').toDate().toUtc(),
      updatedAt: _requiredTimestamp(data, 'updatedAt').toDate().toUtc(),
    );
  }

  FirestoreExploreSkillRecord _parseSkill(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final String skillId = _requireDocumentId(snapshot.id, 'Remote skill ID');
    final Map<String, dynamic>? data = snapshot.data();
    if (data == null) {
      throw const FirestoreExploreRepositoryException(
        'A remote skill is empty or invalid.',
      );
    }
    final String? ownerUid = _nullableUid(data, 'ownerUid');
    final String title = _requiredString(data, 'title', maxLength: 80);
    final String titleKey = _requiredString(data, 'titleKey');
    if (titleKey != _normalizeTitle(title)) {
      throw const FirestoreExploreRepositoryException(
        'A remote skill title normalization is invalid.',
      );
    }
    final int schemaVersion = _requiredInt(data, 'schemaVersion');
    final int linkCount = _requiredInt(data, 'linkCount');
    if (schemaVersion != skillSchemaVersion || linkCount < 0) {
      throw const FirestoreExploreRepositoryException(
        'A remote skill version or reference count is invalid.',
      );
    }

    return FirestoreExploreSkillRecord(
      skillId: skillId,
      ownerUid: ownerUid,
      title: title,
      titleKey: titleKey,
      category: _requiredString(data, 'category'),
      level: _requiredString(data, 'level'),
      iconCodePoint: _positiveInt(data, 'iconCodePoint'),
      sessionLength: _requiredString(data, 'sessionLength'),
      mode: _requiredString(data, 'mode'),
      language: _requiredString(data, 'language'),
      prerequisite: _requiredString(data, 'prerequisite', allowEmpty: true),
      description: _requiredString(data, 'description'),
      learnings: _requiredStringList(data, 'learnings'),
      linkCount: linkCount,
      schemaVersion: schemaVersion,
      createdAt: _requiredTimestamp(data, 'createdAt').toDate().toUtc(),
      updatedAt: _requiredTimestamp(data, 'updatedAt').toDate().toUtc(),
    );
  }

  String _requireActiveUid(String uid) {
    final String clean = uid.trim();
    if (clean.isEmpty || clean != uid || clean == legacyLocalUid) {
      throw const FirestoreExploreRepositoryException(
        'A valid authenticated Firebase user ID is required.',
      );
    }
    return clean;
  }

  String _requireDocumentId(String value, String label) {
    final String clean = value.trim();
    if (clean.isEmpty || clean != value) {
      throw FirestoreExploreRepositoryException('$label is invalid.');
    }
    return clean;
  }

  String _requiredDocumentReferenceId(
    Map<String, dynamic> data,
    String key,
  ) {
    return _requireDocumentId(_requiredString(data, key), 'Remote $key');
  }

  String? _nullableUid(Map<String, dynamic> data, String key) {
    if (!data.containsKey(key)) {
      throw FirestoreExploreRepositoryException(
        'Remote skill field "$key" is missing.',
      );
    }
    final Object? value = data[key];
    if (value == null) return null;
    if (value is! String) {
      throw FirestoreExploreRepositoryException(
        'Remote skill field "$key" is invalid.',
      );
    }
    final String uid = _requireDocumentId(value, 'Remote skill owner UID');
    if (uid == legacyLocalUid) {
      throw const FirestoreExploreRepositoryException(
        'Legacy local skill ownership is invalid in remote Explore data.',
      );
    }
    return uid;
  }

  String _requiredString(
    Map<String, dynamic> data,
    String key, {
    bool allowEmpty = false,
    int? maxLength,
  }) {
    final Object? value = data[key];
    if (value is! String) {
      throw FirestoreExploreRepositoryException(
        'Remote field "$key" is invalid.',
      );
    }
    final String clean = value.trim();
    if ((!allowEmpty && clean.isEmpty) ||
        (maxLength != null && clean.length > maxLength)) {
      throw FirestoreExploreRepositoryException(
        'Remote field "$key" is invalid.',
      );
    }
    return clean;
  }

  String _requiredExperienceLevel(Map<String, dynamic> data, String key) {
    final String value = _requiredString(data, key);
    if (!const <String>{'Beginner', 'Intermediate', 'Advanced'}.contains(value)) {
      throw FirestoreExploreRepositoryException(
        'Remote field "$key" is invalid.',
      );
    }
    return value;
  }

  bool _requiredBool(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! bool) {
      throw FirestoreExploreRepositoryException(
        'Remote field "$key" is invalid.',
      );
    }
    return value;
  }

  int _requiredInt(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! int) {
      throw FirestoreExploreRepositoryException(
        'Remote field "$key" is invalid.',
      );
    }
    return value;
  }

  int _positiveInt(Map<String, dynamic> data, String key) {
    final int value = _requiredInt(data, key);
    if (value <= 0) {
      throw FirestoreExploreRepositoryException(
        'Remote field "$key" is invalid.',
      );
    }
    return value;
  }

  Timestamp _requiredTimestamp(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! Timestamp) {
      throw FirestoreExploreRepositoryException(
        'Remote field "$key" is invalid.',
      );
    }
    return value;
  }

  List<String> _requiredStringList(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! List) {
      throw FirestoreExploreRepositoryException(
        'Remote field "$key" is invalid.',
      );
    }
    final List<String> result = <String>[];
    for (final Object? item in value) {
      if (item is! String || item.trim().isEmpty) {
        throw FirestoreExploreRepositoryException(
          'Remote field "$key" is invalid.',
        );
      }
      result.add(item.trim());
    }
    return result;
  }

  String _buildInitials(String name) {
    final List<String> words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  String _normalizeTitle(String title) => title.trim().toLowerCase();

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
