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

  // ============================================================
  // SESSION MODE SUPPORT
  // ============================================================

  bool get supportsOnline {
    final String normalized =
    mode.trim().toLowerCase();

    return normalized.contains(
      'online',
    );
  }

  bool get supportsInPerson {
    final String normalized =
    mode.trim().toLowerCase();

    return normalized.contains(
      'meetup',
    ) ||
        normalized.contains(
          'in-person',
        ) ||
        normalized.contains(
          'in person',
        );
  }

  bool supportsSessionMode(
      String requestedMode,
      ) {
    final String normalized =
    requestedMode
        .trim()
        .toLowerCase();

    if (normalized == 'online') {
      return supportsOnline;
    }

    if (normalized == 'in-person' ||
        normalized == 'in person' ||
        normalized == 'meetup') {
      return supportsInPerson;
    }

    return false;
  }

  List<String> get supportedSessionModes {
    final List<String> modes =
    <String>[];

    if (supportsOnline) {
      modes.add(
        'Online',
      );
    }

    if (supportsInPerson) {
      modes.add(
        'In-person',
      );
    }

    return List<String>.unmodifiable(
      modes,
    );
  }
}