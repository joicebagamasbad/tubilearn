import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../model/auth_session.dart';

class AuthServiceException implements Exception {
  final String code;
  final String message;

  const AuthServiceException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();

  static final AuthService instance =
      AuthService._();

  final FirebaseAuth _firebaseAuth =
      FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  Future<void>? _googleInitialization;

  // ============================================================
  // AUTH STATE
  // ============================================================

  Stream<AuthSession?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map(
        (User? user) => user == null ? null : _sessionFor(user),
      );

  AuthSession? get currentSession {
    final User? user = _firebaseAuth.currentUser;
    return user == null ? null : _sessionFor(user);
  }

  bool get isSignedIn =>
      currentSession != null;

  String? get currentUserId =>
      currentSession?.uid;

  // ============================================================
  // EMAIL / PASSWORD SIGN UP
  // ============================================================

  Future<AuthSession> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential =
          await _firebaseAuth
              .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user =
          credential.user;

      if (user != null) {
        try {
          await user.updateDisplayName(
            displayName.trim(),
          );
        } catch (_) {
          // The account already exists; a profile update must not fail signup.
        }
      }

      if (user == null) {
        throw const AuthServiceException(
          code: 'no-current-user',
          message: 'Account was created, but its session could not be loaded.',
        );
      }

      return _sessionFor(user);
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        code: error.code,
        message:
            error.message ??
            'Could not create account.',
      );
    }
  }

  // ============================================================
  // EMAIL / PASSWORD LOGIN
  // ============================================================

  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _sessionFromCredential(credential);
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        code: error.code,
        message:
            error.message ??
            'Could not sign in.',
      );
    }
  }

  // ============================================================
  // GOOGLE SIGN IN
  // ============================================================

  Future<AuthSession> signInWithGoogle() async {
    try {
      try {
        await _ensureGoogleInitialized();
      } catch (_) {
        throw const AuthServiceException(
          code: 'google-initialization-failed',
          message:
              'Google sign-in could not start. Try again or use email sign-in.',
        );
      }

      if (!_googleSignIn.supportsAuthenticate()) {
        throw const AuthServiceException(
          code: 'google-sign-in-not-supported',
          message:
              'Google sign-in is not supported on this platform.',
        );
      }

      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      final GoogleSignInAuthentication
          googleAuthentication =
          googleUser.authentication;

      final String? idToken =
          googleAuthentication.idToken;

      if (idToken == null ||
          idToken.trim().isEmpty) {
        throw const AuthServiceException(
          code: 'google-missing-id-token',
          message:
              'Google sign-in did not return a valid identity token.',
        );
      }

      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final UserCredential result = await _firebaseAuth.signInWithCredential(
        credential,
      );
      return _sessionFromCredential(result);
    } on GoogleSignInException catch (error) {
      if (error.code ==
          GoogleSignInExceptionCode.canceled) {
        throw const AuthServiceException(
          code: 'google-sign-in-canceled',
          message:
              'Google sign-in was canceled.',
        );
      }

      throw AuthServiceException(
        code: 'google-sign-in-failed',
        message:
            error.description ??
            'Google sign-in failed.',
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        code: error.code,
        message:
            error.message ??
            'Could not sign in with Google.',
      );
    }
  }

  // ============================================================
  // PASSWORD RESET
  // ============================================================

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _firebaseAuth
          .sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        code: error.code,
        message:
            error.message ??
            'Could not send password reset email.',
      );
    }
  }

  // ============================================================
  // EMAIL VERIFICATION
  // ============================================================

  Future<void> sendEmailVerification() async {
    final User? user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const AuthServiceException(
        code: 'no-current-user',
        message:
            'No authenticated user is available.',
      );
    }

    if (user.emailVerified) {
      return;
    }

    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        code: error.code,
        message:
            error.message ??
            'Could not send verification email.',
      );
    }
  }

  Future<void> reloadCurrentUser() async {
    final User? user = _firebaseAuth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await user.reload();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        code: error.code,
        message:
            error.message ??
            'Could not refresh account information.',
      );
    }
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();

      try {
        await _ensureGoogleInitialized();
        await _googleSignIn.signOut();
      } catch (_) {
        // Firebase sign-out already succeeded.
        // Google session cleanup should not block logout.
      }
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        code: error.code,
        message:
            error.message ??
            'Could not sign out.',
      );
    }
  }

  // ============================================================
  // GOOGLE INITIALIZATION
  // ============================================================

  Future<void> _ensureGoogleInitialized() async {
    final Future<void> initialization =
        _googleInitialization ??= _googleSignIn.initialize();
    try {
      await initialization;
    } catch (_) {
      if (identical(_googleInitialization, initialization)) {
        _googleInitialization = null;
      }
      rethrow;
    }
  }

  AuthSession _sessionFromCredential(UserCredential credential) {
    final User? user = credential.user;
    if (user == null) {
      throw const AuthServiceException(
        code: 'no-current-user',
        message: 'The user session could not be loaded.',
      );
    }
    return _sessionFor(user);
  }

  AuthSession _sessionFor(User user) => AuthSession(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        emailVerified: user.emailVerified,
      );
}
