import '../model/managed_skill.dart';
import '../model/repositories/my_skills_repository.dart';
import '../model/repositories/wanted_skills_repository.dart';
import '../services/current_user_service.dart';

// ============================================================
// CONTROLLER EXCEPTION
// ============================================================

class MySkillsControllerException
    implements Exception {
  final String message;

  const MySkillsControllerException(
      this.message,
      );

  @override
  String toString() => message;
}

// ============================================================
// MY SKILLS SNAPSHOT
// ============================================================

class MySkillsSnapshot {
  final List<ManagedSkill> offeredSkills;

  final List<ManagedWantedSkill> wantedSkills;

  const MySkillsSnapshot({
    required this.offeredSkills,
    required this.wantedSkills,
  });
}

// ============================================================
// MY SKILLS CONTROLLER
// ============================================================

class MySkillsController {
  MySkillsController({
    MySkillsRepository? mySkillsRepository,
    WantedSkillsRepository? wantedSkillsRepository,
    CurrentUserService? currentUserService,
  })  : _mySkillsRepository =
      mySkillsRepository ??
          MySkillsRepository.instance,
        _wantedSkillsRepository =
            wantedSkillsRepository ??
                WantedSkillsRepository.instance,
        _currentUserService =
            currentUserService ??
                CurrentUserService.instance;

  final MySkillsRepository _mySkillsRepository;

  final WantedSkillsRepository
  _wantedSkillsRepository;

  final CurrentUserService _currentUserService;

  // ============================================================
  // LOAD ALL MY SKILLS
  // ============================================================

  Future<MySkillsSnapshot>
  loadAllSkills() async {
    try {
      final String currentUserId =
          _currentUserService.userId;

      final List<ManagedSkill> offeredSkills =
      await _mySkillsRepository
          .getOfferedSkills(
        currentUserId,
      );

      final List<ManagedWantedSkill>
      wantedSkills =
      await _wantedSkillsRepository
          .getWantedSkills(
        currentUserId,
      );

      return MySkillsSnapshot(
        offeredSkills: offeredSkills,
        wantedSkills: wantedSkills,
      );
    } on CurrentUserServiceException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } on MySkillsRepositoryException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } on WantedSkillsRepositoryException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } catch (_) {
      throw const MySkillsControllerException(
        'Could not load your skills. Please try again.',
      );
    }
  }

  // ============================================================
  // OFFERED SKILL METADATA PERMISSION
  // ============================================================

  bool canEditMetadata(
      ManagedSkill managedSkill,
      ) {
    try {
      final String currentUserId =
          _currentUserService.userId;

      return managedSkill.metadataCanBeEditedBy(
        currentUserId,
      );
    } on CurrentUserServiceException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } catch (_) {
      throw const MySkillsControllerException(
        'Could not verify skill editing permissions.',
      );
    }
  }

  // ============================================================
  // WANTED SKILL METADATA PERMISSION
  // ============================================================

  bool canEditWantedMetadata(
      ManagedWantedSkill managedWantedSkill,
      ) {
    try {
      final String currentUserId =
          _currentUserService.userId;

      return managedWantedSkill
          .metadataCanBeEditedBy(
        currentUserId,
      );
    } on CurrentUserServiceException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } catch (_) {
      throw const MySkillsControllerException(
        'Could not verify learning interest editing permissions.',
      );
    }
  }

  // ============================================================
  // ADD OFFERED SKILL
  // ============================================================

  Future<void> addOfferedSkill({
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
  }) async {
    final String cleanTitle =
    title.trim();

    final String cleanCategory =
    category.trim();

    final String cleanDescription =
    description.trim();

    final String cleanLevel =
    level.trim();

    final String cleanAvailability =
    availability.trim();

    _validateAddOfferedSkillInput(
      title: cleanTitle,
      category: cleanCategory,
      description: cleanDescription,
      level: cleanLevel,
      availability: cleanAvailability,
    );

    try {
      final String currentUserId =
          _currentUserService.userId;

      await _mySkillsRepository
          .addOfferedSkill(
        userId: currentUserId,
        title: cleanTitle,
        category: cleanCategory,
        description: cleanDescription,
        level: cleanLevel,
        availability: cleanAvailability,
      );
    } on CurrentUserServiceException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } on MySkillsRepositoryException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } catch (_) {
      throw const MySkillsControllerException(
        'Could not add the skill. Please try again.',
      );
    }
  }

  // ============================================================
  // UPDATE OFFERED SKILL
  // ============================================================

  Future<void> updateOfferedSkill({
    required String userSkillId,
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
  }) async {
    final String cleanUserSkillId =
    userSkillId.trim();

    final String cleanTitle =
    title.trim();

    final String cleanCategory =
    category.trim();

    final String cleanDescription =
    description.trim();

    final String cleanLevel =
    level.trim();

    final String cleanAvailability =
    availability.trim();

    if (cleanUserSkillId.isEmpty) {
      throw const MySkillsControllerException(
        'Skill relationship could not be found.',
      );
    }

    _validateUpdateOfferedSkillInput(
      title: cleanTitle,
      category: cleanCategory,
      description: cleanDescription,
      level: cleanLevel,
      availability: cleanAvailability,
    );

    try {
      final String currentUserId =
          _currentUserService.userId;

      await _mySkillsRepository
          .updateOfferedSkill(
        userId: currentUserId,
        userSkillId: cleanUserSkillId,
        title: cleanTitle,
        category: cleanCategory,
        description: cleanDescription,
        level: cleanLevel,
        availability: cleanAvailability,
      );
    } on CurrentUserServiceException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } on MySkillsRepositoryException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } catch (_) {
      throw const MySkillsControllerException(
        'Could not update the skill. Please try again.',
      );
    }
  }

  // ============================================================
  // DELETE OFFERED SKILL
  // ============================================================

  Future<void> deleteOfferedSkill({
    required String userSkillId,
  }) async {
    final String cleanUserSkillId =
    userSkillId.trim();

    if (cleanUserSkillId.isEmpty) {
      throw const MySkillsControllerException(
        'Skill relationship could not be found.',
      );
    }

    try {
      final String currentUserId =
          _currentUserService.userId;

      await _mySkillsRepository
          .deleteOfferedSkill(
        userId: currentUserId,
        userSkillId: cleanUserSkillId,
      );
    } on CurrentUserServiceException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } on MySkillsRepositoryException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } catch (_) {
      throw const MySkillsControllerException(
        'Could not delete the skill. Please try again.',
      );
    }
  }

  // ============================================================
  // ADD WANTED SKILL
  // ============================================================

  Future<void> addWantedSkill({
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
  }) async {
    final String cleanTitle =
    title.trim();

    final String cleanCategory =
    category.trim();

    final String cleanDescription =
    description.trim();

    final String cleanLevel =
    level.trim();

    final String cleanAvailability =
    availability.trim();

    _validateAddWantedSkillInput(
      title: cleanTitle,
      category: cleanCategory,
      description: cleanDescription,
      level: cleanLevel,
      availability: cleanAvailability,
    );

    try {
      final String currentUserId =
          _currentUserService.userId;

      await _wantedSkillsRepository
          .addWantedSkill(
        userId: currentUserId,
        title: cleanTitle,
        category: cleanCategory,
        description: cleanDescription,
        level: cleanLevel,
        availability: cleanAvailability,
      );
    } on CurrentUserServiceException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } on WantedSkillsRepositoryException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } catch (_) {
      throw const MySkillsControllerException(
        'Could not add the learning interest. Please try again.',
      );
    }
  }

  // ============================================================
  // UPDATE WANTED SKILL
  // ============================================================

  Future<void> updateWantedSkill({
    required String userSkillId,
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
  }) async {
    final String cleanUserSkillId =
    userSkillId.trim();

    final String cleanTitle =
    title.trim();

    final String cleanCategory =
    category.trim();

    final String cleanDescription =
    description.trim();

    final String cleanLevel =
    level.trim();

    final String cleanAvailability =
    availability.trim();

    if (cleanUserSkillId.isEmpty) {
      throw const MySkillsControllerException(
        'Learning interest relationship could not be found.',
      );
    }

    _validateUpdateWantedSkillInput(
      title: cleanTitle,
      category: cleanCategory,
      description: cleanDescription,
      level: cleanLevel,
      availability: cleanAvailability,
    );

    try {
      final String currentUserId =
          _currentUserService.userId;

      await _wantedSkillsRepository
          .updateWantedSkill(
        userId: currentUserId,
        userSkillId: cleanUserSkillId,
        title: cleanTitle,
        category: cleanCategory,
        description: cleanDescription,
        level: cleanLevel,
        availability: cleanAvailability,
      );
    } on CurrentUserServiceException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } on WantedSkillsRepositoryException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } catch (_) {
      throw const MySkillsControllerException(
        'Could not update the learning interest. Please try again.',
      );
    }
  }

  // ============================================================
  // DELETE WANTED SKILL
  // ============================================================

  Future<void> deleteWantedSkill({
    required String userSkillId,
  }) async {
    final String cleanUserSkillId =
    userSkillId.trim();

    if (cleanUserSkillId.isEmpty) {
      throw const MySkillsControllerException(
        'Learning interest relationship could not be found.',
      );
    }

    try {
      final String currentUserId =
          _currentUserService.userId;

      await _wantedSkillsRepository
          .deleteWantedSkill(
        userId: currentUserId,
        userSkillId: cleanUserSkillId,
      );
    } on CurrentUserServiceException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } on WantedSkillsRepositoryException catch (
    error
    ) {
      throw MySkillsControllerException(
        error.message,
      );
    } catch (_) {
      throw const MySkillsControllerException(
        'Could not remove the learning interest. Please try again.',
      );
    }
  }

  // ============================================================
  // ADD OFFERED SKILL VALIDATION
  // ============================================================

  void _validateAddOfferedSkillInput({
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
  }) {
    if (title.isEmpty) {
      throw const MySkillsControllerException(
        'Please enter a skill name.',
      );
    }

    if (title.length > 80) {
      throw const MySkillsControllerException(
        'Skill name must be 80 characters or less.',
      );
    }

    if (category.isEmpty) {
      throw const MySkillsControllerException(
        'Please select a category.',
      );
    }

    if (description.isEmpty) {
      throw const MySkillsControllerException(
        'Please add a short description.',
      );
    }

    if (description.length > 200) {
      throw const MySkillsControllerException(
        'Description must be 200 characters or less.',
      );
    }

    if (level.isEmpty) {
      throw const MySkillsControllerException(
        'Please select an experience level.',
      );
    }

    if (availability.isEmpty) {
      throw const MySkillsControllerException(
        'Please select your availability.',
      );
    }
  }

  // ============================================================
  // UPDATE OFFERED SKILL VALIDATION
  // ============================================================

  void _validateUpdateOfferedSkillInput({
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
  }) {
    if (title.isEmpty) {
      throw const MySkillsControllerException(
        'Skill name is required.',
      );
    }

    if (title.length > 80) {
      throw const MySkillsControllerException(
        'Skill name must be 80 characters or less.',
      );
    }

    if (category.isEmpty) {
      throw const MySkillsControllerException(
        'Category is required.',
      );
    }

    if (description.isEmpty) {
      throw const MySkillsControllerException(
        'Description is required.',
      );
    }

    if (description.length > 200) {
      throw const MySkillsControllerException(
        'Description must be 200 characters or less.',
      );
    }

    if (level.isEmpty) {
      throw const MySkillsControllerException(
        'Experience level is required.',
      );
    }

    if (availability.isEmpty) {
      throw const MySkillsControllerException(
        'Availability is required.',
      );
    }
  }

  // ============================================================
  // ADD WANTED SKILL VALIDATION
  // ============================================================

  void _validateAddWantedSkillInput({
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
  }) {
    if (title.isEmpty) {
      throw const MySkillsControllerException(
        'Skill name is required.',
      );
    }

    if (title.length > 80) {
      throw const MySkillsControllerException(
        'Skill name must be 80 characters or less.',
      );
    }

    if (category.isEmpty) {
      throw const MySkillsControllerException(
        'Please select a category.',
      );
    }

    if (description.isEmpty) {
      throw const MySkillsControllerException(
        'Please describe what you want to learn.',
      );
    }

    if (description.length > 200) {
      throw const MySkillsControllerException(
        'Description must be 200 characters or less.',
      );
    }

    if (level.isEmpty) {
      throw const MySkillsControllerException(
        'Please select your current level.',
      );
    }

    if (availability.isEmpty) {
      throw const MySkillsControllerException(
        'Please select your availability.',
      );
    }
  }

  // ============================================================
  // UPDATE WANTED SKILL VALIDATION
  // ============================================================

  void _validateUpdateWantedSkillInput({
    required String title,
    required String category,
    required String description,
    required String level,
    required String availability,
  }) {
    if (title.isEmpty) {
      throw const MySkillsControllerException(
        'Skill name is required.',
      );
    }

    if (title.length > 80) {
      throw const MySkillsControllerException(
        'Skill name must be 80 characters or less.',
      );
    }

    if (category.isEmpty) {
      throw const MySkillsControllerException(
        'Category is required.',
      );
    }

    if (description.isEmpty) {
      throw const MySkillsControllerException(
        'Description is required.',
      );
    }

    if (description.length > 200) {
      throw const MySkillsControllerException(
        'Description must be 200 characters or less.',
      );
    }

    if (level.isEmpty) {
      throw const MySkillsControllerException(
        'Current level is required.',
      );
    }

    if (availability.isEmpty) {
      throw const MySkillsControllerException(
        'Availability is required.',
      );
    }
  }
}