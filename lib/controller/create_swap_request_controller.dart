import '../model/repositories/explore_repository.dart';
import '../model/repositories/my_skills_repository.dart';
import '../model/skill.dart';
import '../model/swap_request.dart';
import '../model/user.dart';
import '../services/current_user_service.dart';
import '../services/swap_service.dart';

// ============================================================
// EXCEPTION
// ============================================================

class CreateSwapRequestControllerException
    implements Exception {
  final String message;

  const CreateSwapRequestControllerException(
      this.message,
      );

  @override
  String toString() => message;
}

// ============================================================
// INPUT
// ============================================================

class CreateSwapRequestInput {
  final String? providerUserId;
  final String? skillToLearnId;
  final String? skillToOfferId;
  final String? skillToOffer;

  final String providerName;
  final String providerInitials;
  final String providerCity;
  final String skillToLearn;

  const CreateSwapRequestInput({
    required this.providerUserId,
    required this.skillToLearnId,
    required this.skillToOfferId,
    required this.skillToOffer,
    required this.providerName,
    required this.providerInitials,
    required this.providerCity,
    required this.skillToLearn,
  });
}

// ============================================================
// SNAPSHOT
// ============================================================

class CreateSwapRequestSnapshot {
  final String currentUserId;
  final User? provider;
  final Skill? skillToLearn;
  final List<Skill> availableOfferSkills;
  final Skill? preselectedOfferSkill;
  final bool providerStillOffersLearnSkill;

  const CreateSwapRequestSnapshot({
    required this.currentUserId,
    required this.provider,
    required this.skillToLearn,
    required this.availableOfferSkills,
    required this.preselectedOfferSkill,
    required this.providerStillOffersLearnSkill,
  });

  String? get providerUserId =>
      provider?.id;
}

// ============================================================
// CONTROLLER
// ============================================================

class CreateSwapRequestController {
  final ExploreRepository _exploreRepository;
  final MySkillsRepository _mySkillsRepository;
  final CurrentUserService _currentUserService;
  final SwapService _swapService;

  CreateSwapRequestController({
    ExploreRepository? exploreRepository,
    MySkillsRepository? mySkillsRepository,
    CurrentUserService? currentUserService,
    SwapService? swapService,
  })  : _exploreRepository =
      exploreRepository ??
          ExploreRepository.instance,
        _mySkillsRepository =
            mySkillsRepository ??
                MySkillsRepository.instance,
        _currentUserService =
            currentUserService ??
                CurrentUserService.instance,
        _swapService =
            swapService ??
                SwapService.instance;

  // ============================================================
  // LOAD
  // ============================================================

  Future<CreateSwapRequestSnapshot> load(
      CreateSwapRequestInput input,
      ) async {
    try {
      final String currentUserId =
      _currentUserService.requireUserId();

      await _swapService.initialize();

      await _exploreRepository.refresh();

      final User? provider =
      _resolveProvider(
        input,
      );

      final Skill? skillToLearn =
      _resolveSkillToLearn(
        input,
      );

      final List<ManagedSkill> managedSkills =
      await _mySkillsRepository
          .getOfferedSkills(
        currentUserId,
      );

      final String? learnSkillId =
          skillToLearn?.id;

      final List<Skill> availableSkills =
      managedSkills
          .map(
            (
            ManagedSkill item,
            ) =>
        item.skill,
      )
          .where(
            (
            Skill skill,
            ) =>
        skill.id !=
            learnSkillId,
      )
          .toList();

      availableSkills.sort(
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

      final Skill? preselectedSkill =
      _resolveBestOfferSkill(
        input:
        input,
        availableSkills:
        availableSkills,
        provider:
        provider,
      );

      final bool providerStillOffers =
      _providerStillOffersLearnSkill(
        provider:
        provider,
        skillToLearn:
        skillToLearn,
      );

      return CreateSwapRequestSnapshot(
        currentUserId:
        currentUserId,
        provider:
        provider,
        skillToLearn:
        skillToLearn,
        availableOfferSkills:
        List<Skill>.unmodifiable(
          availableSkills,
        ),
        preselectedOfferSkill:
        preselectedSkill,
        providerStillOffersLearnSkill:
        providerStillOffers,
      );
    } on CurrentUserServiceException catch (error) {
      throw CreateSwapRequestControllerException(
        error.message,
      );
    } on MySkillsRepositoryException catch (error) {
      throw CreateSwapRequestControllerException(
        error.message,
      );
    } on SwapServiceException catch (error) {
      throw CreateSwapRequestControllerException(
        error.message,
      );
    } on ExploreRepositoryException catch (error) {
      throw CreateSwapRequestControllerException(
        error.message,
      );
    } catch (_) {
      throw const CreateSwapRequestControllerException(
        'Swap request details could not be loaded. Please try again.',
      );
    }
  }

  // ============================================================
  // SESSION MODES
  // ============================================================

  List<String> supportedModes({
    required Skill? skillToLearn,
    required Skill? skillToOffer,
  }) {
    if (skillToLearn == null ||
        skillToOffer == null) {
      return const <String>[];
    }

    final List<String> modes =
    <String>[];

    if (skillToLearn.supportsSessionMode(
      'Online',
    ) &&
        skillToOffer.supportsSessionMode(
          'Online',
        )) {
      modes.add(
        'Online',
      );
    }

    if (skillToLearn.supportsSessionMode(
      'In-person',
    ) &&
        skillToOffer.supportsSessionMode(
          'In-person',
        )) {
      modes.add(
        'In-person',
      );
    }

    return List<String>.unmodifiable(
      modes,
    );
  }

  bool isModeSupported({
    required Skill? skillToLearn,
    required Skill? skillToOffer,
    required String mode,
  }) {
    return supportedModes(
      skillToLearn:
      skillToLearn,
      skillToOffer:
      skillToOffer,
    ).contains(
      mode,
    );
  }

  String? normalizedMode({
    required Skill? skillToLearn,
    required Skill? skillToOffer,
    required String? currentMode,
  }) {
    final List<String> modes =
    supportedModes(
      skillToLearn:
      skillToLearn,
      skillToOffer:
      skillToOffer,
    );

    if (currentMode != null &&
        modes.contains(
          currentMode,
        )) {
      return currentMode;
    }

    if (modes.isEmpty) {
      return null;
    }

    return modes.first;
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<SwapRequest> submitRequest({
    required CreateSwapRequestSnapshot snapshot,
    required Skill? skillToOffer,
    required String? selectedMode,
    required DateTime? proposedAt,
    required String meetingDetails,
    required String note,
  }) async {
    try {
      final String requesterUserId =
      _currentUserService.requireUserId();

      final User? provider =
          snapshot.provider;

      final Skill? skillToLearn =
          snapshot.skillToLearn;

      if (provider == null) {
        throw const CreateSwapRequestControllerException(
          'We could not safely identify this provider. Please go back and try again.',
        );
      }

      if (requesterUserId ==
          provider.id) {
        throw const CreateSwapRequestControllerException(
          'You cannot send a swap request to yourself.',
        );
      }

      if (skillToLearn == null) {
        throw const CreateSwapRequestControllerException(
          'We could not identify the skill you want to learn. Please go back and try again.',
        );
      }

      if (!_providerStillOffersLearnSkill(
        provider:
        provider,
        skillToLearn:
        skillToLearn,
      )) {
        throw const CreateSwapRequestControllerException(
          'This provider no longer offers the selected skill.',
        );
      }

      if (skillToOffer == null) {
        if (snapshot
            .availableOfferSkills
            .isEmpty) {
          throw const CreateSwapRequestControllerException(
            'Add an offered skill in My Skills before creating this request.',
          );
        }

        throw const CreateSwapRequestControllerException(
          'Please select a skill you can offer.',
        );
      }

      final bool stillOwnsOfferedSkill =
      snapshot
          .availableOfferSkills
          .any(
            (
            Skill skill,
            ) =>
        skill.id ==
            skillToOffer.id,
      );

      if (!stillOwnsOfferedSkill) {
        throw const CreateSwapRequestControllerException(
          'The selected offered skill is no longer available. Please reload and try again.',
        );
      }

      if (skillToLearn.id ==
          skillToOffer.id) {
        throw const CreateSwapRequestControllerException(
          'Please offer a different skill from the one you want to learn.',
        );
      }

      if (selectedMode == null ||
          !isModeSupported(
            skillToLearn:
            skillToLearn,
            skillToOffer:
            skillToOffer,
            mode:
            selectedMode,
          )) {
        throw const CreateSwapRequestControllerException(
          'Please choose a session mode supported by both skills.',
        );
      }

      if (proposedAt == null) {
        throw const CreateSwapRequestControllerException(
          'Please choose your preferred date and time.',
        );
      }

      if (!proposedAt.isAfter(
        DateTime.now(),
      )) {
        throw const CreateSwapRequestControllerException(
          'Please choose a future date and time.',
        );
      }

      final String cleanMeetingDetails =
      meetingDetails.trim();

      if (cleanMeetingDetails.isEmpty) {
        throw CreateSwapRequestControllerException(
          selectedMode ==
              'Online'
              ? 'Please enter your preferred online platform.'
              : 'Please enter a preferred public meeting area.',
        );
      }

      if (cleanMeetingDetails.length >
          150) {
        throw const CreateSwapRequestControllerException(
          'Meeting details must be 150 characters or less.',
        );
      }

      final String cleanNote =
      note.trim();

      if (cleanNote.length >
          300) {
        throw const CreateSwapRequestControllerException(
          'Message must be 300 characters or less.',
        );
      }

      return await _swapService.createRequest(
        requesterUserId:
        requesterUserId,
        providerUserId:
        provider.id,
        skillToLearnId:
        skillToLearn.id,
        skillToOfferId:
        skillToOffer.id,
        providerName:
        provider.name,
        providerInitials:
        provider.initials,
        providerCity:
        provider.city,
        skillToLearn:
        skillToLearn.title,
        skillToOffer:
        skillToOffer.title,
        proposedAt:
        proposedAt,
        mode:
        selectedMode,
        meetingDetails:
        cleanMeetingDetails,
        note:
        cleanNote.isEmpty
            ? null
            : cleanNote,
      );
    } on CreateSwapRequestControllerException {
      rethrow;
    } on CurrentUserServiceException catch (error) {
      throw CreateSwapRequestControllerException(
        error.message,
      );
    } on SwapServiceException catch (error) {
      throw CreateSwapRequestControllerException(
        error.message,
      );
    } catch (_) {
      throw const CreateSwapRequestControllerException(
        'We could not save your swap request. Please try again.',
      );
    }
  }

  // ============================================================
  // PROVIDER RESOLUTION
  // ============================================================

  User? _resolveProvider(
      CreateSwapRequestInput input,
      ) {
    final String? suppliedId =
    _cleanOptionalId(
      input.providerUserId,
    );

    if (suppliedId != null) {
      return _exploreRepository
          .findUserById(
        suppliedId,
      );
    }

    final String targetName =
    input.providerName
        .trim()
        .toLowerCase();

    if (targetName.isEmpty) {
      return null;
    }

    final List<User> matches =
    _exploreRepository.users
        .where(
          (
          User user,
          ) =>
      user.name
          .trim()
          .toLowerCase() ==
          targetName,
    )
        .toList();

    if (matches.length != 1) {
      return null;
    }

    return matches.single;
  }

  // ============================================================
  // SKILL RESOLUTION
  // ============================================================

  Skill? _resolveSkillToLearn(
      CreateSwapRequestInput input,
      ) {
    final String? suppliedId =
    _cleanOptionalId(
      input.skillToLearnId,
    );

    if (suppliedId != null) {
      return _exploreRepository
          .findSkillById(
        suppliedId,
      );
    }

    final String targetTitle =
    input.skillToLearn
        .trim()
        .toLowerCase();

    if (targetTitle.isEmpty) {
      return null;
    }

    final List<Skill> matches =
    _exploreRepository.skills
        .where(
          (
          Skill skill,
          ) =>
      skill.title
          .trim()
          .toLowerCase() ==
          targetTitle,
    )
        .toList();

    if (matches.length != 1) {
      return null;
    }

    return matches.single;
  }

  // ============================================================
  // PROVIDER STILL OFFERS SKILL
  // ============================================================

  bool _providerStillOffersLearnSkill({
    required User? provider,
    required Skill? skillToLearn,
  }) {
    if (provider == null ||
        skillToLearn == null) {
      return false;
    }

    return _exploreRepository
        .getOfferedSkillsForUser(
      provider.id,
    )
        .any(
          (
          relationship,
          ) =>
      relationship.skillId ==
          skillToLearn.id,
    );
  }

  // ============================================================
  // PRESELECT OFFER SKILL
  // ============================================================

  Skill? _resolveBestOfferSkill({
    required CreateSwapRequestInput input,
    required List<Skill> availableSkills,
    required User? provider,
  }) {
    if (availableSkills.isEmpty) {
      return null;
    }

    final String? preferredId =
    _cleanOptionalId(
      input.skillToOfferId,
    );

    if (preferredId != null) {
      for (final Skill skill
      in availableSkills) {
        if (skill.id ==
            preferredId) {
          return skill;
        }
      }
    }

    final String preferredTitle =
        input.skillToOffer
            ?.trim()
            .toLowerCase() ??
            '';

    if (preferredTitle.isNotEmpty) {
      final List<Skill> titleMatches =
      availableSkills
          .where(
            (
            Skill skill,
            ) =>
        skill.title
            .trim()
            .toLowerCase() ==
            preferredTitle,
      )
          .toList();

      if (titleMatches.length ==
          1) {
        return titleMatches.single;
      }
    }

    if (provider == null) {
      return null;
    }

    final Set<String> providerWantedSkillIds =
    _exploreRepository
        .getWantedSkillsForUser(
      provider.id,
    )
        .map(
          (
          relationship,
          ) =>
      relationship.skillId,
    )
        .toSet();

    if (providerWantedSkillIds.isEmpty) {
      return null;
    }

    final List<Skill> reciprocalMatches =
    availableSkills
        .where(
          (
          Skill skill,
          ) =>
          providerWantedSkillIds
              .contains(
            skill.id,
          ),
    )
        .toList();

    if (reciprocalMatches.length ==
        1) {
      return reciprocalMatches.single;
    }

    if (reciprocalMatches.isEmpty) {
      return null;
    }

    reciprocalMatches.sort(
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

    return reciprocalMatches.first;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String? _cleanOptionalId(
      String? value,
      ) {
    if (value == null) {
      return null;
    }

    final String cleaned =
    value.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    return cleaned;
  }
}