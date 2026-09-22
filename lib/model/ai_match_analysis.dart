class AiMatchAnalysisFormatException implements Exception {
  final String message;

  /// True when this validation failure is plausibly transient model-output
  /// content/count variance (e.g. a list came back the wrong length, or a
  /// string exceeded a length bound) — a fresh generation attempt may
  /// produce a compliant result. False for structural/type/presence
  /// failures (wrong type, missing field, empty string/item), which are
  /// deterministic contract violations a retry is unlikely to fix.
  final bool isRetryable;

  const AiMatchAnalysisFormatException(
    this.message, {
    required this.isRetryable,
  });

  @override
  String toString() => message;
}

/// Structured, on-device representation of a Gemini-generated skill-match
/// analysis for a single candidate.
class AiMatchAnalysis {
  static const int _maxCompatibilitySummaryLength = 600;
  static const int _minStrengths = 1;
  static const int _maxStrengths = 3;
  static const int _maxPotentialChallenges = 2;

  /// Local attachment only. Never sent to or received from the model as
  /// part of the prompt or response payload — it is stitched on after the
  /// model output has been parsed and validated.
  final String candidateUid;

  final String compatibilitySummary;
  final List<String> strengths;
  final List<String> potentialChallenges;
  final String suggestedFirstSession;
  final String confidenceNote;

  const AiMatchAnalysis({
    required this.candidateUid,
    required this.compatibilitySummary,
    required this.strengths,
    required this.potentialChallenges,
    required this.suggestedFirstSession,
    required this.confidenceNote,
  });

  /// Parses and validates a decoded Gemini JSON response body.
  ///
  /// [candidateUid] is supplied by the caller from local state — it must
  /// never be read from [json], since the model is never given it.
  ///
  /// Throws [AiMatchAnalysisFormatException] on any structural or content
  /// violation. Malformed output is never coerced, truncated, or defaulted.
  factory AiMatchAnalysis.fromJson(
    Map<String, Object?> json, {
    required String candidateUid,
  }) {
    final String cleanCandidateUid = candidateUid.trim();
    if (cleanCandidateUid.isEmpty) {
      throw const AiMatchAnalysisFormatException(
        'candidateUid is required.',
        isRetryable: false,
      );
    }

    final String compatibilitySummary = _requireString(
      json,
      'compatibilitySummary',
    );
    if (compatibilitySummary.length > _maxCompatibilitySummaryLength) {
      throw AiMatchAnalysisFormatException(
        'compatibilitySummary must be $_maxCompatibilitySummaryLength '
        'characters or fewer.',
        isRetryable: true,
      );
    }

    final List<String> strengths = _requireStringList(
      json,
      'strengths',
      emptyListIsRetryable: true,
    );
    if (strengths.length < _minStrengths || strengths.length > _maxStrengths) {
      throw AiMatchAnalysisFormatException(
        'strengths must contain between $_minStrengths and '
        '$_maxStrengths items.',
        isRetryable: true,
      );
    }

    final List<String> potentialChallenges = _requireStringList(
      json,
      'potentialChallenges',
      allowEmptyList: true,
      emptyListIsRetryable: false,
    );
    if (potentialChallenges.length > _maxPotentialChallenges) {
      throw AiMatchAnalysisFormatException(
        'potentialChallenges must contain at most '
        '$_maxPotentialChallenges items.',
        isRetryable: true,
      );
    }

    final String suggestedFirstSession = _requireString(
      json,
      'suggestedFirstSession',
    );

    final String confidenceNote = _requireString(
      json,
      'confidenceNote',
    );

    return AiMatchAnalysis(
      candidateUid: cleanCandidateUid,
      compatibilitySummary: compatibilitySummary,
      strengths: List<String>.unmodifiable(strengths),
      potentialChallenges: List<String>.unmodifiable(potentialChallenges),
      suggestedFirstSession: suggestedFirstSession,
      confidenceNote: confidenceNote,
    );
  }

  static String _requireString(Map<String, Object?> json, String key) {
    final Object? value = json[key];
    if (value is! String) {
      throw AiMatchAnalysisFormatException(
        '$key is invalid.',
        isRetryable: false,
      );
    }

    final String cleaned = value.trim();
    if (cleaned.isEmpty) {
      throw AiMatchAnalysisFormatException(
        '$key is required.',
        isRetryable: false,
      );
    }

    return cleaned;
  }

  static List<String> _requireStringList(
    Map<String, Object?> json,
    String key, {
    bool allowEmptyList = false,
    bool emptyListIsRetryable = false,
  }) {
    final Object? value = json[key];
    if (value is! List) {
      throw AiMatchAnalysisFormatException(
        '$key is invalid.',
        isRetryable: false,
      );
    }

    final List<String> items = <String>[];
    for (final Object? entry in value) {
      if (entry is! String) {
        throw AiMatchAnalysisFormatException(
          '$key contains an invalid item.',
          isRetryable: false,
        );
      }

      final String cleaned = entry.trim();
      if (cleaned.isEmpty) {
        throw AiMatchAnalysisFormatException(
          '$key contains an empty item.',
          isRetryable: false,
        );
      }

      items.add(cleaned);
    }

    if (!allowEmptyList && items.isEmpty) {
      throw AiMatchAnalysisFormatException(
        '$key is required.',
        isRetryable: emptyListIsRetryable,
      );
    }

    return items;
  }
}
