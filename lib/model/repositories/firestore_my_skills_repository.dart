import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../skill.dart';
import '../user_skill.dart';

class FirestoreMySkillsRepositoryException implements Exception {
  final String message;

  const FirestoreMySkillsRepositoryException(this.message);

  @override
  String toString() => message;
}

enum FirestoreMySkillsSource { server, cache, unavailable }

class FirestoreSkillRecord {
  final Skill skill;
  final String? ownerUid;
  final int linkCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FirestoreSkillRecord({
    required this.skill,
    required this.ownerUid,
    required this.linkCount,
    required this.createdAt,
    required this.updatedAt,
  });
}

class FirestoreSkillLinkRecord {
  final UserSkill userSkill;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FirestoreSkillLinkRecord({
    required this.userSkill,
    required this.createdAt,
    required this.updatedAt,
  });
}

class FirestoreManagedSkillRecord {
  final FirestoreSkillRecord catalog;
  final FirestoreSkillLinkRecord link;

  const FirestoreManagedSkillRecord({
    required this.catalog,
    required this.link,
  });
}

class FirestoreMySkillsSnapshot {
  final FirestoreMySkillsSource source;
  final List<FirestoreManagedSkillRecord> records;

  const FirestoreMySkillsSnapshot({
    required this.source,
    required this.records,
  });

  const FirestoreMySkillsSnapshot.unavailable()
    : source = FirestoreMySkillsSource.unavailable,
      records = const <FirestoreManagedSkillRecord>[];
}

class FirestoreMySkillsRepository {
  FirestoreMySkillsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final FirestoreMySkillsRepository instance =
      FirestoreMySkillsRepository();

  static const int schemaVersion = 1;

  final FirebaseFirestore _firestore;

  Future<FirestoreMySkillsSnapshot> load(String uid) async {
    final String cleanUid = _requireUid(uid);
    try {
      return await _loadFromSource(cleanUid, Source.server);
    } on FirestoreMySkillsRepositoryException {
      rethrow;
    } on FirebaseException catch (error) {
      if (!_isAvailabilityFailure(error)) {
        throw const FirestoreMySkillsRepositoryException(
          'Your cloud skills could not be loaded. Please try again.',
        );
      }
    } catch (_) {
      throw const FirestoreMySkillsRepositoryException(
        'Your cloud skills could not be loaded. Please try again.',
      );
    }

    try {
      return await _loadFromSource(cleanUid, Source.cache);
    } catch (_) {
      return const FirestoreMySkillsSnapshot.unavailable();
    }
  }

  Future<void> bootstrapLink({
    required String uid,
    required Skill skill,
    required UserSkill userSkill,
    required String? ownerUid,
  }) async {
    await _createLink(
      uid: uid,
      proposedSkill: skill,
      proposedLink: userSkill,
      ownerUid: ownerUid,
      preserveProposedSkillId: true,
    );
  }

  Future<FirestoreManagedSkillRecord> createLink({
    required String uid,
    required Skill proposedSkill,
    required UserSkill proposedLink,
  }) {
    return _createLink(
      uid: uid,
      proposedSkill: proposedSkill,
      proposedLink: proposedLink,
      ownerUid: uid,
      preserveProposedSkillId: false,
    );
  }

  Future<void> updateLink({
    required String uid,
    required String userSkillId,
    required UserSkillType expectedType,
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
    required IconData icon,
  }) async {
    final String cleanUid = _requireUid(uid);
    final String cleanLinkId = _requiredText(userSkillId, 'Skill relationship');
    final String cleanTitle = _validatedTitle(title);
    final String cleanCategory = _requiredText(category, 'Category');
    final String cleanDescription = _validatedDescription(description);
    final String cleanLevel = _validatedLevel(level);
    final String cleanAvailability = _requiredText(
      availability,
      'Availability',
    );
    final DocumentReference<Map<String, dynamic>> linkReference = _firestore
        .collection('users')
        .doc(cleanUid)
        .collection('skillLinks')
        .doc(cleanLinkId);

    try {
      await _firestore.runTransaction<void>((Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> linkSnapshot =
            await transaction.get(linkReference);
        if (!linkSnapshot.exists) {
          throw const FirestoreMySkillsRepositoryException(
            'Skill relationship could not be found.',
          );
        }
        final FirestoreSkillLinkRecord existingLink = _parseLink(
          cleanUid,
          linkSnapshot,
        );
        if (existingLink.userSkill.type != expectedType) {
          throw const FirestoreMySkillsRepositoryException(
            'Skill relationship type does not match.',
          );
        }

        final DocumentReference<Map<String, dynamic>> skillReference =
            _firestore.collection('skills').doc(existingLink.userSkill.skillId);
        final DocumentSnapshot<Map<String, dynamic>> skillSnapshot =
            await transaction.get(skillReference);
        if (!skillSnapshot.exists) {
          throw const FirestoreMySkillsRepositoryException(
            'Skill catalog entry could not be found.',
          );
        }
        final FirestoreSkillRecord existingSkill = _parseSkill(skillSnapshot);
        final String oldKey = normalizeTitle(existingSkill.skill.title);
        final String newKey = normalizeTitle(cleanTitle);
        final DocumentReference<Map<String, dynamic>> oldKeyReference =
            _titleKeyReference(oldKey);
        final DocumentReference<Map<String, dynamic>> newKeyReference =
            _titleKeyReference(newKey);
        final DocumentSnapshot<Map<String, dynamic>> oldKeySnapshot =
            await transaction.get(oldKeyReference);
        final DocumentSnapshot<Map<String, dynamic>> newKeySnapshot =
            oldKeyReference.path == newKeyReference.path
            ? oldKeySnapshot
            : await transaction.get(newKeyReference);

        if (existingSkill.ownerUid == cleanUid) {
          if (newKeySnapshot.exists &&
              _keySkillId(newKeySnapshot) != existingSkill.skill.id) {
            throw const FirestoreMySkillsRepositoryException(
              'Another skill already uses that name.',
            );
          }
          if (oldKeyReference.path != newKeyReference.path) {
            if (oldKeySnapshot.exists &&
                _keySkillId(oldKeySnapshot) == existingSkill.skill.id) {
              transaction.delete(oldKeyReference);
            }
            transaction.set(newKeyReference, <String, Object?>{
              'skillId': existingSkill.skill.id,
              'titleKey': newKey,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } else if (!oldKeySnapshot.exists) {
            transaction.set(oldKeyReference, <String, Object?>{
              'skillId': existingSkill.skill.id,
              'titleKey': oldKey,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
          transaction.update(skillReference, <String, Object?>{
            'title': cleanTitle,
            'titleKey': newKey,
            'category': cleanCategory,
            'level': cleanLevel,
            'iconCodePoint': icon.codePoint,
            'description': cleanDescription,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          if (cleanTitle != existingSkill.skill.title ||
              cleanCategory != existingSkill.skill.category ||
              cleanDescription != existingSkill.skill.description) {
            throw const FirestoreMySkillsRepositoryException(
              'Shared skill details cannot be renamed or rewritten. '
              'You can update your level and availability.',
            );
          }
        }

        transaction.update(linkReference, <String, Object?>{
          'level': cleanLevel,
          'availability': cleanAvailability,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirestoreMySkillsRepositoryException {
      rethrow;
    } on FirebaseException {
      throw const FirestoreMySkillsRepositoryException(
        'The skill could not be updated in the cloud. Please try again.',
      );
    } catch (_) {
      throw const FirestoreMySkillsRepositoryException(
        'The skill could not be updated in the cloud. Please try again.',
      );
    }
  }

  Future<void> deleteLink({
    required String uid,
    required String userSkillId,
    required UserSkillType expectedType,
  }) async {
    final String cleanUid = _requireUid(uid);
    final String cleanLinkId = _requiredText(userSkillId, 'Skill relationship');
    final DocumentReference<Map<String, dynamic>> linkReference = _firestore
        .collection('users')
        .doc(cleanUid)
        .collection('skillLinks')
        .doc(cleanLinkId);
    try {
      await _firestore.runTransaction<void>((Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> linkSnapshot =
            await transaction.get(linkReference);
        if (!linkSnapshot.exists) {
          throw const FirestoreMySkillsRepositoryException(
            'Skill relationship could not be found.',
          );
        }
        final FirestoreSkillLinkRecord link = _parseLink(
          cleanUid,
          linkSnapshot,
        );
        if (link.userSkill.type != expectedType) {
          throw const FirestoreMySkillsRepositoryException(
            'Skill relationship type does not match.',
          );
        }
        final DocumentReference<Map<String, dynamic>> skillReference =
            _firestore.collection('skills').doc(link.userSkill.skillId);
        final DocumentSnapshot<Map<String, dynamic>> skillSnapshot =
            await transaction.get(skillReference);
        if (!skillSnapshot.exists) {
          throw const FirestoreMySkillsRepositoryException(
            'Skill catalog entry could not be found.',
          );
        }
        final FirestoreSkillRecord skill = _parseSkill(skillSnapshot);
        if (skill.linkCount <= 0) {
          throw const FirestoreMySkillsRepositoryException(
            'Skill catalog reference count is invalid.',
          );
        }
        final DocumentReference<Map<String, dynamic>> keyReference =
            _titleKeyReference(normalizeTitle(skill.skill.title));
        final DocumentSnapshot<Map<String, dynamic>> keySnapshot =
            await transaction.get(keyReference);
        final DocumentReference<Map<String, dynamic>> linkKeyReference =
            _linkKeyReference(
              cleanUid,
              link.userSkill.type,
              link.userSkill.skillId,
            );
        final DocumentSnapshot<Map<String, dynamic>> linkKeySnapshot =
            await transaction.get(linkKeyReference);

        transaction.delete(linkReference);
        if (linkKeySnapshot.exists &&
            _linkKeyRelationshipId(linkKeySnapshot) == cleanLinkId) {
          transaction.delete(linkKeyReference);
        }
        final int remaining = skill.linkCount - 1;
        if (remaining == 0 && skill.ownerUid == cleanUid) {
          transaction.delete(skillReference);
          if (keySnapshot.exists &&
              _keySkillId(keySnapshot) == skill.skill.id) {
            transaction.delete(keyReference);
          }
        } else {
          transaction.update(skillReference, <String, Object?>{
            'linkCount': remaining,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } on FirestoreMySkillsRepositoryException {
      rethrow;
    } on FirebaseException {
      throw const FirestoreMySkillsRepositoryException(
        'The skill could not be deleted from the cloud. Please try again.',
      );
    } catch (_) {
      throw const FirestoreMySkillsRepositoryException(
        'The skill could not be deleted from the cloud. Please try again.',
      );
    }
  }

  Future<FirestoreManagedSkillRecord> _createLink({
    required String uid,
    required Skill proposedSkill,
    required UserSkill proposedLink,
    required String? ownerUid,
    required bool preserveProposedSkillId,
  }) async {
    final String cleanUid = _requireUid(uid);
    _validateSkill(proposedSkill);
    _validateLink(cleanUid, proposedLink);
    final String? cleanOwnerUid = _optionalUid(ownerUid);
    if (cleanOwnerUid == 'user_joice_local') {
      throw const FirestoreMySkillsRepositoryException(
        'This skill belongs to legacy local data and cannot be migrated.',
      );
    }
    final String titleKey = normalizeTitle(proposedSkill.title);
    final DocumentReference<Map<String, dynamic>> keyReference =
        _titleKeyReference(titleKey);
    final DocumentReference<Map<String, dynamic>> linkReference = _firestore
        .collection('users')
        .doc(cleanUid)
        .collection('skillLinks')
        .doc(proposedLink.id.trim());

    try {
      return await _firestore.runTransaction<FirestoreManagedSkillRecord>((
        Transaction transaction,
      ) async {
        final DocumentSnapshot<Map<String, dynamic>> linkSnapshot =
            await transaction.get(linkReference);
        final DocumentSnapshot<Map<String, dynamic>> keySnapshot =
            await transaction.get(keyReference);

        String selectedSkillId = proposedSkill.id.trim();
        if (keySnapshot.exists) {
          final String keyedSkillId = _keySkillId(keySnapshot);
          if (preserveProposedSkillId && keyedSkillId != selectedSkillId) {
            throw const FirestoreMySkillsRepositoryException(
              'A cloud skill with the same name uses a different stable ID.',
            );
          }
          selectedSkillId = keyedSkillId;
        }

        final DocumentReference<Map<String, dynamic>> skillReference =
            _firestore.collection('skills').doc(selectedSkillId);
        final DocumentSnapshot<Map<String, dynamic>> skillSnapshot =
            await transaction.get(skillReference);

        late final FirestoreSkillRecord selectedSkill;
        if (skillSnapshot.exists) {
          selectedSkill = _parseSkill(skillSnapshot);
          if (normalizeTitle(selectedSkill.skill.title) != titleKey) {
            throw const FirestoreMySkillsRepositoryException(
              'Cloud skill title ownership is inconsistent.',
            );
          }
          if (preserveProposedSkillId &&
              selectedSkill.skill.id != proposedSkill.id.trim()) {
            throw const FirestoreMySkillsRepositoryException(
              'The stable local skill ID conflicts with cloud data.',
            );
          }
        } else {
          if (keySnapshot.exists) {
            throw const FirestoreMySkillsRepositoryException(
              'The cloud skill title points to a missing catalog entry.',
            );
          }
          if (cleanOwnerUid != null && cleanOwnerUid != cleanUid) {
            throw const FirestoreMySkillsRepositoryException(
              'A skill owned by another account must already exist in the cloud.',
            );
          }
          final DateTime now = DateTime.now().toUtc();
          selectedSkill = FirestoreSkillRecord(
            skill: proposedSkill,
            ownerUid: cleanOwnerUid,
            linkCount: 0,
            createdAt: now,
            updatedAt: now,
          );
        }

        final UserSkill selectedLink = UserSkill(
          id: proposedLink.id.trim(),
          userId: cleanUid,
          skillId: selectedSkillId,
          type: proposedLink.type,
          level: _validatedLevel(proposedLink.level),
          availability: _requiredText(
            proposedLink.availability,
            'Availability',
          ),
        );
        final DocumentReference<Map<String, dynamic>> linkKeyReference =
            _linkKeyReference(
              cleanUid,
              selectedLink.type,
              selectedLink.skillId,
            );
        final DocumentSnapshot<Map<String, dynamic>> linkKeySnapshot =
            await transaction.get(linkKeyReference);
        if (linkKeySnapshot.exists &&
            _linkKeyRelationshipId(linkKeySnapshot) != selectedLink.id) {
          throw FirestoreMySkillsRepositoryException(
            selectedLink.type == UserSkillType.offered
                ? 'You already offer this skill.'
                : 'You already want to learn this skill.',
          );
        }

        if (linkSnapshot.exists) {
          final FirestoreSkillLinkRecord existing = _parseLink(
            cleanUid,
            linkSnapshot,
          );
          if (existing.userSkill.skillId != selectedLink.skillId ||
              existing.userSkill.type != selectedLink.type) {
            throw const FirestoreMySkillsRepositoryException(
              'The stable relationship ID conflicts with cloud data.',
            );
          }
          if (!linkKeySnapshot.exists) {
            transaction.set(linkKeyReference, <String, Object?>{
              'userSkillId': selectedLink.id,
              'skillId': selectedLink.skillId,
              'type': selectedLink.type.name,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
          return FirestoreManagedSkillRecord(
            catalog: selectedSkill,
            link: existing,
          );
        }

        if (!skillSnapshot.exists) {
          transaction.set(
            skillReference,
            _newSkillData(selectedSkill, initialLinkCount: 1),
          );
        } else {
          transaction.update(skillReference, <String, Object?>{
            'linkCount': selectedSkill.linkCount + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        if (!keySnapshot.exists) {
          transaction.set(keyReference, <String, Object?>{
            'skillId': selectedSkillId,
            'titleKey': titleKey,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        if (!linkKeySnapshot.exists) {
          transaction.set(linkKeyReference, <String, Object?>{
            'userSkillId': selectedLink.id,
            'skillId': selectedLink.skillId,
            'type': selectedLink.type.name,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        transaction.set(linkReference, _newLinkData(selectedLink));

        final DateTime now = DateTime.now().toUtc();
        return FirestoreManagedSkillRecord(
          catalog: FirestoreSkillRecord(
            skill: selectedSkill.skill,
            ownerUid: selectedSkill.ownerUid,
            linkCount: selectedSkill.linkCount + 1,
            createdAt: selectedSkill.createdAt,
            updatedAt: now,
          ),
          link: FirestoreSkillLinkRecord(
            userSkill: selectedLink,
            createdAt: now,
            updatedAt: now,
          ),
        );
      });
    } on FirestoreMySkillsRepositoryException {
      rethrow;
    } on FirebaseException {
      throw const FirestoreMySkillsRepositoryException(
        'The skill could not be saved to the cloud. Please try again.',
      );
    } catch (_) {
      throw const FirestoreMySkillsRepositoryException(
        'The skill could not be saved to the cloud. Please try again.',
      );
    }
  }

  Future<FirestoreMySkillsSnapshot> _loadFromSource(
    String uid,
    Source source,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> links = await _firestore
        .collection('users')
        .doc(uid)
        .collection('skillLinks')
        .get(GetOptions(source: source));
    final List<FirestoreSkillLinkRecord> parsedLinks =
        <FirestoreSkillLinkRecord>[];
    final Set<String> relationshipIds = <String>{};
    final Set<String> typeKeys = <String>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> snapshot
        in links.docs) {
      final FirestoreSkillLinkRecord link = _parseLink(uid, snapshot);
      if (!relationshipIds.add(link.userSkill.id) ||
          !typeKeys.add(
            '${link.userSkill.skillId}:${link.userSkill.type.name}',
          )) {
        throw const FirestoreMySkillsRepositoryException(
          'Cloud skills contain duplicate relationships.',
        );
      }
      parsedLinks.add(link);
    }

    final Map<String, FirestoreSkillRecord> catalog =
        <String, FirestoreSkillRecord>{};
    final List<String> skillIds = parsedLinks
        .map((FirestoreSkillLinkRecord item) => item.userSkill.skillId)
        .toSet()
        .toList(growable: false);
    final List<DocumentSnapshot<Map<String, dynamic>>> skillSnapshots =
        await Future.wait(
          skillIds.map(
            (String skillId) => _firestore
                .collection('skills')
                .doc(skillId)
                .get(GetOptions(source: source)),
          ),
        );
    for (final DocumentSnapshot<Map<String, dynamic>> snapshot
        in skillSnapshots) {
      if (!snapshot.exists) {
        throw const FirestoreMySkillsRepositoryException(
          'A cloud skill relationship points to a missing catalog entry.',
        );
      }
      final FirestoreSkillRecord skill = _parseSkill(snapshot);
      catalog[skill.skill.id] = skill;
    }

    final List<FirestoreManagedSkillRecord> records = parsedLinks.map((
      FirestoreSkillLinkRecord link,
    ) {
      final FirestoreSkillRecord? skill = catalog[link.userSkill.skillId];
      if (skill == null) {
        throw const FirestoreMySkillsRepositoryException(
          'A cloud skill relationship could not be resolved.',
        );
      }
      return FirestoreManagedSkillRecord(catalog: skill, link: link);
    }).toList();
    records.sort(
      (FirestoreManagedSkillRecord a, FirestoreManagedSkillRecord b) => a
          .catalog
          .skill
          .title
          .toLowerCase()
          .compareTo(b.catalog.skill.title.toLowerCase()),
    );
    return FirestoreMySkillsSnapshot(
      source: source == Source.server
          ? FirestoreMySkillsSource.server
          : FirestoreMySkillsSource.cache,
      records: List<FirestoreManagedSkillRecord>.unmodifiable(records),
    );
  }

  FirestoreSkillRecord _parseSkill(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic>? data = snapshot.data();
    if (data == null || snapshot.id.trim().isEmpty) {
      throw const FirestoreMySkillsRepositoryException(
        'Cloud skill data is invalid.',
      );
    }
    final String? ownerUid = _nullableString(data, 'ownerUid');
    if (ownerUid == 'user_joice_local') {
      throw const FirestoreMySkillsRepositoryException(
        'Legacy local skill ownership cannot be migrated.',
      );
    }
    final String title = _requiredString(data, 'title');
    final String titleKey = _requiredString(data, 'titleKey');
    if (titleKey != normalizeTitle(title)) {
      throw const FirestoreMySkillsRepositoryException(
        'Cloud skill title normalization is invalid.',
      );
    }
    final int version = _requiredInt(data, 'schemaVersion');
    final int linkCount = _requiredInt(data, 'linkCount');
    if (version != schemaVersion || linkCount < 0) {
      throw const FirestoreMySkillsRepositoryException(
        'Cloud skill version or reference count is invalid.',
      );
    }
    final List<String> learnings = _requiredStringList(data, 'learnings');
    final Skill skill = Skill(
      id: snapshot.id.trim(),
      title: title,
      category: _requiredString(data, 'category'),
      level: _requiredString(data, 'level'),
      icon: IconData(
        // ignore: non_const_argument_for_const_parameter
        _positiveInt(data, 'iconCodePoint'),
        fontFamily: 'MaterialIcons',
      ),
      sessionLength: _requiredString(data, 'sessionLength'),
      mode: _requiredString(data, 'mode'),
      language: _requiredString(data, 'language'),
      prerequisite: _requiredString(data, 'prerequisite', allowEmpty: true),
      description: _requiredString(data, 'description'),
      learnings: List<String>.unmodifiable(learnings),
    );
    _validateSkill(skill);
    return FirestoreSkillRecord(
      skill: skill,
      ownerUid: ownerUid,
      linkCount: linkCount,
      createdAt: _requiredTimestamp(data, 'createdAt').toDate().toUtc(),
      updatedAt: _requiredTimestamp(data, 'updatedAt').toDate().toUtc(),
    );
  }

  FirestoreSkillLinkRecord _parseLink(
    String uid,
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic>? data = snapshot.data();
    if (data == null || snapshot.id.trim().isEmpty) {
      throw const FirestoreMySkillsRepositoryException(
        'Cloud skill relationship is invalid.',
      );
    }
    final String storedType = _requiredString(data, 'type');
    final UserSkillType type;
    switch (storedType) {
      case 'offered':
        type = UserSkillType.offered;
        break;
      case 'wanted':
        type = UserSkillType.wanted;
        break;
      default:
        throw const FirestoreMySkillsRepositoryException(
          'Cloud skill relationship type is invalid.',
        );
    }
    if (_requiredInt(data, 'schemaVersion') != schemaVersion) {
      throw const FirestoreMySkillsRepositoryException(
        'Cloud skill relationship version is unsupported.',
      );
    }
    final UserSkill relationship = UserSkill(
      id: snapshot.id.trim(),
      userId: uid,
      skillId: _requiredString(data, 'skillId'),
      type: type,
      level: _validatedLevel(_requiredString(data, 'level')),
      availability: _requiredString(data, 'availability'),
    );
    _validateLink(uid, relationship);
    return FirestoreSkillLinkRecord(
      userSkill: relationship,
      createdAt: _requiredTimestamp(data, 'createdAt').toDate().toUtc(),
      updatedAt: _requiredTimestamp(data, 'updatedAt').toDate().toUtc(),
    );
  }

  Map<String, Object?> _newSkillData(
    FirestoreSkillRecord record, {
    required int initialLinkCount,
  }) {
    final Skill skill = record.skill;
    return <String, Object?>{
      'ownerUid': record.ownerUid,
      'title': skill.title.trim(),
      'titleKey': normalizeTitle(skill.title),
      'category': skill.category.trim(),
      'level': skill.level.trim(),
      'iconCodePoint': skill.icon.codePoint,
      'sessionLength': skill.sessionLength.trim(),
      'mode': skill.mode.trim(),
      'language': skill.language.trim(),
      'prerequisite': skill.prerequisite.trim(),
      'description': skill.description.trim(),
      'learnings': skill.learnings.map((String item) => item.trim()).toList(),
      'linkCount': initialLinkCount,
      'schemaVersion': schemaVersion,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> _newLinkData(UserSkill link) {
    return <String, Object?>{
      'skillId': link.skillId.trim(),
      'type': link.type.name,
      'level': link.level.trim(),
      'availability': link.availability.trim(),
      'schemaVersion': schemaVersion,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  DocumentReference<Map<String, dynamic>> _titleKeyReference(String titleKey) {
    final String encoded = base64Url
        .encode(utf8.encode(titleKey))
        .replaceAll('=', '');
    return _firestore.collection('skillTitleKeys').doc(encoded);
  }

  DocumentReference<Map<String, dynamic>> _linkKeyReference(
    String uid,
    UserSkillType type,
    String skillId,
  ) {
    final String raw = '${type.name}:${skillId.trim()}';
    final String encoded = base64Url
        .encode(utf8.encode(raw))
        .replaceAll('=', '');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('skillLinkKeys')
        .doc(encoded);
  }

  String _keySkillId(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final Map<String, dynamic>? data = snapshot.data();
    if (data == null) {
      throw const FirestoreMySkillsRepositoryException(
        'Cloud skill title key is invalid.',
      );
    }
    final String titleKey = _requiredString(data, 'titleKey');
    if (titleKey.trim().isEmpty) {
      throw const FirestoreMySkillsRepositoryException(
        'Cloud skill title key is invalid.',
      );
    }
    _requiredTimestamp(data, 'createdAt');
    return _requiredString(data, 'skillId');
  }

  String _linkKeyRelationshipId(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic>? data = snapshot.data();
    if (data == null) {
      throw const FirestoreMySkillsRepositoryException(
        'Cloud skill relationship key is invalid.',
      );
    }
    final String type = _requiredString(data, 'type');
    if (type != 'offered' && type != 'wanted') {
      throw const FirestoreMySkillsRepositoryException(
        'Cloud skill relationship key is invalid.',
      );
    }
    _requiredString(data, 'skillId');
    _requiredTimestamp(data, 'createdAt');
    return _requiredString(data, 'userSkillId');
  }

  static String normalizeTitle(String title) => title.trim().toLowerCase();

  void _validateSkill(Skill skill) {
    if (skill.id.trim().isEmpty) {
      throw const FirestoreMySkillsRepositoryException('Skill ID is required.');
    }
    _validatedTitle(skill.title);
    _requiredText(skill.category, 'Category');
    _requiredText(skill.level, 'Catalog level');
    _requiredText(skill.sessionLength, 'Session length');
    _requiredText(skill.mode, 'Mode');
    _requiredText(skill.language, 'Language');
    _requiredText(skill.description, 'Description');
    if (skill.icon.codePoint <= 0 ||
        skill.learnings.any((String item) => item.trim().isEmpty)) {
      throw const FirestoreMySkillsRepositoryException(
        'Skill catalog metadata is invalid.',
      );
    }
  }

  void _validateLink(String uid, UserSkill link) {
    if (link.id.trim().isEmpty ||
        link.userId.trim() != uid ||
        link.skillId.trim().isEmpty) {
      throw const FirestoreMySkillsRepositoryException(
        'Skill relationship ownership is invalid.',
      );
    }
    _validatedLevel(link.level);
    _requiredText(link.availability, 'Availability');
  }

  String _requireUid(String uid) {
    final String clean = uid.trim();
    if (clean.isEmpty || clean == 'user_joice_local') {
      throw const FirestoreMySkillsRepositoryException(
        'A valid authenticated user ID is required.',
      );
    }
    return clean;
  }

  String? _optionalUid(String? uid) {
    if (uid == null) return null;
    final String clean = uid.trim();
    return clean.isEmpty ? null : clean;
  }

  String _validatedTitle(String value) {
    final String clean = _requiredText(value, 'Skill name');
    if (clean.length > 80) {
      throw const FirestoreMySkillsRepositoryException(
        'Skill name must be 80 characters or less.',
      );
    }
    return clean;
  }

  String _validatedDescription(String value) {
    final String clean = _requiredText(value, 'Description');
    if (clean.length > 200) {
      throw const FirestoreMySkillsRepositoryException(
        'Description must be 200 characters or less.',
      );
    }
    return clean;
  }

  String _validatedLevel(String value) {
    final String clean = _requiredText(value, 'Experience level');
    if (!const <String>{
      'Beginner',
      'Intermediate',
      'Advanced',
    }.contains(clean)) {
      throw const FirestoreMySkillsRepositoryException(
        'Invalid experience level.',
      );
    }
    return clean;
  }

  String _requiredText(String value, String label) {
    final String clean = value.trim();
    if (clean.isEmpty) {
      throw FirestoreMySkillsRepositoryException('$label is required.');
    }
    return clean;
  }

  String _requiredString(
    Map<String, dynamic> data,
    String key, {
    bool allowEmpty = false,
  }) {
    final Object? value = data[key];
    if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
      throw FirestoreMySkillsRepositoryException(
        'Cloud skill field "$key" is invalid.',
      );
    }
    return value.trim();
  }

  String? _nullableString(Map<String, dynamic> data, String key) {
    if (!data.containsKey(key)) {
      throw FirestoreMySkillsRepositoryException(
        'Cloud skill field "$key" is missing.',
      );
    }
    final Object? value = data[key];
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      throw FirestoreMySkillsRepositoryException(
        'Cloud skill field "$key" is invalid.',
      );
    }
    return value.trim();
  }

  int _requiredInt(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! int) {
      throw FirestoreMySkillsRepositoryException(
        'Cloud skill field "$key" is invalid.',
      );
    }
    return value;
  }

  int _positiveInt(Map<String, dynamic> data, String key) {
    final int value = _requiredInt(data, key);
    if (value <= 0) {
      throw FirestoreMySkillsRepositoryException(
        'Cloud skill field "$key" is invalid.',
      );
    }
    return value;
  }

  Timestamp _requiredTimestamp(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! Timestamp) {
      throw FirestoreMySkillsRepositoryException(
        'Cloud skill field "$key" is invalid.',
      );
    }
    return value;
  }

  List<String> _requiredStringList(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! List) {
      throw FirestoreMySkillsRepositoryException(
        'Cloud skill field "$key" is invalid.',
      );
    }
    final List<String> result = <String>[];
    for (final Object? item in value) {
      if (item is! String || item.trim().isEmpty) {
        throw FirestoreMySkillsRepositoryException(
          'Cloud skill field "$key" is invalid.',
        );
      }
      result.add(item.trim());
    }
    return result;
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
