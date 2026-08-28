enum UserSkillType {
  offered,
  wanted,
}

class UserSkill {
  final String id;

  final String userId;
  final String skillId;

  final UserSkillType type;

  final String level;

  final String availability;

  const UserSkill({
    required this.id,
    required this.userId,
    required this.skillId,
    required this.type,
    required this.level,
    required this.availability,
  });
}