import '../model/auth_session.dart';
import '../services/auth_service.dart';

class AuthControllerException
    implements Exception {
  final String message;

  const AuthControllerException(
    this.message,
  );

  @override
  String toString() => message;
}

class AuthController {
  final AuthService _authService;

  AuthController({
    AuthService? authService,
  }) : _authService =
            authService ??
            AuthService.instance;

  // ============================================================
  // AUTH STATE
  // ============================================================

  Stream<AuthSession?> get authStateChanges =>
      _authService.authStateChanges;

  AuthSession? get currentSession =>
      _authService.currentSession;

  bool get isSignedIn =>
      _authService.isSignedIn;

  String? get currentUserId =>
      _authService.currentUserId;

  // ============================================================
  // SIGN UP
  // ============================================================

  Future<AuthSession> signUp({
    required String displayName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final String cleanName =
        displayName.trim();

    final String cleanEmail =
        email.trim();

    _validateDisplayName(
      cleanName,
    );

    _validateEmail(
      cleanEmail,
    );

    _validatePassword(
      password,
    );

    if (password !=
        confirmPassword) {
      throw const AuthControllerException(
        'Passwords do not match.',
      );
    }

    try {
      final AuthSession session = await _authService.signUpWithEmail(
        displayName: cleanName,
        email: cleanEmail,
        password: password,
      );

      try {
        await _authService
            .sendEmailVerification();
      } catch (_) {
        // Account creation remains successful even if
        // the verification email cannot be sent immediately.
      }

      return session;
    } on AuthServiceException catch (error) {
      throw AuthControllerException(
        _messageForCode(
          error.code,
        ),
      );
    }
  }

  // ============================================================
  // EMAIL LOGIN
  // ============================================================

  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final String cleanEmail =
        email.trim();

    _validateEmail(
      cleanEmail,
    );

    if (password.isEmpty) {
      throw const AuthControllerException(
        'Enter your password.',
      );
    }

    try {
      return await _authService.signInWithEmail(
        email: cleanEmail,
        password: password,
      );
    } on AuthServiceException catch (error) {
      throw AuthControllerException(
        _messageForCode(
          error.code,
        ),
      );
    }
  }

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<AuthSession> signInWithGoogle() async {
    try {
      return await _authService.signInWithGoogle();
    } on AuthServiceException catch (error) {
      throw AuthControllerException(
        _messageForCode(
          error.code,
        ),
      );
    }
  }

  // ============================================================
  // PASSWORD RESET
  // ============================================================

  Future<void> sendPasswordReset({
    required String email,
  }) async {
    final String cleanEmail =
        email.trim();

    _validateEmail(
      cleanEmail,
    );

    try {
      await _authService
          .sendPasswordResetEmail(
        email: cleanEmail,
      );
    } on AuthServiceException catch (error) {
      throw AuthControllerException(
        _messageForPasswordResetCode(
          error.code,
        ),
      );
    }
  }

  // ============================================================
  // EMAIL VERIFICATION
  // ============================================================

  Future<void> sendVerificationEmail() async {
    try {
      await _authService
          .sendEmailVerification();
    } on AuthServiceException catch (error) {
      throw AuthControllerException(
        _messageForCode(
          error.code,
        ),
      );
    }
  }

  Future<void> refreshCurrentUser() async {
    try {
      await _authService
          .reloadCurrentUser();
    } on AuthServiceException catch (error) {
      throw AuthControllerException(
        _messageForCode(
          error.code,
        ),
      );
    }
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } on AuthServiceException catch (error) {
      throw AuthControllerException(
        _messageForCode(
          error.code,
        ),
      );
    }
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  void _validateDisplayName(
    String displayName,
  ) {
    if (displayName.isEmpty) {
      throw const AuthControllerException(
        'Enter your name.',
      );
    }

    if (displayName.length < 2) {
      throw const AuthControllerException(
        'Name must contain at least 2 characters.',
      );
    }
  }

  void _validateEmail(
    String email,
  ) {
    if (email.isEmpty) {
      throw const AuthControllerException(
        'Enter your email address.',
      );
    }

    final RegExp emailPattern =
        RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailPattern.hasMatch(
      email,
    )) {
      throw const AuthControllerException(
        'Enter a valid email address.',
      );
    }
  }

  void _validatePassword(
    String password,
  ) {
    if (password.isEmpty) {
      throw const AuthControllerException(
        'Enter a password.',
      );
    }

    if (password.length < 6) {
      throw const AuthControllerException(
        'Password must contain at least 6 characters.',
      );
    }
  }

  // ============================================================
  // USER-FACING ERROR MESSAGES
  // ============================================================

  String _messageForPasswordResetCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
        return 'No account was found for this email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many reset requests. Please try again later.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Password reset is currently unavailable.';
      default:
        return 'Could not send the reset link. Please try again.';
    }
  }

  String _messageForCode(
    String code,
  ) {
    switch (code) {
      case 'invalid-email':
        return 'Enter a valid email address.';

      case 'email-already-in-use':
        return 'An account already exists for this email.';

      case 'weak-password':
        return 'Choose a stronger password.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Check your internet connection and try again.';

      case 'operation-not-allowed':
        return 'This sign-in method is currently unavailable.';

      case 'google-sign-in-canceled':
        return 'Google sign-in was canceled.';

      case 'google-sign-in-not-supported':
        return 'Google sign-in is not supported on this device.';

      case 'google-missing-id-token':
        return 'Google sign-in could not verify your account.';

      case 'google-sign-in-failed':
        return 'Google sign-in failed. Please try again.';

      case 'google-initialization-failed':
        return 'Google sign-in could not start. Try again or use email sign-in.';

      case 'no-current-user':
        return 'You are not currently signed in.';

      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
