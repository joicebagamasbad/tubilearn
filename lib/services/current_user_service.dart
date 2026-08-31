class CurrentUserServiceException implements Exception {
  final String message;

  const CurrentUserServiceException(
      this.message,
      );

  @override
  String toString() => message;
}

class CurrentUserService {
  CurrentUserService._();

  static final CurrentUserService instance =
  CurrentUserService._();

  // ============================================================
  // LOCAL DEVELOPMENT SESSION
  //
  // IMPORTANT:
  // This is NOT authentication.
  //
  // TubiLearn currently runs as a single local prototype user.
  // Real authentication must later come from a trusted backend
  // session/token and server-enforced authorization.
  // ============================================================

  static const String _localUserId =
      'user_joice_local';

  static const bool _usesLocalPrototypeSession =
  true;

  String get userId =>
      requireUserId();

  bool get usesLocalPrototypeSession =>
      _usesLocalPrototypeSession;

  bool get hasAuthenticatedBackendSession =>
      false;

  // ============================================================
  // CURRENT USER VALIDATION
  // ============================================================

  String requireUserId() {
    final String cleanUserId =
    _localUserId.trim();

    if (cleanUserId.isEmpty) {
      throw const CurrentUserServiceException(
        'No active local user is configured.',
      );
    }

    return cleanUserId;
  }

  bool isCurrentUser(
      String? candidateUserId,
      ) {
    if (candidateUserId == null) {
      return false;
    }

    final String cleanCandidate =
    candidateUserId.trim();

    if (cleanCandidate.isEmpty) {
      return false;
    }

    return cleanCandidate ==
        requireUserId();
  }

  void requireCurrentUser(
      String candidateUserId, {
        String message =
        'You are not allowed to perform this action.',
      }) {
    final String cleanCandidate =
    candidateUserId.trim();

    if (cleanCandidate.isEmpty ||
        !isCurrentUser(
          cleanCandidate,
        )) {
      throw CurrentUserServiceException(
        message,
      );
    }
  }
}