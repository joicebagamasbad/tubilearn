import 'package:flutter/material.dart';

import '../model/managed_skill.dart';
import '../model/repositories/explore_repository.dart';
import '../model/repositories/firestore_my_skills_repository.dart';
import '../model/repositories/firestore_profile_repository.dart';
import '../model/repositories/local_user_data_projection_repository.dart';
import '../model/skill.dart';
import '../model/user_skill.dart';
import 'current_user_service.dart';

class MySkillsServiceException implements Exception {
  final String message;

  const MySkillsServiceException(this.message);

  @override
  String toString() => message;
}

class MySkillsServiceSnapshot {
  final List<ManagedSkill> offeredSkills;
  final List<ManagedWantedSkill> wantedSkills;
  final bool isStaleLocalFallback;

  const MySkillsServiceSnapshot({
    required this.offeredSkills,
    required this.wantedSkills,
    required this.isStaleLocalFallback,
  });
}

class MySkillsService {
  MySkillsService({
    FirestoreMySkillsRepository? firestoreRepository,
    FirestoreProfileRepository? profileRepository,
    LocalUserDataProjectionRepository? localRepository,
    CurrentUserService? currentUserService,
    ExploreRepository? exploreRepository,
  }) : _firestoreRepository =
           firestoreRepository ?? FirestoreMySkillsRepository.instance,
       _profileRepository =
           profileRepository ?? FirestoreProfileRepository.instance,
       _localRepository =
           localRepository ?? LocalUserDataProjectionRepository.instance,
       _currentUserService = currentUserService ?? CurrentUserService.instance,
       _exploreRepository = exploreRepository ?? ExploreRepository.instance;

  static final MySkillsService instance = MySkillsService();

  final FirestoreMySkillsRepository _firestoreRepository;
  final FirestoreProfileRepository _profileRepository;
  final LocalUserDataProjectionRepository _localRepository;
  final CurrentUserService _currentUserService;
  final ExploreRepository _exploreRepository;

  int _lastGeneratedIdValue = 0;

  Future<MySkillsServiceSnapshot> prepareCurrentSession() {
    return _currentUserService.runForSession<MySkillsServiceSnapshot>(() async {
      return _prepareAndLoad(
        refreshExplore: false,
        allowStaleLocalFallback: true,
      );
    });
  }

  Future<MySkillsServiceSnapshot> loadCurrentSkills({
    bool allowStaleLocalFallback = true,
  }) {
    return _currentUserService.runForSession<MySkillsServiceSnapshot>(() async {
      return _prepareAndLoad(
        refreshExplore: true,
        allowStaleLocalFallback: allowStaleLocalFallback,
      );
    });
  }

  Future<void> addOfferedSkill({
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
  }) {
    return _addSkill(
      title: title,
      category: category,
      description: description,
      level: level,
      availability: availability,
      type: UserSkillType.offered,
    );
  }

  Future<void> addWantedSkill({
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
  }) {
    return _addSkill(
      title: title,
      category: category,
      description: description,
      level: level,
      availability: availability,
      type: UserSkillType.wanted,
    );
  }

  Future<void> updateOfferedSkill({
    required String userSkillId,
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
  }) {
    return _updateSkill(
      userSkillId: userSkillId,
      title: title,
      category: category,
      description: description,
      level: level,
      availability: availability,
      type: UserSkillType.offered,
    );
  }

  Future<void> updateWantedSkill({
    required String userSkillId,
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
  }) {
    return _updateSkill(
      userSkillId: userSkillId,
      title: title,
      category: category,
      description: description,
      level: level,
      availability: availability,
      type: UserSkillType.wanted,
    );
  }

  Future<void> deleteOfferedSkill({required String userSkillId}) {
    return _deleteSkill(userSkillId: userSkillId, type: UserSkillType.offered);
  }

  Future<void> deleteWantedSkill({required String userSkillId}) {
    return _deleteSkill(userSkillId: userSkillId, type: UserSkillType.wanted);
  }

  Future<MySkillsServiceSnapshot> _prepareAndLoad({
    required bool refreshExplore,
    required bool allowStaleLocalFallback,
  }) async {
    final String uid = _currentUserService.requireUserId();
    final FirestoreProfileLookup profileLookup;
    try {
      profileLookup = await _profileRepository.lookup(uid);
    } on FirestoreProfileRepositoryException catch (error) {
      throw MySkillsServiceException(error.message);
    }
    _currentUserService.requireActiveOperation();

    if (profileLookup.status ==
        FirestoreProfileLookupStatus.confirmedServerAbsent) {
      throw const MySkillsServiceException(
        'The cloud profile must be prepared before cloud skills.',
      );
    }
    if (profileLookup.status == FirestoreProfileLookupStatus.unavailable) {
      return _fallbackOrThrow(uid, allowStaleLocalFallback);
    }
    final FirestoreProfileData profile = profileLookup.profile!;
    if (profile.skillsBootstrapVersion <
        FirestoreProfileRepository.skillsBootstrapVersion) {
      if (profileLookup.status != FirestoreProfileLookupStatus.serverDocument) {
        return _fallbackOrThrow(uid, allowStaleLocalFallback);
      }
      final LocalUserSkillsSnapshot local;
      try {
        local = await _localRepository.loadSkills(uid);
      } on LocalUserDataProjectionException catch (error) {
        throw MySkillsServiceException(error.message);
      }
      _currentUserService.requireActiveOperation();
      for (final LocalManagedSkillRecord record in local.records) {
        if (record.ownerUid == 'user_joice_local') {
          throw const MySkillsServiceException(
            'A same-account skill references legacy local ownership. '
            'The skills migration was not changed.',
          );
        }
      }
      for (final LocalManagedSkillRecord record in local.records) {
        try {
          await _firestoreRepository.bootstrapLink(
            uid: uid,
            skill: record.skill,
            userSkill: record.userSkill,
            ownerUid: record.ownerUid,
          );
        } on FirestoreMySkillsRepositoryException catch (error) {
          throw MySkillsServiceException(error.message);
        }
        _currentUserService.requireActiveOperation();
      }
      try {
        await _profileRepository.markSkillsBootstrapComplete(uid);
      } on FirestoreProfileRepositoryException catch (error) {
        throw MySkillsServiceException(error.message);
      }
      _currentUserService.requireActiveOperation();
    }

    final FirestoreMySkillsSnapshot cloud = await _loadCloud(uid);
    _currentUserService.requireActiveOperation();
    if (cloud.source != FirestoreMySkillsSource.server) {
      return _fallbackOrThrow(uid, allowStaleLocalFallback);
    }
    await _projectCloud(uid, cloud, refreshExplore: refreshExplore);
    return _snapshotFromCloud(cloud);
  }

  Future<void> _addSkill({
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
    required UserSkillType type,
  }) {
    final String cleanTitle = _validatedTitle(title);
    final String cleanCategory = _requiredText(category, 'Category');
    final String cleanDescription = _validatedDescription(description);
    final String cleanLevel = _validatedLevel(level);
    final String cleanAvailability = _requiredText(
      availability,
      'Availability',
    );
    return _currentUserService.runForSession<void>(() async {
      final String uid = _currentUserService.requireUserId();
      final String skillId = _generateId('skill_custom');
      final String relationshipId = _generateId('user_skill');
      final Skill proposedSkill = Skill(
        id: skillId,
        title: cleanTitle,
        category: cleanCategory,
        level: cleanLevel,
        icon: _iconForCategory(cleanCategory),
        sessionLength: 'Flexible',
        mode: 'Online / In-person',
        language: 'Filipino / English',
        prerequisite: '',
        description: cleanDescription,
        learnings: const <String>[],
      );
      final UserSkill proposedLink = UserSkill(
        id: relationshipId,
        userId: uid,
        skillId: skillId,
        type: type,
        level: cleanLevel,
        availability: cleanAvailability,
      );
      try {
        await _firestoreRepository.createLink(
          uid: uid,
          proposedSkill: proposedSkill,
          proposedLink: proposedLink,
        );
      } on FirestoreMySkillsRepositoryException catch (error) {
        throw MySkillsServiceException(error.message);
      }
      _currentUserService.requireActiveOperation();
      await _reconcileAfterCloudMutation(uid);
    });
  }

  Future<void> _updateSkill({
    required String userSkillId,
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
    required UserSkillType type,
  }) {
    final String cleanId = _requiredText(userSkillId, 'Skill relationship');
    final String cleanTitle = _validatedTitle(title);
    final String cleanCategory = _requiredText(category, 'Category');
    final String cleanDescription = _validatedDescription(description);
    final String cleanLevel = _validatedLevel(level);
    final String cleanAvailability = _requiredText(
      availability,
      'Availability',
    );
    return _currentUserService.runForSession<void>(() async {
      final String uid = _currentUserService.requireUserId();
      try {
        await _firestoreRepository.updateLink(
          uid: uid,
          userSkillId: cleanId,
          expectedType: type,
          title: cleanTitle,
          category: cleanCategory,
          description: cleanDescription,
          level: cleanLevel,
          availability: cleanAvailability,
          icon: _iconForCategory(cleanCategory),
        );
      } on FirestoreMySkillsRepositoryException catch (error) {
        throw MySkillsServiceException(error.message);
      }
      _currentUserService.requireActiveOperation();
      await _reconcileAfterCloudMutation(uid);
    });
  }

  Future<void> _deleteSkill({
    required String userSkillId,
    required UserSkillType type,
  }) {
    final String cleanId = _requiredText(userSkillId, 'Skill relationship');
    return _currentUserService.runForSession<void>(() async {
      final String uid = _currentUserService.requireUserId();
      try {
        await _firestoreRepository.deleteLink(
          uid: uid,
          userSkillId: cleanId,
          expectedType: type,
        );
      } on FirestoreMySkillsRepositoryException catch (error) {
        throw MySkillsServiceException(error.message);
      }
      _currentUserService.requireActiveOperation();
      await _reconcileAfterCloudMutation(uid);
    });
  }

  Future<void> _reconcileAfterCloudMutation(String uid) async {
    final FirestoreMySkillsSnapshot cloud;
    try {
      cloud = await _firestoreRepository.load(uid);
    } on FirestoreMySkillsRepositoryException {
      throw const MySkillsServiceException(
        'Your skill change was saved to the cloud, but the local copy could '
        'not be refreshed. Reload My Skills to reconcile it.',
      );
    }
    _currentUserService.requireActiveOperation();
    if (cloud.source != FirestoreMySkillsSource.server) {
      throw const MySkillsServiceException(
        'Your skill change was saved to the cloud, but the local copy could '
        'not be refreshed. Reload My Skills to reconcile it.',
      );
    }
    try {
      await _projectCloud(uid, cloud, refreshExplore: true);
    } on MySkillsServiceException {
      throw const MySkillsServiceException(
        'Your skill change was saved to the cloud, but the local copy could '
        'not be refreshed. Reload My Skills to reconcile it.',
      );
    }
  }

  Future<FirestoreMySkillsSnapshot> _loadCloud(String uid) async {
    try {
      return await _firestoreRepository.load(uid);
    } on FirestoreMySkillsRepositoryException catch (error) {
      throw MySkillsServiceException(error.message);
    }
  }

  Future<void> _projectCloud(
    String uid,
    FirestoreMySkillsSnapshot cloud, {
    required bool refreshExplore,
  }) async {
    _currentUserService.requireActiveOperation();
    try {
      await _localRepository.projectSkills(uid: uid, snapshot: cloud);
    } on LocalUserDataProjectionException catch (error) {
      throw MySkillsServiceException(error.message);
    }
    _currentUserService.requireActiveOperation();
    if (refreshExplore) {
      try {
        await _exploreRepository.refresh();
      } on ExploreRepositoryException {
        throw const MySkillsServiceException(
          'Cloud skills were saved locally, but Explore could not be refreshed.',
        );
      }
      _currentUserService.requireActiveOperation();
    }
  }

  Future<MySkillsServiceSnapshot> _loadLocalFallback(String uid) async {
    try {
      final LocalUserSkillsSnapshot local = await _localRepository.loadSkills(
        uid,
      );
      _currentUserService.requireActiveOperation();
      return _snapshotFromLocal(local, isStale: true);
    } on LocalUserDataProjectionException {
      throw const MySkillsServiceException(
        'Neither cloud skills nor the same-account local copy could be loaded.',
      );
    }
  }

  Future<MySkillsServiceSnapshot> _fallbackOrThrow(
    String uid,
    bool allowStaleLocalFallback,
  ) {
    if (!allowStaleLocalFallback) {
      throw const MySkillsServiceException(
        'Your cloud skills are unavailable. Check your connection and try again.',
      );
    }
    return _loadLocalFallback(uid);
  }

  MySkillsServiceSnapshot _snapshotFromCloud(FirestoreMySkillsSnapshot cloud) {
    final List<ManagedSkill> offered = <ManagedSkill>[];
    final List<ManagedWantedSkill> wanted = <ManagedWantedSkill>[];
    for (final FirestoreManagedSkillRecord record in cloud.records) {
      if (record.link.userSkill.type == UserSkillType.offered) {
        offered.add(
          ManagedSkill(
            skill: record.catalog.skill,
            userSkill: record.link.userSkill,
            ownerUserId: record.catalog.ownerUid,
          ),
        );
      } else {
        wanted.add(
          ManagedWantedSkill(
            skill: record.catalog.skill,
            userSkill: record.link.userSkill,
            ownerUserId: record.catalog.ownerUid,
          ),
        );
      }
    }
    return MySkillsServiceSnapshot(
      offeredSkills: List<ManagedSkill>.unmodifiable(offered),
      wantedSkills: List<ManagedWantedSkill>.unmodifiable(wanted),
      isStaleLocalFallback: cloud.source == FirestoreMySkillsSource.cache,
    );
  }

  MySkillsServiceSnapshot _snapshotFromLocal(
    LocalUserSkillsSnapshot local, {
    required bool isStale,
  }) {
    final List<ManagedSkill> offered = <ManagedSkill>[];
    final List<ManagedWantedSkill> wanted = <ManagedWantedSkill>[];
    for (final LocalManagedSkillRecord record in local.records) {
      if (record.userSkill.type == UserSkillType.offered) {
        offered.add(
          ManagedSkill(
            skill: record.skill,
            userSkill: record.userSkill,
            ownerUserId: record.ownerUid,
          ),
        );
      } else {
        wanted.add(
          ManagedWantedSkill(
            skill: record.skill,
            userSkill: record.userSkill,
            ownerUserId: record.ownerUid,
          ),
        );
      }
    }
    return MySkillsServiceSnapshot(
      offeredSkills: List<ManagedSkill>.unmodifiable(offered),
      wantedSkills: List<ManagedWantedSkill>.unmodifiable(wanted),
      isStaleLocalFallback: isStale,
    );
  }

  String _generateId(String prefix) {
    final int now = DateTime.now().microsecondsSinceEpoch;
    if (now > _lastGeneratedIdValue) {
      _lastGeneratedIdValue = now;
    } else {
      _lastGeneratedIdValue++;
    }
    return '${prefix}_$_lastGeneratedIdValue';
  }

  String _validatedTitle(String value) {
    final String clean = _requiredText(value, 'Skill name');
    if (clean.length > 80) {
      throw const MySkillsServiceException(
        'Skill name must be 80 characters or less.',
      );
    }
    return clean;
  }

  String _validatedDescription(String value) {
    final String clean = _requiredText(value, 'Description');
    if (clean.length > 200) {
      throw const MySkillsServiceException(
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
      throw const MySkillsServiceException('Invalid experience level.');
    }
    return clean;
  }

  String _requiredText(String value, String label) {
    final String clean = value.trim();
    if (clean.isEmpty) {
      throw MySkillsServiceException('$label is required.');
    }
    return clean;
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Design & Creative':
        return Icons.design_services_outlined;
      case 'Photography':
        return Icons.camera_alt_outlined;
      case 'Video & Media':
        return Icons.movie_creation_outlined;
      case 'Technology':
        return Icons.code_rounded;
      case 'Music':
        return Icons.music_note_rounded;
      case 'Language':
        return Icons.translate_rounded;
      case 'Education':
        return Icons.school_outlined;
      case 'Lifestyle':
        return Icons.self_improvement_rounded;
      default:
        return Icons.lightbulb_outline_rounded;
    }
  }
}
