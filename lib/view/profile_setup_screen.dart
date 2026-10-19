import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controller/my_skills_controller.dart';
import '../theme/app_theme.dart';
import 'add_skill_screen.dart';
import 'add_wanted_skill_screen.dart';
import 'edit_profile_screen.dart';

/// Default [ProfileSetupScreen.skillCountsLoader]: loads the current
/// user's offered/wanted skill counts via [MySkillsController]. Callers
/// (tests) may inject a fake loader instead.
Future<(int, int)> _defaultSkillCountsLoader() async {
  final MySkillsSnapshot snapshot = await MySkillsController().loadAllSkills();
  return (snapshot.offeredSkills.length, snapshot.wantedSkills.length);
}

/// Guided 4-step first-run wizard shown by [AuthGate] when
/// `needsProfileSetup` is true: Profile -> Teach -> Learn -> Done. Each
/// step is skippable; [onDone] is called once (from the Done step) and
/// [AuthGate] then shows the dashboard.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
    required this.onDone,
    this.skillCountsLoader,
  });

  final VoidCallback onDone;

  /// Returns (offeredCount, wantedCount) for the current user. Defaults
  /// to [MySkillsController.loadAllSkills]; tests inject a fake loader.
  final Future<(int, int)> Function()? skillCountsLoader;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const int _stepCount = 4;

  int _step = 0;
  bool _busy = false;

  int _offeredCount = 0;
  int _wantedCount = 0;

  // ============================================================
  // SKILL COUNTS
  // ============================================================

  Future<void> _refreshCounts() async {
    final Future<(int, int)> Function() loader =
        widget.skillCountsLoader ?? _defaultSkillCountsLoader;

    int offered = 0;
    int wanted = 0;

    try {
      final (int, int) counts = await loader();
      offered = counts.$1;
      wanted = counts.$2;
    } catch (_) {
      offered = 0;
      wanted = 0;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _offeredCount = offered;
      _wantedCount = wanted;
    });
  }

  // ============================================================
  // STEP NAVIGATION
  // ============================================================

  Future<void> _goToStep(int step) async {
    setState(() {
      _step = step;
    });

    if (step == _stepCount - 1) {
      await _refreshCounts();
    }
  }

  // ============================================================
  // PROFILE STEP
  // ============================================================

  Future<void> _openEditProfile() async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
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
      _busy = false;
    });

    if (saved == true) {
      await _goToStep(1);
    }
  }

  // ============================================================
  // TEACH STEP
  // ============================================================

  Future<void> _openAddSkill() async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
    });

    final bool? added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => const AddSkillScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _busy = false;
    });

    if (added == true) {
      await _refreshCounts();
    }
  }

  // ============================================================
  // LEARN STEP
  // ============================================================

  Future<void> _openAddWantedSkill() async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
    });

    final bool? added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => const AddWantedSkillScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _busy = false;
    });

    if (added == true) {
      await _refreshCounts();
    }
  }

  // ============================================================
  // DONE STEP
  // ============================================================

  void _findMyMatch() {
    final NavigatorState nav = Navigator.of(context);

    widget.onDone();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      nav.pushNamed('/smart-matches');
    });
  }

  void _goToDashboard() {
    widget.onDone();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }

        _goToStep(_step - 1);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: _buildStepContent(colorScheme),
        ),
      ),
    );
  }

  Widget _buildStepContent(ColorScheme colorScheme) {
    switch (_step) {
      case 0:
        return _buildStepChrome(
          colorScheme: colorScheme,
          asset: 'assets/images/mascot/tubi_typing.png',
          title: 'Set up your profile',
          subtitle:
              "Add a photo, a short bio, and when you're free so people "
              "know who they're swapping with.",
          showSkip: true,
          onSkip: _busy ? null : () => _goToStep(1),
          extraContent: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _openEditProfile,
                child: const Text('SET UP PROFILE'),
              ),
            ),
          ],
        );

      case 1:
        return _buildStepChrome(
          colorScheme: colorScheme,
          asset: 'assets/images/mascot/tubi_explaining.png',
          title: 'What can you teach?',
          subtitle:
              "Add a skill you can share, with your level and when "
              "you're available.",
          showSkip: true,
          onSkip: _busy ? null : () => _goToStep(2),
          extraContent: _buildTeachLearnExtra(
            colorScheme: colorScheme,
            count: _offeredCount,
            addLabel: 'ADD A SKILL',
            onAdd: _busy ? null : _openAddSkill,
            onNext: _offeredCount > 0 && !_busy ? () => _goToStep(2) : null,
          ),
        );

      case 2:
        return _buildStepChrome(
          colorScheme: colorScheme,
          asset: 'assets/images/mascot/tubi_thinking.png',
          title: 'What do you want to learn?',
          subtitle:
              "Tell Tubi what you'd love to pick up so it can match you "
              "with the right people.",
          showSkip: true,
          onSkip: _busy ? null : () => _goToStep(3),
          extraContent: _buildTeachLearnExtra(
            colorScheme: colorScheme,
            count: _wantedCount,
            addLabel: 'ADD A LEARNING INTEREST',
            onAdd: _busy ? null : _openAddWantedSkill,
            onNext: _wantedCount > 0 && !_busy ? () => _goToStep(3) : null,
          ),
        );

      case 3:
      default:
        final bool canMatch = _offeredCount > 0 && _wantedCount > 0;

        return _buildStepChrome(
          colorScheme: colorScheme,
          asset: 'assets/images/mascot/tubi_celebrating.png',
          title: "You're all set!",
          subtitle:
              "Your profile is ready. Let's find people to swap skills "
              "with.",
          showSkip: false,
          onSkip: null,
          extraContent: canMatch
              ? [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _findMyMatch,
                      child: const Text('FIND MY MATCH'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _goToDashboard,
                    child: const Text('GO TO DASHBOARD'),
                  ),
                ]
              : [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _goToDashboard,
                      child: const Text('GO TO DASHBOARD'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Add skills later in My Skills to unlock matches.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
        );
    }
  }

  // ============================================================
  // SHARED STEP CHROME
  // ============================================================

  Widget _buildStepChrome({
    required ColorScheme colorScheme,
    required String asset,
    required String title,
    required String subtitle,
    required bool showSkip,
    required VoidCallback? onSkip,
    required List<Widget> extraContent,
  }) {
    final Widget header = Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Step ${_step + 1} of $_stepCount',
            textAlign: TextAlign.center,
            style: AppTextStyles.secondary.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_step + 1) / _stepCount,
              color: colorScheme.primary,
              backgroundColor: colorScheme.outlineVariant,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: showSkip
                ? TextButton(
                    onPressed: onSkip,
                    child: const Text('Skip'),
                  )
                : const SizedBox(height: 40),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(
          child: _buildScrollBody(
            colorScheme: colorScheme,
            asset: asset,
            title: title,
            subtitle: subtitle,
            extraContent: extraContent,
          ),
        ),
      ],
    );
  }

  Widget _buildScrollBody({
    required ColorScheme colorScheme,
    required String asset,
    required String title,
    required String subtitle,
    required List<Widget> extraContent,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side = math
            .min(
              constraints.maxWidth - 56,
              constraints.maxHeight * 0.38,
            )
            .clamp(120.0, 260.0);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0.0, constraints.maxHeight - 24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SizedBox(
                    width: side,
                    height: side,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary.withValues(
                              alpha: 0.10,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Image.asset(
                            asset,
                            fit: BoxFit.contain,
                            cacheWidth: 700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pageTitle.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ...extraContent,
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TEACH / LEARN SHARED EXTRA CONTENT
  // ============================================================

  List<Widget> _buildTeachLearnExtra({
    required ColorScheme colorScheme,
    required int count,
    required String addLabel,
    required VoidCallback? onAdd,
    required VoidCallback? onNext,
  }) {
    final String countLabel =
        '$count skill${count == 1 ? '' : 's'} added';

    return [
      Text(
        countLabel,
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      if (count == 0) ...[
        const SizedBox(height: 6),
        Text(
          'Add at least one so Tubi can find your matches.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onAdd,
          child: Text(addLabel),
        ),
      ),
      if (onNext != null) ...[
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onNext,
            child: const Text('NEXT'),
          ),
        ),
      ],
    ];
  }
}
