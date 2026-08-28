import 'package:flutter/material.dart';

class Skill {
  final String id;

  final String title;
  final String category;
  final String level;

  final IconData icon;

  final String sessionLength;
  final String mode;
  final String language;

  final String prerequisite;
  final String description;

  final List<String> learnings;

  const Skill({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.icon,
    required this.sessionLength,
    required this.mode,
    required this.language,
    required this.prerequisite,
    required this.description,
    required this.learnings,
  });
}