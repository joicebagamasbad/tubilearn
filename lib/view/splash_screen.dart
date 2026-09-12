import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dashboard_video_session_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController
  _animationController;

  late final Animation<double>
  _fadeAnimation;

  late final Animation<double>
  _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(
            milliseconds: 850,
          ),
        );

    _fadeAnimation =
        CurvedAnimation(
          parent:
          _animationController,
          curve:
          Curves.easeOut,
        );

    _scaleAnimation =
        Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent:
            _animationController,
            curve:
            Curves.easeOutBack,
          ),
        );

    _animationController.forward();

    _openDashboard();
  }

  Future<void> _openDashboard() async {
    await Future<void>.delayed(
      const Duration(
        seconds: 3,
      ),
    );

    if (!mounted) {
      return;
    }

    await Navigator.of(
      context,
    ).pushReplacement(
      MaterialPageRoute<void>(
        builder: (
            BuildContext context,
            ) =>
        const DashboardVideoSessionShell(),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    const Color backgroundTop =
    Color(
      0xFFF8FBFA,
    );

    const Color backgroundBottom =
    Color(
      0xFFEAF4F2,
    );

    const Color mascotSurface =
        Colors.white;

    final Color mascotBorder =
    AppTheme.primary.withValues(
      alpha: 0.12,
    );

    const Color titleColor =
    Color(
      0xFF173638,
    );

    const Color subtitleColor =
    Color(
      0xFF627674,
    );

    const Color loadingTextColor =
    Color(
      0xFF748583,
    );

    final Color accentColor =
        AppTheme.primary;

    return Scaffold(
      backgroundColor:
      backgroundTop,
      body: Container(
        width:
        double.infinity,
        height:
        double.infinity,
        decoration:
        const BoxDecoration(
          gradient:
          LinearGradient(
            begin:
            Alignment.topCenter,
            end:
            Alignment.bottomCenter,
            colors: <Color>[
              backgroundTop,
              backgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            child: Column(
              children: <Widget>[
                const Spacer(),

                FadeTransition(
                  opacity:
                  _fadeAnimation,
                  child:
                  ScaleTransition(
                    scale:
                    _scaleAnimation,
                    child:
                    Container(
                      width: 156,
                      height: 156,
                      decoration:
                      BoxDecoration(
                        shape:
                        BoxShape.circle,
                        color:
                        mascotSurface,
                        border:
                        Border.all(
                          color:
                          mascotBorder,
                          width:
                          1.5,
                        ),
                        boxShadow:
                        <BoxShadow>[
                          BoxShadow(
                            color:
                            Colors.black
                                .withValues(
                              alpha:
                              0.06,
                            ),
                            blurRadius:
                            28,
                            offset:
                            const Offset(
                              0,
                              10,
                            ),
                          ),
                        ],
                      ),
                      alignment:
                      Alignment.center,
                      child:
                      Image.asset(
                        'assets/images/mascot/tubi_happy.png',
                        width:
                        118,
                        height:
                        118,
                        fit:
                        BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                FadeTransition(
                  opacity:
                  _fadeAnimation,
                  child:
                  Image.asset(
                    'assets/images/tubilearn_logo.png',
                    width:
                    185,
                    fit:
                    BoxFit.contain,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                FadeTransition(
                  opacity:
                  _fadeAnimation,
                  child:
                  const Text(
                    'Learn together. Grow together.',
                    textAlign:
                    TextAlign.center,
                    style:
                    TextStyle(
                      fontSize:
                      17,
                      height:
                      1.3,
                      color:
                      titleColor,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                FadeTransition(
                  opacity:
                  _fadeAnimation,
                  child:
                  const Padding(
                    padding:
                    EdgeInsets.symmetric(
                      horizontal:
                      8,
                    ),
                    child:
                    Text(
                      'Share what you know and discover something new.',
                      textAlign:
                      TextAlign.center,
                      style:
                      TextStyle(
                        fontSize:
                        13,
                        height:
                        1.45,
                        color:
                        subtitleColor,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                FadeTransition(
                  opacity:
                  _fadeAnimation,
                  child:
                  Column(
                    children:
                    <Widget>[
                      SizedBox(
                        width:
                        21,
                        height:
                        21,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2.2,
                          color:
                          accentColor,
                        ),
                      ),

                      const SizedBox(
                        height:
                        11,
                      ),

                      const Text(
                        'Getting things ready...',
                        style:
                        TextStyle(
                          fontSize:
                          12,
                          color:
                          loadingTextColor,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}