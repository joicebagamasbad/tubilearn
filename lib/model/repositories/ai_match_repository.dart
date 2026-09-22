import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../ai_match_analysis.dart';

/// Gemini model backing AI match analysis.
///
/// Verified current/stable on the Gemini Developer API backend (does not
/// require the Blaze billing plan) via the Firebase AI Logic "Supported
/// models" documentation as of 2026-09-22:
/// https://firebase.google.com/docs/ai-logic/models
const String _kAiMatchAnalysisModel = 'gemini-3.8-flash';

class AiMatchRepositoryException implements Exception {
  final String message;
  final Object? cause;

  const AiMatchRepositoryException(this.message, {this.cause});

  @override
  String toString() => message;
}

/// A single participant's skill-exchange profile, stripped of every field
/// that could identify them or expose local-only reputation data.
///
/// Deliberately excludes: Firebase UID, email, exact city, bio,
/// relationship/skill/manifest document IDs, member-since, email
/// verification, and any rating/review/completed-swap/response-rate field.
class AiMatchParticipantProfile {
  final List<String> offeredSkillTitles;
  final List<String> wantedSkillTitles;
  final String preferredMode;
  final String teachingStyle;
  final String language;
  final String availability;

  const AiMatchParticipantProfile({
    required this.offeredSkillTitles,
    required this.wantedSkillTitles,
    required this.preferredMode,
    required this.teachingStyle,
    required this.language,
    required this.availability,
  });

  Map<String, Object?> toPromptJson() => <String, Object?>{
        'offeredSkills': offeredSkillTitles,
        'wantedSkills': wantedSkillTitles,
        'preferredMode': preferredMode,
        'teachingStyle': teachingStyle,
        'language': language,
        'availability': availability,
      };
}

/// Sanitized request payload for an AI match analysis. This is the only
/// shape that may reach the model — see [AiMatchParticipantProfile] for
/// what has already been stripped out.
class AiMatchAnalysisRequest {
  final AiMatchParticipantProfile currentUser;
  final AiMatchParticipantProfile candidate;
  final bool isTwoWayMatch;
  final bool sameCity;
  final bool modeCompatible;
  final bool languageCompatible;
  final bool availabilityCompatible;

  const AiMatchAnalysisRequest({
    required this.currentUser,
    required this.candidate,
    required this.isTwoWayMatch,
    required this.sameCity,
    required this.modeCompatible,
    required this.languageCompatible,
    required this.availabilityCompatible,
  });

  Map<String, Object?> toPromptJson() => <String, Object?>{
        'currentUser': currentUser.toPromptJson(),
        'candidate': candidate.toPromptJson(),
        'isTwoWayMatch': isTwoWayMatch,
        'sameCity': sameCity,
        'modeCompatible': modeCompatible,
        'languageCompatible': languageCompatible,
        'availabilityCompatible': availabilityCompatible,
      };
}

/// Thin boundary around Firebase AI Logic for generating structured
/// [AiMatchAnalysis] output from a sanitized [AiMatchAnalysisRequest].
///
/// Backend: this repository is wired to the GEMINI DEVELOPER API backend
/// (`FirebaseAI.googleAI()`), NOT the Vertex AI / Agent Platform Gemini API
/// backend (`FirebaseAI.vertexAI()`). Only the Gemini Developer API backend
/// runs on the no-cost Spark plan — switching this to `FirebaseAI.vertexAI()`
/// would silently require the Blaze billing plan, which is forbidden by
/// project constraints. Keep this call, and only this call, as the model
/// source.
class AiMatchRepository {
  AiMatchRepository._();

  static final AiMatchRepository instance = AiMatchRepository._();

  factory AiMatchRepository() => instance;

  static final Schema _responseSchema = Schema.object(
    properties: <String, Schema>{
      'compatibilitySummary': Schema.string(),
      'strengths': Schema.array(items: Schema.string(), maxItems: 3),
      'potentialChallenges': Schema.array(items: Schema.string(), maxItems: 2),
      'suggestedFirstSession': Schema.string(),
      'confidenceNote': Schema.string(),
    },
  );

  GenerativeModel? _model;

  // GEMINI DEVELOPER API BACKEND — see class doc comment. Must stay
  // `FirebaseAI.googleAI()`, never `FirebaseAI.vertexAI()`.
  GenerativeModel _requireModel() {
    return _model ??= FirebaseAI.googleAI().generativeModel(
      model: _kAiMatchAnalysisModel,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _responseSchema,
      ),
    );
  }

  static const int _maxAttempts = 3;

  /// Generates an [AiMatchAnalysis] for [candidateUid] from a sanitized
  /// [request]. Not invoked anywhere yet in this batch — no live Gemini
  /// call is made until a later batch wires a caller to this method.
  Future<AiMatchAnalysis> generateMatchAnalysis({
    required String candidateUid,
    required AiMatchAnalysisRequest request,
  }) async {
    final String cleanCandidateUid = candidateUid.trim();
    if (cleanCandidateUid.isEmpty) {
      throw const AiMatchRepositoryException('candidateUid is required.');
    }

    final GenerativeModel model = _requireModel();
    final String prompt = jsonEncode(request.toPromptJson());

    // Only count/content-bound validation failures are retried (a string
    // over its length bound, or a list outside its allowed item count —
    // including an empty `strengths` list, since Firebase AI Logic's
    // schema cannot enforce minItems and so cannot prevent the model from
    // returning zero items). Structural/type/presence failures (wrong
    // type, missing field, an empty individual string/item) and any
    // generateContent()/JSON-decode-level failure fail immediately,
    // without retry, exactly as before this loop was introduced.
    for (int attempt = 1; attempt <= _maxAttempts; attempt++) {
      final GenerateContentResponse response;
      try {
        response = await model.generateContent(<Content>[
          Content.text(prompt),
        ]);
      } catch (error) {
        throw AiMatchRepositoryException(
          'Could not generate a match analysis. Please try again.',
          cause: error,
        );
      }

      final String? text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw const AiMatchRepositoryException(
          'The match analysis response was empty.',
        );
      }

      final Object? decoded;
      try {
        decoded = jsonDecode(text);
      } on FormatException catch (error) {
        throw AiMatchRepositoryException(
          'The match analysis response was not valid JSON.',
          cause: error,
        );
      }

      if (decoded is! Map<String, Object?>) {
        throw const AiMatchRepositoryException(
          'The match analysis response had an unexpected shape.',
        );
      }

      try {
        return AiMatchAnalysis.fromJson(
          decoded,
          candidateUid: cleanCandidateUid,
        );
      } on AiMatchAnalysisFormatException catch (error) {
        if (!error.isRetryable) {
          throw AiMatchRepositoryException(
            'The match analysis response failed validation: $error',
            cause: error,
          );
        }

        if (attempt >= _maxAttempts) {
          throw AiMatchRepositoryException(
            'The match analysis response failed validation after '
            'multiple attempts: $error',
            cause: error,
          );
        }
        // Retryable and attempts remain: fall through to the next
        // iteration for a fresh generateContent() call.
      }
    }

    // Unreachable: the loop above always either returns or throws.
    throw const AiMatchRepositoryException(
      'The match analysis could not be generated.',
    );
  }
}
