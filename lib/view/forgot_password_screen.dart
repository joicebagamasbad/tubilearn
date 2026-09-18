import 'package:flutter/material.dart';

import '../controller/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthController _controller = AuthController();
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail);
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _sent = false;
      _error = null;
    });
    try {
      await _controller.sendPasswordReset(email: _email.text);
      if (mounted) {
        setState(() => _sent = true);
        _showFeedback('If an account exists for this email, a reset link is on its way.');
      }
    } on AuthControllerException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
        _showFeedback(error.message);
      }
    } catch (_) {
      if (mounted) {
        const String message = 'Could not send the reset email. Try again.';
        setState(() => _error = message);
        _showFeedback(message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Image.asset('assets/images/tubilearn_logo.png', height: 62),
                  const SizedBox(height: 26),
                  Text('Reset your password',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Enter your email and we will send a reset link.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  if (_error != null) ...<Widget>[
                    Text(_error!,
                        style: TextStyle(color: colors.error),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                  ],
                  if (_sent) ...<Widget>[
                    Text('If an account exists for this email, a reset link is on its way.',
                        style: TextStyle(color: colors.primary),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 18),
                  ],
                  TextField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _sendReset(),
                    decoration: const InputDecoration(labelText: 'Email address'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _busy ? null : _sendReset,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send reset link'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: const Text('Back to login'),
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
