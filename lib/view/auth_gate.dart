import 'package:flutter/material.dart';

import '../controller/auth_controller.dart';
import '../controller/authenticated_session_controller.dart';
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
  final AuthenticatedSessionController _sessionController =
      AuthenticatedSessionController();
  late final Stream<AuthSession?> _authStateChanges =
      _controller.authStateChanges;
  String? _pendingUid;
  Future<void>? _preparation;

  Future<void> _prepare(AuthSession? session) {
    final String? uid = session?.uid;
    if (_preparation == null || _pendingUid != uid) {
      if (_preparation != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
          }
        });
      }
      _pendingUid = uid;
      _preparation = _sessionController.prepare(session);
    }
    return _preparation!;
  }

  void _retry(AuthSession? session) {
    setState(() {
      _pendingUid = session?.uid;
      _preparation = _sessionController.prepare(session);
    });
  }

  Future<void> _signOutAfterFailure(BuildContext context) async {
    try {
      await _controller.signOut();
    } on AuthControllerException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not sign out. Please try again.')),
        );
      }
    }
  }

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

        final AuthSession? session = snapshot.hasError ? null : snapshot.data;
        return FutureBuilder<void>(
          future: _prepare(session),
          builder: (BuildContext context, AsyncSnapshot<void> preparation) {
            if (preparation.connectionState != ConnectionState.done) {
              return const SplashScreen();
            }
            if (preparation.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text(
                          'Could not prepare your account. Please try again.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => _retry(session),
                          child: const Text('Try again'),
                        ),
                        if (session != null)
                          TextButton(
                            onPressed: () => _signOutAfterFailure(context),
                            child: const Text('Sign out'),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return const LoginScreen(
                initialMessage: 'Could not restore your session. Please sign in.',
              );
            }
            return session == null
                ? const LoginScreen()
                : DashboardVideoSessionShell(key: ValueKey<String>(session.uid));
          },
        );
      },
    );
  }
}
