import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

import 'model/skill.dart';
import 'model/user.dart';

import 'theme/app_theme.dart';

import 'services/app_settings_service.dart';

import 'view/auth_gate.dart';
import 'view/add_skill_screen.dart';
import 'view/my_skills_screen.dart';
import 'view/explore_screen.dart';
import 'view/skill_details_screen.dart';
import 'view/user_profile_screen.dart';
import 'view/profile_screen.dart';
import 'view/chat_screen.dart';
import 'view/conversation_screen.dart';
import 'view/swap_requests_screen.dart';
import 'view/smart_matches_screen.dart';
import 'view/video_call_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // FIREBASE INITIALIZATION
  // ============================================================

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ============================================================
  // APP CHECK
  // ============================================================
  //
  // DEBUG PROVIDER — local development only. Must be swapped to
  // AndroidProvider.playIntegrity (or equivalent) before any
  // production/release build.

  await FirebaseAppCheck.instance.activate(
    providerAndroid: const AndroidDebugProvider(),
  );

  // ============================================================
  // STARTUP INITIALIZATION
  // ============================================================

  await AppSettingsService.instance.initialize();

  runApp(
    const TubiLearnApp(),
  );
}

class TubiLearnApp extends StatelessWidget {
  const TubiLearnApp({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return AnimatedBuilder(
      animation:
      AppSettingsService.instance,
      builder: (
          BuildContext context,
          Widget? child,
          ) {
        return MaterialApp(
          title:
          'TubiLearn',
          debugShowCheckedModeBanner:
          false,

          theme:
          AppTheme.lightTheme,

          darkTheme:
          AppTheme.darkTheme,

          themeMode:
          AppSettingsService
              .instance
              .themeMode,

          home:
          const AuthGate(),

          routes: {
            '/add-skill': (
                context,
                ) =>
            const AddSkillScreen(),

            '/my-skills': (
                context,
                ) =>
            const MySkillsScreen(),

            '/explore': (
                context,
                ) =>
            const ExploreScreen(),

            '/chat': (
                context,
                ) =>
            const ChatScreen(),

            '/swap-requests': (
                context,
                ) =>
            const SwapRequestsScreen(),

            '/profile': (
                context,
                ) =>
            const ProfileScreen(),

            '/smart-matches': (
                context,
                ) =>
            const SmartMatchesScreen(),

            '/video-call': (
                context,
                ) =>
            const VideoCallScreen(),
          },

          onGenerateRoute: (
              RouteSettings settings,
              ) {
            // ==================================================
            // SKILL DETAILS
            // ==================================================

            if (settings.name ==
                '/skill-details') {
              final Skill skill =
              settings.arguments
              as Skill;

              return MaterialPageRoute(
                builder: (
                    context,
                    ) =>
                    SkillDetailsScreen(
                      skill:
                      skill,
                    ),
              );
            }

            // ==================================================
            // USER PROFILE
            // ==================================================

            if (settings.name ==
                '/user-profile') {
              final User user =
              settings.arguments
              as User;

              return MaterialPageRoute(
                builder: (
                    context,
                    ) =>
                    UserProfileScreen(
                      user:
                      user,
                    ),
              );
            }

            // ==================================================
            // CONVERSATION
            // ==================================================

            if (settings.name ==
                '/conversation') {
              final String
              conversationId =
              settings.arguments
              as String;

              return MaterialPageRoute(
                builder: (
                    context,
                    ) =>
                    ConversationScreen(
                      conversationId:
                      conversationId,
                    ),
              );
            }

            return null;
          },
        );
      },
    );
  }
}
