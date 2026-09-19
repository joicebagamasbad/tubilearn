import 'dart:async';

class ActiveUserSession {
  final String uid;
  final int generation;

  const ActiveUserSession(this.uid, this.generation);
}

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

  String? _activeUid;
  int _generation = 0;
  final Object _operationKey = Object();

  String get userId =>
      requireUserId();

  bool get usesLocalPrototypeSession => false;

  // Firebase authentication is active; application data remains local.
  bool get hasAuthenticatedBackendSession => _activeUid != null;

  void configureAuthenticatedUid(String uid) {
    final String cleanUid = uid.trim();
    if (cleanUid.isEmpty || cleanUid == 'user_joice_local') {
      throw const CurrentUserServiceException(
        'A valid authenticated user ID is required.',
      );
    }
    _activeUid = cleanUid;
    _generation++;
  }

  void clearSession() {
    _activeUid = null;
    _generation++;
  }

  ActiveUserSession captureSession() =>
      ActiveUserSession(requireUserId(), _generation);

  void requireSameSession(ActiveUserSession session) {
    if (_activeUid != session.uid || _generation != session.generation) {
      throw const CurrentUserServiceException(
        'The authenticated user changed during this operation.',
      );
    }
  }

  void requireActiveOperation() {
    final Object? session = Zone.current[_operationKey];
    if (session is ActiveUserSession) requireSameSession(session);
  }

  Future<T> runForSession<T>(Future<T> Function() operation) {
    final ActiveUserSession session = captureSession();
    return runZoned<Future<T>>(() async {
      requireSameSession(session);
      final T result = await operation();
      requireSameSession(session);
      return result;
    }, zoneValues: <Object, Object>{_operationKey: session});
  }

  // ============================================================
  // CURRENT USER VALIDATION
  // ============================================================

  String requireUserId() {
    requireActiveOperation();
    final String? cleanUserId = _activeUid;

    if (cleanUserId == null) {
      throw const CurrentUserServiceException(
        'No authenticated user session is active.',
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

    return _activeUid != null && cleanCandidate == _activeUid;
  }

  void requireCurrentUser(
      String candidateUserId, {
        String message =
        'You are not allowed to perform this action.',
      }) {
    requireActiveOperation();
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
