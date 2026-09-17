import 'skill.dart';
import 'user_skill.dart';

// ============================================================
// MANAGED OFFERED SKILL
// ============================================================

class ManagedSkill {
  final Skill skill;
  final UserSkill userSkill;
  final String? ownerUserId;

  const ManagedSkill({
    required this.skill,
    required this.userSkill,
    required this.ownerUserId,
  });

  bool metadataCanBeEditedBy(
      String userId,
      ) {
    return ownerUserId != null &&
        ownerUserId == userId.trim();
  }
}

// ============================================================
// MANAGED WANTED SKILL
// ============================================================

class ManagedWantedSkill {
  final Skill skill;
  final UserSkill userSkill;
  final String? ownerUserId;

  const ManagedWantedSkill({
    required this.skill,
    required this.userSkill,
    required this.ownerUserId,
  });

  bool metadataCanBeEditedBy(
      String userId,
      ) {
    return ownerUserId != null &&
        ownerUserId == userId.trim();
  }
}