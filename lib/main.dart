import 'package:flutter/material.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized();

  await ChatService
      .instance
      .initialize();

  await SwapService
      .instance
      .initialize();

  runApp(
    const TubiLearnApp(),
  );
}

class TubiLearnApp
    extends StatelessWidget {
  const TubiLearnApp({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return MaterialApp(
      title: 'TubiLearn',

      debugShowCheckedModeBanner:
      false,

      theme:
      AppTheme.lightTheme,

      home:
      const DashboardScreen(),

      routes: {
        '/add-skill':
            (context) =>
        const AddSkillScreen(),

        '/my-skills':
            (context) =>
        const MySkillsScreen(),

        '/explore':
            (context) =>
        const ExploreScreen(),

        '/chat':
            (context) =>
        const ChatScreen(),
      },

      onGenerateRoute:
          (settings) {
        if (settings.name ==
            '/skill-details') {
          final skill =
          settings.arguments
          as Map<String, dynamic>;

          return MaterialPageRoute(
            builder:
                (context) =>
                SkillDetailsScreen(
                  skill: skill,
                ),
          );
        }

        if (settings.name ==
            '/user-profile') {
          final user =
          settings.arguments
          as Map<String, dynamic>;

          return MaterialPageRoute(
            builder:
                (context) =>
                UserProfileScreen(
                  user: user,
                ),
          );
        }

        if (settings.name ==
            '/conversation') {
          final conversationId =
          settings.arguments
          as String;

          return MaterialPageRoute(
            builder:
                (context) =>
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