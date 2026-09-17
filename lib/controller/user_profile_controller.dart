import '../model/conversation.dart';
import '../model/repositories/explore_repository.dart';
import '../model/repositories/review_repository.dart';
import '../model/review.dart';
import '../model/skill.dart';
import '../model/user.dart';
import '../services/chat_service.dart';

// ============================================================
// EXCEPTION
// ============================================================

class UserProfileControllerException
    implements Exception {
  final String message;

  const UserProfileControllerException(
      this.message,
      );

  @override
  String toString() => message;
}

// ============================================================
// REVIEW ITEM
// ============================================================

class UserProfileReview {
  final Review review;
  final User? reviewer;

  const UserProfileReview({
    required this.review,
    required this.reviewer,
  });

  String get reviewerName {
    final String? name =
    reviewer?.name.trim();

    if (name == null ||
        name.isEmpty) {
      return 'TubiLearn member';
    }

    return name;
  }
}

// ============================================================
// SNAPSHOT
// ============================================================

class UserProfileSnapshot {
  final User user;
  final List<Skill> offeredSkills;
  final List<Skill> wantedSkills;
  final List<UserProfileReview> reviews;

  const UserProfileSnapshot({
    required this.user,
    required this.offeredSkills,
    required this.wantedSkills,
    required this.reviews,
  });
}

// ============================================================
// CONVERSATION RESULT
// ============================================================

enum UserProfileConversationStatus {
  ready,
  previousHidden,
}

class UserProfileConversationResult {
  final UserProfileConversationStatus status;
  final String? conversationId;
  final String? hiddenConversationId;

  const UserProfileConversationResult._({
    required this.status,
    required this.conversationId,
    required this.hiddenConversationId,
  });

  const UserProfileConversationResult.ready(
      String conversationId,
      ) : this._(
    status:
    UserProfileConversationStatus.ready,
    conversationId:
    conversationId,
    hiddenConversationId:
    null,
  );

  const UserProfileConversationResult.previousHidden(
      String conversationId,
      ) : this._(
    status:
    UserProfileConversationStatus.previousHidden,
    conversationId:
    null,
    hiddenConversationId:
    conversationId,
  );
}

// ============================================================
// SWAP DATA
// ============================================================

class UserProfileSwapRequestData {
  final User provider;
  final Skill skillToLearn;

  const UserProfileSwapRequestData({
    required this.provider,
    required this.skillToLearn,
  });
}

// ============================================================
// CONTROLLER
// ============================================================

class UserProfileController {
  final ExploreRepository _exploreRepository;
  final ReviewRepository _reviewRepository;
  final ChatService _chatService;

  UserProfileController({
    ExploreRepository? exploreRepository,
    ReviewRepository? reviewRepository,
    ChatService? chatService,
  })  : _exploreRepository =
      exploreRepository ??
          ExploreRepository.instance,
        _reviewRepository =
            reviewRepository ??
                ReviewRepository.instance,
        _chatService =
            chatService ??
                ChatService.instance;

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<UserProfileSnapshot> loadProfile(
      User fallbackUser, {
        bool refresh = true,
      }) async {
    try {
      await _exploreRepository.initialize();

      if (refresh) {
        try {
          await _exploreRepository.refresh();
        } on ExploreRepositoryException {
          // Keep already-loaded reference data usable.
        }
      }

      final User user =
      _resolveUser(
        fallbackUser,
      );

      final List<Review> reviews =
      await _reviewRepository
          .getReviewsForUser(
        user.id,
      );

      return _buildSnapshot(
        user:
        user,
        reviews:
        reviews,
      );
    } on ReviewRepositoryException catch (error) {
      throw UserProfileControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw UserProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const UserProfileControllerException(
        'Profile details could not be loaded. Please try again.',
      );
    }
  }

  // ============================================================
  // LOAD REVIEWS ONLY
  // ============================================================

  Future<List<UserProfileReview>> loadReviews(
      User fallbackUser,
      ) async {
    try {
      await _exploreRepository.initialize();

      final User user =
      _resolveUser(
        fallbackUser,
      );

      final List<Review> reviews =
      await _reviewRepository
          .getReviewsForUser(
        user.id,
      );

      return List<UserProfileReview>.unmodifiable(
        _resolveReviews(
          reviews,
        ),
      );
    } on ReviewRepositoryException catch (error) {
      throw UserProfileControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw UserProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const UserProfileControllerException(
        'Reviews could not be loaded.',
      );
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<UserProfileSnapshot> refreshProfile(
      User fallbackUser,
      ) async {
    try {
      try {
        await _exploreRepository.refresh();
      } on ExploreRepositoryException {
        // Continue using current reference data if refresh fails.
      }

      final User user =
      _resolveUser(
        fallbackUser,
      );

      final List<Review> reviews =
      await _reviewRepository
          .getReviewsForUser(
        user.id,
      );

      return _buildSnapshot(
        user:
        user,
        reviews:
        reviews,
      );
    } on ReviewRepositoryException catch (error) {
      throw UserProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const UserProfileControllerException(
        'Profile could not be refreshed.',
      );
    }
  }

  // ============================================================
  // CURRENT SNAPSHOT
  // ============================================================

  UserProfileSnapshot currentSnapshot(
      User fallbackUser, {
        List<Review> reviews =
        const <Review>[],
      }) {
    try {
      final User user =
      _resolveUser(
        fallbackUser,
      );

      return _buildSnapshot(
        user:
        user,
        reviews:
        reviews,
      );
    } catch (_) {
      throw const UserProfileControllerException(
        'Profile details could not be prepared.',
      );
    }
  }

  // ============================================================
  // OPEN CONVERSATION
  // ============================================================

  Future<UserProfileConversationResult>
  openConversation(
      UserProfileSnapshot snapshot,
      ) async {
    final String skillWanted =
    snapshot.offeredSkills.isEmpty
        ? 'Skill'
        : snapshot
        .offeredSkills
        .first
        .title;

    final String skillOffered =
    snapshot.wantedSkills.isEmpty
        ? 'Skill'
        : snapshot
        .wantedSkills
        .first
        .title;

    try {
      final Conversation conversation =
      await _chatService
          .getOrCreateConversation(
        userId:
        snapshot.user.id,
        userName:
        snapshot.user.name,
        initials:
        snapshot.user.initials,
        city:
        snapshot.user.city,
        skillWanted:
        skillWanted,
        skillOffered:
        skillOffered,
      );

      return UserProfileConversationResult.ready(
        conversation.id,
      );
    } on HiddenConversationException catch (error) {
      return UserProfileConversationResult
          .previousHidden(
        error.conversationId,
      );
    } on ChatServiceException catch (error) {
      throw UserProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const UserProfileControllerException(
        'Conversation could not be opened. Please try again.',
      );
    }
  }

  // ============================================================
  // RESTORE CONVERSATION
  // ============================================================

  Future<String> restoreConversation(
      String conversationId,
      ) async {
    try {
      final Conversation conversation =
      await _chatService
          .restoreConversation(
        conversationId,
      );

      return conversation.id;
    } on ChatServiceException catch (error) {
      throw UserProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const UserProfileControllerException(
        'Conversation could not be restored. Please try again.',
      );
    }
  }

  // ============================================================
  // START NEW CONVERSATION
  // ============================================================

  Future<String> startNewConversation(
      UserProfileSnapshot snapshot,
      ) async {
    final String skillWanted =
    snapshot.offeredSkills.isEmpty
        ? 'Skill'
        : snapshot
        .offeredSkills
        .first
        .title;

    final String skillOffered =
    snapshot.wantedSkills.isEmpty
        ? 'Skill'
        : snapshot
        .wantedSkills
        .first
        .title;

    try {
      final Conversation conversation =
      await _chatService
          .startNewConversation(
        userId:
        snapshot.user.id,
        userName:
        snapshot.user.name,
        initials:
        snapshot.user.initials,
        city:
        snapshot.user.city,
        skillWanted:
        skillWanted,
        skillOffered:
        skillOffered,
      );

      return conversation.id;
    } on ChatServiceException catch (error) {
      throw UserProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const UserProfileControllerException(
        'A new conversation could not be created. Please try again.',
      );
    }
  }

  // ============================================================
  // PREPARE SWAP REQUEST
  // ============================================================

  Future<UserProfileSwapRequestData>
  prepareSwapRequest(
      User fallbackUser,
      ) async {
    try {
      try {
        await _exploreRepository.refresh();
      } on ExploreRepositoryException {
        // Use current cached data if refresh is temporarily unavailable.
      }

      final User provider =
      _resolveUser(
        fallbackUser,
      );

      final List<Skill> offeredSkills =
      _resolveSkills(
        provider.id,
        offered:
        true,
      );

      if (offeredSkills.isEmpty) {
        throw const UserProfileControllerException(
          'This user has no offered skill available for swap.',
        );
      }

      return UserProfileSwapRequestData(
        provider:
        provider,
        skillToLearn:
        offeredSkills.first,
      );
    } on UserProfileControllerException {
      rethrow;
    } on ExploreRepositoryException catch (error) {
      throw UserProfileControllerException(
        error.message,
      );
    } catch (_) {
      throw const UserProfileControllerException(
        'Swap request could not be prepared. Please try again.',
      );
    }
  }

  // ============================================================
  // COPY SUMMARY CONTENT
  // ============================================================

  String buildProfileSummary(
      UserProfileSnapshot snapshot,
      ) {
    final String offered =
    snapshot.offeredSkills.isEmpty
        ? 'None listed'
        : snapshot.offeredSkills
        .map(
          (
          Skill skill,
          ) =>
      skill.title,
    )
        .join(
      ', ',
    );

    final String wanted =
    snapshot.wantedSkills.isEmpty
        ? 'None listed'
        : snapshot.wantedSkills
        .map(
          (
          Skill skill,
          ) =>
      skill.title,
    )
        .join(
      ', ',
    );

    final User user =
        snapshot.user;

    final String ratingSummary =
    user.reviewCount > 0
        ? '${user.rating.toStringAsFixed(1)} '
        '(${user.reviewCount} reviews)'
        : 'No reviews yet';

    return '${user.name}\n'
        '${user.city}\n'
        'Rating: $ratingSummary\n'
        'Completed swaps: ${user.completedSwaps}\n'
        'Skills offered: $offered\n'
        'Wants to learn: $wanted\n'
        'Availability: ${user.availability}\n'
        'Preferred mode: ${user.preferredMode}';
  }

  // ============================================================
  // BUILD SNAPSHOT
  // ============================================================

  UserProfileSnapshot _buildSnapshot({
    required User user,
    required List<Review> reviews,
  }) {
    final List<Skill> offeredSkills =
    _resolveSkills(
      user.id,
      offered:
      true,
    );

    final List<Skill> wantedSkills =
    _resolveSkills(
      user.id,
      offered:
      false,
    );

    final List<UserProfileReview> resolvedReviews =
    _resolveReviews(
      reviews,
    );

    return UserProfileSnapshot(
      user:
      user,
      offeredSkills:
      List<Skill>.unmodifiable(
        offeredSkills,
      ),
      wantedSkills:
      List<Skill>.unmodifiable(
        wantedSkills,
      ),
      reviews:
      List<UserProfileReview>.unmodifiable(
        resolvedReviews,
      ),
    );
  }

  // ============================================================
  // RESOLVE USER
  // ============================================================

  User _resolveUser(
      User fallbackUser,
      ) {
    final User? latestUser =
    _exploreRepository.findUserById(
      fallbackUser.id,
    );

    return latestUser ??
        fallbackUser;
  }

  // ============================================================
  // RESOLVE SKILLS
  // ============================================================

  List<Skill> _resolveSkills(
      String userId, {
        required bool offered,
      }) {
    final relationships =
    offered
        ? _exploreRepository
        .getOfferedSkillsForUser(
      userId,
    )
        : _exploreRepository
        .getWantedSkillsForUser(
      userId,
    );

    final List<Skill> skills =
    relationships
        .map(
          (
          relationship,
          ) =>
          _exploreRepository
              .findSkillById(
            relationship.skillId,
          ),
    )
        .whereType<Skill>()
        .toList();

    skills.sort(
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

    return skills;
  }

  // ============================================================
  // RESOLVE REVIEWS
  // ============================================================

  List<UserProfileReview> _resolveReviews(
      List<Review> reviews,
      ) {
    return reviews
        .map(
          (
          Review review,
          ) =>
          UserProfileReview(
            review:
            review,
            reviewer:
            _exploreRepository
                .findUserById(
              review.reviewerUserId,
            ),
          ),
    )
        .toList();
  }
}