import '../model/repositories/explore_repository.dart';
import '../model/repositories/firestore_profile_repository.dart';
import '../model/repositories/local_user_data_projection_repository.dart';
import '../model/user.dart';
import 'current_user_service.dart';

class ProfileServiceException implements Exception {
  final String message;

  const ProfileServiceException(this.message);

  @override
  String toString() => message;
}

class ProfileService {
  ProfileService({
    FirestoreProfileRepository? firestoreRepository,
    LocalUserDataProjectionRepository? localRepository,
    CurrentUserService? currentUserService,
    ExploreRepository? exploreRepository,
  }) : _firestoreRepository =
           firestoreRepository ?? FirestoreProfileRepository.instance,
       _localRepository =
           localRepository ?? LocalUserDataProjectionRepository.instance,
       _currentUserService = currentUserService ?? CurrentUserService.instance,
       _exploreRepository = exploreRepository ?? ExploreRepository.instance;

  static final ProfileService instance = ProfileService();

  final FirestoreProfileRepository _firestoreRepository;
  final LocalUserDataProjectionRepository _localRepository;
  final CurrentUserService _currentUserService;
  final ExploreRepository _exploreRepository;

  Future<User> prepareCurrentSession() {
    return _currentUserService.runForSession<User>(() async {
      return _loadAndProject(allowStaleLocalFallback: true);
    });
  }

  Future<User> loadCurrentProfile({bool allowStaleLocalFallback = true}) {
    return _currentUserService.runForSession<User>(() async {
      return _loadAndProject(allowStaleLocalFallback: allowStaleLocalFallback);
    });
  }

  Future<User> saveCurrentProfile({
    required String name,
    required String city,
    required String bio,
    required String availability,
    required String language,
    required String preferredMode,
    required String teachingStyle,
  }) {
    return _currentUserService.runForSession<User>(() async {
      final String uid = _currentUserService.requireUserId();
      final FirestoreProfileData updated;
      try {
        updated = await _firestoreRepository.updateEditableProfile(
          uid: uid,
          name: name,
          city: city,
          bio: bio,
          availability: availability,
          language: language,
          preferredMode: preferredMode,
          teachingStyle: teachingStyle,
        );
      } on FirestoreProfileRepositoryException catch (error) {
        throw ProfileServiceException(error.message);
      }

      _currentUserService.requireActiveOperation();
      final User projected;
      try {
        _currentUserService.requireActiveOperation();
        projected = await _localRepository.projectProfile(
          uid: uid,
          profile: updated,
        );
      } on LocalUserDataProjectionException {
        throw const ProfileServiceException(
          'Your profile was saved to the cloud, but its local copy could not '
          'be refreshed. Please reload your profile.',
        );
      }

      _currentUserService.requireActiveOperation();
      try {
        await _exploreRepository.refresh();
      } on ExploreRepositoryException {
        throw const ProfileServiceException(
          'Your profile was saved, but the app could not refresh it locally. '
          'Please reload your profile.',
        );
      }
      _currentUserService.requireActiveOperation();
      return projected;
    });
  }

  Future<User> _loadAndProject({required bool allowStaleLocalFallback}) async {
    final String uid = _currentUserService.requireUserId();
    final FirestoreProfileLookup lookup;
    try {
      lookup = await _firestoreRepository.lookup(uid);
    } on FirestoreProfileRepositoryException catch (error) {
      throw ProfileServiceException(error.message);
    }
    _currentUserService.requireActiveOperation();

    FirestoreProfileData? cloudProfile = lookup.profile;
    if (lookup.status == FirestoreProfileLookupStatus.confirmedServerAbsent) {
      final User local = await _requireLocalFallback(uid);
      _currentUserService.requireActiveOperation();
      final DateTime now = DateTime.now().toUtc();
      final FirestoreProfileData bootstrap = FirestoreProfileData(
        name: local.name,
        city: local.city,
        bio: local.bio,
        availability: local.availability,
        language: local.language,
        preferredMode: local.preferredMode,
        teachingStyle: local.teachingStyle,
        memberSince: local.memberSince,
        profileCompleted: local.profileCompleted,
        schemaVersion: FirestoreProfileRepository.schemaVersion,
        skillsBootstrapVersion: 0,
        createdAt: now,
        updatedAt: now,
      );
      try {
        await _firestoreRepository.createInitialProfile(
          uid: uid,
          sourceUid: local.id,
          profile: bootstrap,
        );
      } on FirestoreProfileRepositoryException catch (error) {
        throw ProfileServiceException(error.message);
      }
      _currentUserService.requireActiveOperation();
      final FirestoreProfileLookup created;
      try {
        created = await _firestoreRepository.lookup(uid);
      } on FirestoreProfileRepositoryException catch (error) {
        throw ProfileServiceException(error.message);
      }
      _currentUserService.requireActiveOperation();
      if (!created.hasDocument) {
        throw const ProfileServiceException(
          'Your cloud profile was created but could not be reloaded. '
          'Please try again.',
        );
      }
      cloudProfile = created.profile;
    } else if (lookup.status == FirestoreProfileLookupStatus.unavailable) {
      if (!allowStaleLocalFallback) {
        throw const ProfileServiceException(
          'Your cloud profile is unavailable. Check your connection and try again.',
        );
      }
      return _requireLocalFallback(uid);
    }

    if (cloudProfile == null) {
      throw const ProfileServiceException(
        'Your cloud profile could not be prepared.',
      );
    }
    _currentUserService.requireActiveOperation();
    try {
      _currentUserService.requireActiveOperation();
      final User projected = await _localRepository.projectProfile(
        uid: uid,
        profile: cloudProfile,
      );
      _currentUserService.requireActiveOperation();
      return projected;
    } on LocalUserDataProjectionException {
      throw const ProfileServiceException(
        'Your cloud profile is available, but its local copy could not be '
        'prepared. Please try again.',
      );
    }
  }

  Future<User> _requireLocalFallback(String uid) async {
    try {
      final User? local = await _localRepository.loadProfile(uid);
      _currentUserService.requireActiveOperation();
      if (local == null) {
        throw const ProfileServiceException(
          'Your same-account local profile could not be found.',
        );
      }
      return local;
    } on ProfileServiceException {
      rethrow;
    } on LocalUserDataProjectionException {
      throw const ProfileServiceException(
        'Your same-account local profile could not be loaded.',
      );
    }
  }
}
