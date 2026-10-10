import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/user.dart';
import '../model/user_skill.dart';
import '../services/current_user_service.dart';
import '../services/profile_service.dart';
import '../services/profile_image_service.dart';
import '../services/review_service.dart';

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
  final double displayRating;
  final int displayReviewCount;

  const ProfileSnapshot({
    required this.user,
    required this.offeredSkills,
    required this.wantedSkills,
    required this.displayRating,
    required this.displayReviewCount,
  });
}

// ============================================================
// REVIEW DISPLAY STATS
// ============================================================

/// Result of ProfileController.loadReviewStats(): the Firestore-backed
/// rating/count when available, otherwise the legacy local fallback.
/// Never thrown from — callers always get a usable value.
class ReviewDisplayStats {
  final double rating;
  final int count;
  final bool fromCloud;

  const ReviewDisplayStats({
    required this.rating,
    required this.count,
    required this.fromCloud,
  });
}

class ProfileController {
  final ExploreRepository _repository;
  final CurrentUserService _currentUserService;
  final ProfileService _profileService;
  final ProfileImageService _profileImageService;
  final ReviewService _reviewService;

  ProfileController({
    ExploreRepository? repository,
    CurrentUserService? currentUserService,
    ProfileService? profileService,
    ProfileImageService? profileImageService,
    ReviewService? reviewService,
  })  : _repository =
      repository ??
          ExploreRepository.instance,
        _currentUserService =
            currentUserService ??
                CurrentUserService.instance,
        _profileService =
            profileService ??
                ProfileService.instance,
        _profileImageService =
            profileImageService ??
                ProfileImageService.instance,
        _reviewService =
            reviewService ??
                ReviewService.instance;

  // ============================================================
  // LOAD
  // ============================================================

  Future<ProfileSnapshot> loadProfile({
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

      return _buildSnapshot(
        authoritativeUser: user,
      );
    } on ProfileServiceException catch (error) {
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

  ProfileSnapshot _buildSnapshot({
    User? authoritativeUser,
  }) {
    final String userId =
    _currentUserService.requireUserId();

    final User? user =
    authoritativeUser ??
        _repository.findUserById(
          userId,
        );

    if (user == null || user.id != userId) {
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
      displayRating:
      user.rating,
      displayReviewCount:
      user.reviewCount,
    );
  }

  // ============================================================
  // REVIEW STATS
  // ============================================================

  /// Firestore-backed rating/count for the current user, with the
  /// legacy local User.rating/reviewCount as a silent fallback on any
  /// failure (offline, unavailable, etc.) — this must never throw,
  /// since the own-profile screen calls it right after first paint and
  /// cannot be allowed to surface a review-related error.
  Future<ReviewDisplayStats> loadReviewStats() async {
    final String userId;

    try {
      userId =
          _currentUserService.requireUserId();
    } on CurrentUserServiceException catch (error) {
      throw ProfileControllerException(
        error.message,
      );
    }

    final User? localUser =
    _repository.findUserById(
      userId,
    );

    final double fallbackRating =
        localUser?.rating ?? 0;

    final int fallbackCount =
        localUser?.reviewCount ?? 0;

    try {
      final ReceivedReviews result =
      await _reviewService.loadReviewsReceivedBy(
        userId,
      );

      if (result.available) {
        return ReviewDisplayStats(
          rating:
          result.averageRating,
          count:
          result.count,
          fromCloud:
          true,
        );
      }

      return ReviewDisplayStats(
        rating:
        fallbackRating,
        count:
        fallbackCount,
        fromCloud:
        false,
      );
    } catch (_) {
      return ReviewDisplayStats(
        rating:
        fallbackRating,
        count:
        fallbackCount,
        fromCloud:
        false,
      );
    }
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
