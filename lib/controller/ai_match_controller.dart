import '../model/ai_match_analysis.dart';
import '../services/ai_match_service.dart';

class AiMatchControllerException implements Exception {
  final String message;

  const AiMatchControllerException(
      this.message,
      );

  @override
  String toString() => message;
}

class AiMatchController {
  AiMatchController({
    AiMatchService? aiMatchService,
  })  : _aiMatchService =
      aiMatchService ??
          AiMatchService.instance;

  final AiMatchService _aiMatchService;

  // ============================================================
  // ANALYZE CANDIDATE
  // ============================================================

  Future<AiMatchAnalysis> analyzeCandidate(
      String candidateUid,
      ) async {
    try {
      return await _aiMatchService.generateAnalysisForCandidate(
        candidateUid,
      );
    } on AiMatchServiceException catch (error) {
      throw AiMatchControllerException(
        error.message,
      );
    } catch (_) {
      throw const AiMatchControllerException(
        'Could not analyze this match. Please try again.',
      );
    }
  }
}
