import '../model/ai_match_analysis.dart';
import '../model/repositories/ai_match_repository.dart';
import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/skill_match.dart';
import '../model/user.dart';
import '../model/user_skill.dart';
import 'current_user_service.dart';

class AiMatchServiceException implements Exception {
  final String message;

  const AiMatchServiceException(this.message);

  @override
  String toString() => message;
}

class AiMatchService {
  AiMatchService({
    AiMatchRepository? aiMatchRepository,
    ExploreRepository? exploreRepository,
    CurrentUserService? currentUserService,
  }) : _aiMatchRepository = aiMatchRepository ?? AiMatchRepository.instance,
       _exploreRepository = exploreRepository ?? ExploreRepository.instance,
       _currentUserService = currentUserService ?? CurrentUserService.instance;

  static final AiMatchService instance = AiMatchService();

  final AiMatchRepository _aiMatchRepository;
  final ExploreRepository _exploreRepository;
  final CurrentUserService _currentUserService;

  Future<AiMatchAnalysis> generateAnalysisForCandidate(
    String candidateUid,
  ) {
    return _currentUserService.runForSession<AiMatchAnalysis>(() async {
      final String currentUid = _currentUserService.requireUserId();

      final String cleanCandidateUid = candidateUid.trim();
      if (cleanCandidateUid.isEmpty) {
        throw const AiMatchServiceException('candidateUid is required.');
      }

      final List<SkillMatch> shortlist = _exploreRepository
          .getSmartMatchesForUser(currentUid);

      SkillMatch? match;
      for (final SkillMatch candidateMatch in shortlist) {
        if (candidateMatch.user.id == cleanCandidateUid) {
          match = candidateMatch;
          break;
        }
      }

      if (match == null) {
        throw const AiMatchServiceException(
          'This candidate is not on your current match shortlist.',
        );
      }

      _currentUserService.requireActiveOperation();

      final User? currentUser = _exploreRepository.findUserById(currentUid);
      if (currentUser == null) {
        throw const AiMatchServiceException(
          'Your profile could not be found.',
        );
      }

      final AiMatchParticipantProfile currentUserProfile = _buildProfile(
        currentUser,
        currentUid,
      );
      final AiMatchParticipantProfile candidateProfile = _buildProfile(
        match.user,
        cleanCandidateUid,
      );

      _currentUserService.requireActiveOperation();

      final AiMatchAnalysisRequest request = AiMatchAnalysisRequest(
        currentUser: currentUserProfile,
        candidate: candidateProfile,
        isTwoWayMatch: match.isTwoWayMatch,
        sameCity: match.sameCity,
        modeCompatible: match.modeCompatible,
        languageCompatible: match.languageCompatible,
        availabilityCompatible: match.availabilityCompatible,
      );

      _currentUserService.requireActiveOperation();

      final AiMatchAnalysis analysis;
      try {
        analysis = await _aiMatchRepository.generateMatchAnalysis(
          candidateUid: cleanCandidateUid,
          request: request,
        );
      } on AiMatchRepositoryException catch (error) {
        throw AiMatchServiceException(error.message);
      }

      _currentUserService.requireActiveOperation();

      return analysis;
    });
  }

  AiMatchParticipantProfile _buildProfile(User user, String uid) {
    return AiMatchParticipantProfile(
      offeredSkillTitles: _resolveSkillTitles(
        _exploreRepository.getOfferedSkillsForUser(uid),
      ),
      wantedSkillTitles: _resolveSkillTitles(
        _exploreRepository.getWantedSkillsForUser(uid),
      ),
      preferredMode: user.preferredMode,
      teachingStyle: user.teachingStyle,
      language: user.language,
      availability: user.availability,
    );
  }

  List<String> _resolveSkillTitles(List<UserSkill> relationships) {
    final List<String> titles = <String>[];
    for (final UserSkill relationship in relationships) {
      final Skill? skill = _exploreRepository.findSkillById(
        relationship.skillId,
      );
      if (skill == null) {
        continue;
      }
      titles.add(skill.title);
    }
    return titles;
  }
}
