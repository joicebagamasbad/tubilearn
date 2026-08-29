import 'package:flutter/material.dart';

import 'model/skill.dart';
import 'model/user.dart';

import 'model/repositories/explore_repository.dart';

import 'theme/app_theme.dart';

import 'services/chat_service.dart';
import 'services/swap_service.dart';

import 'view/dashboard_screen.dart';
import 'view/add_skill_screen.dart';
import 'view/my_skills_screen.dart';
import 'view/explore_screen.dart';
import 'view/skill_details_screen.dart';
import 'view/user_profile_screen.dart';
import 'view/chat_screen.dart';
import 'view/conversation_screen.dart';
import 'view/swap_requests_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // STARTUP INITIALIZATION
  // ============================================================

  await ExploreRepository.instance.initialize();

  await ChatService.instance.initialize();

  await SwapService.instance.initialize();

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
    return MaterialApp(
      title: 'TubiLearn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),

      routes: {
        '/add-skill': (context) =>
        const AddSkillScreen(),

        '/my-skills': (context) =>
        const MySkillsScreen(),

        '/explore': (context) =>
        const ExploreScreen(),

        '/chat': (context) =>
        const ChatScreen(),

        '/swap-requests': (context) =>
        const SwapRequestsScreen(),
      },

      onGenerateRoute: (settings) {
        // ======================================================
        // SKILL DETAILS
        // ======================================================

        if (settings.name ==
            '/skill-details') {
          final Skill skill =
          settings.arguments as Skill;

          return MaterialPageRoute(
            builder: (context) =>
                SkillDetailsScreen(
                  skill: skill,
                ),
          );
        }

        // ======================================================
        // USER PROFILE
        // ======================================================

        if (settings.name ==
            '/user-profile') {
          final User user =
          settings.arguments as User;

          return MaterialPageRoute(
            builder: (context) =>
                UserProfileScreen(
                  user: user,
                ),
          );
        }

        // ======================================================
        // CONVERSATION
        // ======================================================

        if (settings.name ==
            '/conversation') {
          final String conversationId =
          settings.arguments as String;

          return MaterialPageRoute(
            builder: (context) =>
                ConversationScreen(
                  conversationId:
                  conversationId,
                ),
          );
        }

        return null;
      },
    );
  }
}