import '../model/repositories/explore_repository.dart';
import '../model/user.dart';
import '../services/current_user_service.dart';
import '../services/profile_image_service.dart';
import '../services/profile_service.dart';

// ============================================================
// EXCEPTION
// ============================================================

class EditProfileControllerException
    implements Exception {
  final String message;

  const EditProfileControllerException(
      this.message,
      );

  @override
  String toString() => message;
}

// ============================================================
// SNAPSHOT
// ============================================================

class EditProfileSnapshot {
  final User user;

  const EditProfileSnapshot({
    required this.user,
  });
}

// ============================================================
// CONTROLLER
// ============================================================

class EditProfileController {
  final ExploreRepository _repository;
  final CurrentUserService _currentUserService;
  final ProfileImageService _profileImageService;
  final ProfileService _profileService;

  EditProfileController({
    ExploreRepository? repository,
    CurrentUserService? currentUserService,
    ProfileImageService? profileImageService,
    ProfileService? profileService,
  })  : _repository =
      repository ??
          ExploreRepository.instance,
        _currentUserService =
            currentUserService ??
                CurrentUserService.instance,
        _profileImageService =
            profileImageService ??
                ProfileImageService.instance,
        _profileService =
            profileService ??
                ProfileService.instance;

  // ============================================================
  // LOAD
  // ============================================================

  Future<EditProfileSnapshot> loadProfile({
    bool refresh = false,
  }) async {
    try {
      final User user =
      await _profileService
          .loadCurrentProfile();

      if (refresh) {
        await _repository.refresh();
      } else {
        await _repository.initialize();
      }
      _currentUserService.requireCurrentUser(
        user.id,
        message: 'The authenticated account changed while loading your profile.',
      );

      return EditProfileSnapshot(
        user: user,
      );
    } on ProfileServiceException catch (error) {
      throw EditProfileControllerException(
        error.message,
      );
    } on EditProfileControllerException {
      rethrow;
    } on CurrentUserServiceException catch (error) {
      throw EditProfileControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw EditProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const EditProfileControllerException(
        'Your profile could not be loaded. Please try again.',
      );
    }
  }

  // ============================================================
  // CURRENT SNAPSHOT
  // ============================================================

  EditProfileSnapshot currentSnapshot() {
    try {
      final User user =
      _requireCurrentUser();

      return EditProfileSnapshot(
        user: user,
      );
    } on EditProfileControllerException {
      rethrow;
    } on CurrentUserServiceException catch (error) {
      throw EditProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const EditProfileControllerException(
        'Your profile could not be prepared.',
      );
    }
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<EditProfileSnapshot> saveProfile({
    required String name,
    required String city,
    required String bio,
    required String availability,
    required String language,
    required String preferredMode,
    required String teachingStyle,
  }) async {
    try {
      final User updatedUser =
      await _profileService
          .saveCurrentProfile(
        name: name,
        city: city,
        bio: bio,
        availability: availability,
        language: language,
        preferredMode: preferredMode,
        teachingStyle: teachingStyle,
      );

      return EditProfileSnapshot(
        user: updatedUser,
      );
    } on ProfileServiceException catch (error) {
      throw EditProfileControllerException(
        error.message,
      );
    } on CurrentUserServiceException catch (error) {
      throw EditProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const EditProfileControllerException(
        'Your profile could not be saved. Please try again.',
      );
    }
  }

  // ============================================================
  // PICK PROFILE IMAGE
  // ============================================================

  Future<EditProfileSnapshot?> pickProfileImage() async {
    try {
      final User? updatedUser =
      await _profileImageService
          .pickAndSaveCurrentUserProfileImage();

      if (updatedUser == null) {
        return null;
      }

      return EditProfileSnapshot(
        user: updatedUser,
      );
    } on ProfileImageServiceException catch (error) {
      throw EditProfileControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw EditProfileControllerException(
        error.message,
      );
    } on CurrentUserServiceException catch (error) {
      throw EditProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const EditProfileControllerException(
        'Profile photo could not be updated. Please try again.',
      );
    }
  }

  // ============================================================
  // REMOVE PROFILE IMAGE
  // ============================================================

  Future<EditProfileSnapshot>
  removeProfileImage() async {
    try {
      final User updatedUser =
      await _profileImageService
          .removeCurrentUserProfileImage();

      return EditProfileSnapshot(
        user: updatedUser,
      );
    } on ProfileImageServiceException catch (error) {
      throw EditProfileControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw EditProfileControllerException(
        error.message,
      );
    } on CurrentUserServiceException catch (error) {
      throw EditProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const EditProfileControllerException(
        'Profile photo could not be removed. Please try again.',
      );
    }
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User _requireCurrentUser() {
    final String userId =
    _currentUserService.requireUserId();

    final User? user =
    _repository.findUserById(
      userId,
    );

    if (user == null) {
      throw const EditProfileControllerException(
        'Your profile could not be found.',
      );
    }

    return user;
  }
}
