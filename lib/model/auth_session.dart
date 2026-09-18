class AuthSession {
  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;

  const AuthSession({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.emailVerified,
  });
}
