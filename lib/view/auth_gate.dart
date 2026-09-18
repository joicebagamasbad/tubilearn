import 'package:flutter/material.dart';

import '../controller/auth_controller.dart';
import '../model/auth_session.dart';
import 'dashboard_video_session_shell.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthController _controller = AuthController();
  late final Stream<AuthSession?> _authStateChanges =
      _controller.authStateChanges;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthSession?>(
      stream: _authStateChanges,
      builder: (BuildContext context, AsyncSnapshot<AuthSession?> snapshot) {
        if (!snapshot.hasData &&
            !snapshot.hasError &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasError) {
          return const LoginScreen(
            initialMessage: 'Could not restore your session. Please sign in.',
          );
        }

        return snapshot.data == null
            ? const LoginScreen()
            : const DashboardVideoSessionShell();
      },
    );
  }
}
