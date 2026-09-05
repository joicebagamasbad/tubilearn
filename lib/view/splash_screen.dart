import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(
      const Duration(
        seconds: 3,
      ),
          () {
        if (!mounted) {
          return;
        }

        // Welcome Screen navigation will go here.
      },
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final ThemeData theme =
    Theme.of(context);

    final Color textColor =
        theme.colorScheme
            .onSurfaceVariant;

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/mascot/tubi_happy.png',
                width: 220,
              ),

              const SizedBox(
                height: 24,
              ),

              Image.asset(
                'assets/images/tubilearn_logo.png',
                width: 200,
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                'Share a skill. Discover another.',
                style: TextStyle(
                  fontSize: 15,
                  color:
                  textColor,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}