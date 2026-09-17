import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/user.dart';
import '../model/user_skill.dart';
import '../services/current_user_service.dart';
import '../services/profile_image_service.dart';

class ProfileControllerException implements Exception {
  final String message;

  const ProfileControllerException(
      this.message,
      );

  @override
  String toString() => message;
}

class ProfileSnapshot {
  final User user;
  final List<Skill> offeredSkills;
  final List<Skill> wantedSkills;

  const ProfileSnapshot({
    required this.user,
    required this.offeredSkills,
    required this.wantedSkills,
  });
}

class ProfileController {
  final ExploreRepository _repository;
  final CurrentUserService _currentUserService;
  final ProfileImageService _profileImageService;

  ProfileController({
    ExploreRepository? repository,
    CurrentUserService? currentUserService,
    ProfileImageService? profileImageService,
  })  : _repository =
      repository ??
          ExploreRepository.instance,
        _currentUserService =
            currentUserService ??
                CurrentUserService.instance,
        _profileImageService =
            profileImageService ??
                ProfileImageService.instance;

  // ============================================================
  // LOAD
  // ============================================================

  Future<ProfileSnapshot> loadProfile({
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        await _repository.refresh();
      } else {
        await _repository.initialize();
      }

      return _buildSnapshot();
    } on CurrentUserServiceException catch (error) {
      throw ProfileControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw ProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const ProfileControllerException(
        'Your profile could not be loaded. Please try again.',
      );
    }
  }

  // ============================================================
  // CURRENT SNAPSHOT
  // ============================================================

  ProfileSnapshot currentSnapshot() {
    try {
      return _buildSnapshot();
    } on ProfileControllerException {
      rethrow;
    } on CurrentUserServiceException catch (error) {
      throw ProfileControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw ProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const ProfileControllerException(
        'Your profile could not be prepared.',
      );
    }
  }

  // ============================================================
  // PICK PROFILE IMAGE
  // ============================================================

  Future<ProfileSnapshot?> pickProfileImage() async {
    try {
      final User? updatedUser =
      await _profileImageService
          .pickAndSaveCurrentUserProfileImage();

      if (updatedUser == null) {
        return null;
      }

      return _buildSnapshot();
    } on ProfileImageServiceException catch (error) {
      throw ProfileControllerException(
        error.message,
      );
    } on CurrentUserServiceException catch (error) {
      throw ProfileControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw ProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const ProfileControllerException(
        'Profile photo could not be updated. Please try again.',
      );
    }
  }

  // ============================================================
  // REMOVE PROFILE IMAGE
  // ============================================================

  Future<ProfileSnapshot> removeProfileImage() async {
    try {
      await _profileImageService
          .removeCurrentUserProfileImage();

      return _buildSnapshot();
    } on ProfileImageServiceException catch (error) {
      throw ProfileControllerException(
        error.message,
      );
    } on CurrentUserServiceException catch (error) {
      throw ProfileControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw ProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const ProfileControllerException(
        'Profile photo could not be removed. Please try again.',
      );
    }
  }

  // ============================================================
  // BUILD SNAPSHOT
  // ============================================================

  ProfileSnapshot _buildSnapshot() {
    final String userId =
    _currentUserService.requireUserId();

    final User? user =
    _repository.findUserById(
      userId,
    );

    if (user == null) {
      throw const ProfileControllerException(
        'Your profile could not be found.',
      );
    }

    final List<Skill> offeredSkills =
    _resolveSkills(
      _repository
          .getOfferedSkillsForUser(
        userId,
      ),
    );

    final List<Skill> wantedSkills =
    _resolveSkills(
      _repository
          .getWantedSkillsForUser(
        userId,
      ),
    );

    return ProfileSnapshot(
      user: user,
      offeredSkills:
      List<Skill>.unmodifiable(
        offeredSkills,
      ),
      wantedSkills:
      List<Skill>.unmodifiable(
        wantedSkills,
      ),
    );
  }

  // ============================================================
  // RESOLVE SKILLS
  // ============================================================

  List<Skill> _resolveSkills(
      List<UserSkill> relationships,
      ) {
    final List<Skill> result =
    <Skill>[];

    final Set<String> seenSkillIds =
    <String>{};

    for (final UserSkill relationship
    in relationships) {
      if (!seenSkillIds.add(
        relationship.skillId,
      )) {
        continue;
      }

      final Skill? skill =
      _repository.findSkillById(
        relationship.skillId,
      );

      if (skill != null) {
        result.add(
          skill,
        );
      }
    }

    result.sort(
          (
          Skill first,
          Skill second,
          ) =>
          first.title
              .toLowerCase()
              .compareTo(
            second.title
                .toLowerCase(),
          ),
    );

    return result;
  }
}