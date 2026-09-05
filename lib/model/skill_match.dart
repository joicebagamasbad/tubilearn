import 'skill.dart';
import 'user.dart';

class SkillMatch {
  final User user;

  final int score;

  final Skill? skillToLearn;
  final Skill? skillToTeach;

  final bool isTwoWayMatch;

  final bool sameCity;
  final bool modeCompatible;
  final bool languageCompatible;
  final bool availabilityCompatible;

  final List<String> reasons;

  const SkillMatch({
    required this.user,
    required this.score,
    required this.skillToLearn,
    required this.skillToTeach,
    required this.isTwoWayMatch,
    required this.sameCity,
    required this.modeCompatible,
    required this.languageCompatible,
    required this.availabilityCompatible,
    required this.reasons,
  });

  bool get hasLearningMatch =>
      skillToLearn != null;

  bool get hasTeachingMatch =>
      skillToTeach != null;

  String get headline {
    if (isTwoWayMatch &&
        skillToLearn != null &&
        skillToTeach != null) {
      return '${skillToLearn!.title} ↔ ${skillToTeach!.title}';
    }

    if (skillToLearn != null) {
      return '${skillToLearn!.title} • Learning match';
    }

    if (skillToTeach != null) {
      return '${skillToTeach!.title} • Teaching match';
    }

    return 'Potential skill match';
  }

  String get explanation {
    if (isTwoWayMatch &&
        skillToLearn != null &&
        skillToTeach != null) {
      return '${user.name} can help you learn '
          '${skillToLearn!.title}, while you can help with '
          '${skillToTeach!.title}.';
    }

    if (skillToLearn != null) {
      return '${user.name} offers ${skillToLearn!.title}, '
          'which matches something you want to learn.';
    }

    if (skillToTeach != null) {
      return '${user.name} wants to learn ${skillToTeach!.title}, '
          'which matches a skill you offer.';
    }

    return '${user.name} may be a useful skill-exchange partner.';
  }
}