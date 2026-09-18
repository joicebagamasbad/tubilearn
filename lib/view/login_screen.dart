import 'package:flutter/material.dart';

import '../controller/auth_controller.dart';
import '../model/auth_session.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? initialMessage;

  const LoginScreen({super.key, this.initialMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _controller = AuthController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _authenticate(Future<AuthSession> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      // AuthGate responds to the Firebase auth-state stream.
    } on AuthControllerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not sign in. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Image.asset('assets/images/tubilearn_logo.png', height: 68),
                  const SizedBox(height: 26),
                  Text('Welcome back',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('Learn together. Grow together.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  if (_error != null || widget.initialMessage != null) ...<Widget>[
                    Text(_error ?? widget.initialMessage!,
                        style: TextStyle(color: colors.error),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email address'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: _hidePassword,
                    autofillHints: const <String>[AutofillHints.password],
                    onSubmitted: (_) => _authenticate(() =>
                        _controller.signInWithEmail(
                          email: _email.text,
                          password: _password.text,
                        )),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        tooltip: _hidePassword ? 'Show password' : 'Hide password',
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                        icon: Icon(_hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ForgotPasswordScreen(
                                    initialEmail: _email.text,
                                  ),
                                ),
                              ),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () => _authenticate(() =>
                            _controller.signInWithEmail(
                              email: _email.text,
                              password: _password.text,
                            )),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Log in'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _authenticate(_controller.signInWithGoogle),
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text('New to TubiLearn?'),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const SignupScreen(),
                                  ),
                                ),
                        child: const Text('Sign up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
