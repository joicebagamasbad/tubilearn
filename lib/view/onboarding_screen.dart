import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';
import '../theme/app_theme.dart';
import 'auth_gate.dart';

/// First-install, 3-page onboarding carousel. Calls [onFinished] on Skip
/// or after the final "Get Started" page — the caller decides what happens
/// next (see [OnboardingGate]).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onFinished,
  });

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.asset,
    required this.title,
    required this.subtitle,
  });

  final String asset;
  final String title;
  final String subtitle;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<_OnboardingPageData> _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      asset: 'assets/images/mascot/tubi_happy.png',
      title: 'Welcome to TubiLearn',
      subtitle:
          'Meet Tubi! Share what you know and learn what you want, all in '
          'one friendly place.',
    ),
    _OnboardingPageData(
      asset: 'assets/images/mascot/tubi_explaining.png',
      title: 'Swap skills, not money',
      subtitle:
          'List the skills you can teach and the ones you want to learn. '
          'Tubi helps you find people who match.',
    ),
    _OnboardingPageData(
      asset: 'assets/images/mascot/tubi_celebrating.png',
      title: 'Match, chat, and learn',
      subtitle:
          'Request a swap, set a schedule, chat, and review each other '
          'after your session.',
    ),
  ];

  late final PageController _pageController;
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        _goToPage(_currentPage - 1);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _isLastPage
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TextButton(
                            onPressed: widget.onFinished,
                            child: const Text('Skip'),
                          ),
                        ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (int index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return _buildPage(_pages[index], colorScheme);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  _pages.length,
                  (int index) => _buildDot(index, colorScheme),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLastPage
                        ? widget.onFinished
                        : () => _goToPage(_currentPage + 1),
                    child: Text(_isLastPage ? 'GET STARTED' : 'NEXT'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(
    _OnboardingPageData page,
    ColorScheme colorScheme,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side =
            math.min(
              constraints.maxWidth - 56,
              constraints.maxHeight * 0.45,
            ).clamp(140.0, 340.0);

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
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
                          padding: const EdgeInsets.all(28),
                          child: Image.asset(
                            page.asset,
                            fit: BoxFit.contain,
                            cacheWidth: 700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.pageTitle.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    page.subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDot(
    int index,
    ColorScheme colorScheme,
  ) {
    final bool active = index == _currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? colorScheme.primary : colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Shown once, before [AuthGate], on a fresh install. Reads
/// [AppSettingsService.instance] (already initialized in `main()` before
/// `runApp`) exactly the way `main.dart` itself does, so no extra
/// initialization is needed here.
///
/// `const AuthGate()` is a compile-time constant, so every `build()` call
/// below returns the same canonical instance — [AuthGate] is never
/// recreated when this gate switches away from [OnboardingScreen].
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({
    super.key,
  });

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = !AppSettingsService.instance.onboardingSeen;
  }

  void _finishOnboarding() {
    try {
      // Fire-and-forget: AppSettingsService.markOnboardingSeen() already
      // swallows its own persistence failures.
      unawaited(AppSettingsService.instance.markOnboardingSeen());
    } catch (_) {
      // Never block leaving onboarding over a persistence failure.
    }

    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(onFinished: _finishOnboarding);
    }

    return const AuthGate();
  }
}
