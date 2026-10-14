import 'package:flutter/material.dart';

import 'edit_profile_screen.dart';

/// Thin first-run wrapper around [EditProfileScreen]. [EditProfileScreen]
/// has no way to report a successful save to a wrapper without being
/// edited, so this screen pushes it as a separate route and relies on the
/// fact that it already calls `Navigator.pop(context, true)` only after a
/// successful save: a `true` result means completed, anything else (back
/// button, system back) means the user backed out without saving and can
/// still choose to retry or skip from here.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
    required this.onDone,
  });

  final VoidCallback onDone;

  @override
  State<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends State<ProfileSetupScreen> {
  bool _opening = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openEditProfile();
    });
  }

  Future<void> _openEditProfile() async {
    if (_opening || !mounted) {
      return;
    }

    setState(() {
      _opening = true;
    });

    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => const EditProfileScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _opening = false;
    });

    if (saved == true) {
      widget.onDone();
    }
  }

  void _skip() {
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Complete your profile'),
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text('SKIP FOR NOW'),
          ),
        ],
      ),
      body: Center(
        child: _opening
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add your city, bio, availability, and teaching '
                      'preferences so others can find and understand you.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _openEditProfile,
                      child: const Text('COMPLETE YOUR PROFILE'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
