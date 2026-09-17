import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/user.dart';
import '../model/user_skill.dart';
import '../services/current_user_service.dart';

// ============================================================
// EXCEPTION
// ============================================================

class SkillDetailsControllerException
    implements Exception {
  final String message;

  const SkillDetailsControllerException(
      this.message,
      );

  @override
  String toString() => message;
}

// ============================================================
// PROVIDER INFO
// ============================================================

class SkillDetailsProvider {
  final User user;
  final String level;
  final List<String> wantedSkillTitles;
  final String learningInterest;

  const SkillDetailsProvider({
    required this.user,
    required this.level,
    required this.wantedSkillTitles,
    required this.learningInterest,
  });
}

// ============================================================
// SNAPSHOT
// ============================================================

class SkillDetailsSnapshot {
  final Skill skill;
  final String? currentUserId;
  final List<SkillDetailsProvider> providers;

  const SkillDetailsSnapshot({
    required this.skill,
    required this.currentUserId,
    required this.providers,
  });
}

// ============================================================
// CONTROLLER
// ============================================================

class SkillDetailsController {
  final ExploreRepository _repository;
  final CurrentUserService _currentUserService;

  SkillDetailsController({
    ExploreRepository? repository,
    CurrentUserService? currentUserService,
  })  : _repository =
      repository ??
          ExploreRepository.instance,
        _currentUserService =
            currentUserService ??
                CurrentUserService.instance;

  // ============================================================
  // LOAD
  // ============================================================

  Future<SkillDetailsSnapshot> loadSkillDetails(
      Skill skill,
      ) async {
    try {
      await _repository.initialize();

      return _buildSnapshot(
        skill,
      );
    } on ExploreRepositoryException catch (error) {
      throw SkillDetailsControllerException(
        error.message,
      );
    } catch (_) {
      throw const SkillDetailsControllerException(
        'Skill details could not be loaded. Please try again.',
      );
    }
  }

  // ============================================================
  // CURRENT SNAPSHOT
  // ============================================================

  SkillDetailsSnapshot currentSnapshot(
      Skill skill,
      ) {
    try {
      return _buildSnapshot(
        skill,
      );
    } catch (_) {
      throw const SkillDetailsControllerException(
        'Skill details could not be prepared.',
      );
    }
  }

  // ============================================================
  // VALIDATE SWAP REQUEST
  // ============================================================

  Future<void> validateSwapRequest({
    required Skill skill,
    required User provider,
  }) async {
    try {
      final String currentUserId =
      _currentUserService
          .requireUserId()
          .trim();

      if (currentUserId.isEmpty) {
        throw const SkillDetailsControllerException(
          'Current user identity is unavailable.',
        );
      }

      if (provider.id ==
          currentUserId) {
        throw const SkillDetailsControllerException(
          'You cannot request a skill swap with yourself.',
        );
      }

      await _repository.refresh();

      final User? freshProvider =
      _repository.findUserById(
        provider.id,
      );

      if (freshProvider == null) {
        throw const SkillDetailsControllerException(
          'This provider is no longer available.',
        );
      }

      final Skill? freshSkill =
      _repository.findSkillById(
        skill.id,
      );

      if (freshSkill == null) {
        throw const SkillDetailsControllerException(
          'This skill is no longer available.',
        );
      }

      final bool stillOffersSkill =
      _repository
          .getOfferedSkillsForUser(
        freshProvider.id,
      )
          .any(
            (
            UserSkill relationship,
            ) =>
        relationship.skillId ==
            freshSkill.id,
      );

      if (!stillOffersSkill) {
        throw SkillDetailsControllerException(
          '${freshProvider.name} no longer offers this skill.',
        );
      }
    } on SkillDetailsControllerException {
      rethrow;
    } on CurrentUserServiceException catch (error) {
      throw SkillDetailsControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw SkillDetailsControllerException(
        error.message,
      );
    } catch (_) {
      throw const SkillDetailsControllerException(
        'This swap request could not be prepared. Please try again.',
      );
    }
  }

  // ============================================================
  // BUILD SNAPSHOT
  // ============================================================

  SkillDetailsSnapshot _buildSnapshot(
      Skill skill,
      ) {
    final String? currentUserId =
    _currentUserIdOrNull();

    final List<User> users =
    _repository
        .getProvidersForSkill(
      skill.id,
    )
        .where(
          (
          User provider,
          ) =>
      provider.id
          .trim()
          .isNotEmpty &&
          provider.id !=
              currentUserId,
    )
        .toList();

    final List<SkillDetailsProvider> providers =
    users
        .map(
          (
          User provider,
          ) =>
          _buildProviderInfo(
            skill:
            skill,
            provider:
            provider,
          ),
    )
        .toList();

    return SkillDetailsSnapshot(
      skill:
      skill,
      currentUserId:
      currentUserId,
      providers:
      List<SkillDetailsProvider>.unmodifiable(
        providers,
      ),
    );
  }

  // ============================================================
  // PROVIDER INFO
  // ============================================================

  SkillDetailsProvider _buildProviderInfo({
    required Skill skill,
    required User provider,
  }) {
    final UserSkill? offeredRelationship =
    _repository.findUserSkill(
      userId:
      provider.id,
      skillId:
      skill.id,
      type:
      UserSkillType.offered,
    );

    final List<String> wantedSkillTitles =
    _getWantedSkillTitles(
      provider.id,
    );

    final String providerLevel =
    offeredRelationship
        ?.level
        .trim()
        .isNotEmpty ==
        true
        ? offeredRelationship!
        .level
        .trim()
        : skill.level
        .trim()
        .isEmpty
        ? 'Level not listed'
        : skill.level.trim();

    return SkillDetailsProvider(
      user:
      provider,
      level:
      providerLevel,
      wantedSkillTitles:
      List<String>.unmodifiable(
        wantedSkillTitles,
      ),
      learningInterest:
      _buildLearningInterestText(
        wantedSkillTitles,
      ),
    );
  }

  // ============================================================
  // WANTED SKILLS
  // ============================================================

  List<String> _getWantedSkillTitles(
      String userId,
      ) {
    final Set<String> seenTitles =
    <String>{};

    final List<String> titles =
    <String>[];

    for (final UserSkill relationship
    in _repository.getWantedSkillsForUser(
      userId,
    )) {
      final Skill? wantedSkill =
      _repository.findSkillById(
        relationship.skillId,
      );

      if (wantedSkill == null) {
        continue;
      }

      final String title =
      wantedSkill.title.trim();

      if (title.isEmpty) {
        continue;
      }

      final String normalized =
      title.toLowerCase();

      if (!seenTitles.add(
        normalized,
      )) {
        continue;
      }

      titles.add(
        title,
      );
    }

    titles.sort(
          (
          String first,
          String second,
          ) =>
          first
              .toLowerCase()
              .compareTo(
            second.toLowerCase(),
          ),
    );

    return titles;
  }

  // ============================================================
  // LEARNING INTEREST
  // ============================================================

  String _buildLearningInterestText(
      List<String> wantedSkillTitles,
      ) {
    if (wantedSkillTitles.isEmpty) {
      return 'No learning interests listed';
    }

    if (wantedSkillTitles.length ==
        1) {
      return 'Wants to learn: '
          '${wantedSkillTitles.first}';
    }

    final int remaining =
        wantedSkillTitles.length - 1;

    return 'Wants to learn: '
        '${wantedSkillTitles.first} '
        '+ $remaining more';
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? _currentUserIdOrNull() {
    try {
      final String userId =
      _currentUserService
          .requireUserId()
          .trim();

      if (userId.isEmpty) {
        return null;
      }

      return userId;
    } catch (_) {
      return null;
    }
  }
}