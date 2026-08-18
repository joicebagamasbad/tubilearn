import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'view/dashboard_screen.dart';
import 'view/add_skill_screen.dart';
import 'view/my_skills_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TubiLearnApp());
}

class TubiLearnApp extends StatelessWidget {
  const TubiLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TubiLearn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/add-skill': (context) => const AddSkillScreen(),
        '/my-skills': (context) => const MySkillsScreen(),
      },
    );
  }
}