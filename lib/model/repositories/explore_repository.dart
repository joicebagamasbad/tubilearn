import 'package:flutter/material.dart';

import '../skill.dart';
import '../user.dart';
import '../user_skill.dart';

class ExploreRepository {
  // ============================================================
  // USERS
  // ============================================================

  final List<User> _users = const [
    User(
      id: 'user_mika_santos',
      name: 'Mika Santos',
      initials: 'MS',
      city: 'Tarlac City',
      bio:
      'I enjoy helping beginners create practical designs for school, small businesses, and social media.',
      rating: 4.8,
      reviewCount: 10,
      completedSwaps: 12,
      responseRate: 94,
      memberSince: '2026',
      availability: 'Weekends • 2:00 PM onwards',
      language: 'Filipino / English',
      preferredMode: 'Online / Meetup',
      teachingStyle:
      'Beginner-friendly, practical, and hands-on.',
      emailVerified: true,
      profileCompleted: true,
    ),
    User(
      id: 'user_paolo_reyes',
      name: 'Paolo Reyes',
      initials: 'PR',
      city: 'Angeles City',
      bio:
      'Graphic designer who enjoys sharing practical design techniques and learning creative skills from others.',
      rating: 4.9,
      reviewCount: 17,
      completedSwaps: 21,
      responseRate: 96,
      memberSince: '2026',
      availability: 'Weekday evenings',
      language: 'Filipino / English',
      preferredMode: 'Online / Meetup',
      teachingStyle:
      'Structured, practical, and project-based.',
      emailVerified: true,
      profileCompleted: true,
    ),
    User(
      id: 'user_alex_rivera',
      name: 'Alex Rivera',
      initials: 'AR',
      city: 'Mabalacat City',
      bio:
      'I enjoy photography and helping people improve their shots using the equipment they already have.',
      rating: 4.9,
      reviewCount: 15,
      completedSwaps: 18,
      responseRate: 95,
      memberSince: '2026',
      availability: 'Saturday afternoons',
      language: 'Filipino / English',
      preferredMode: 'Online / Meetup',
      teachingStyle:
      'Visual, practical, and beginner-friendly.',
      emailVerified: true,
      profileCompleted: true,
    ),
    User(
      id: 'user_bea_mendoza',
      name: 'Bea Mendoza',
      initials: 'BM',
      city: 'Tarlac City',
      bio:
      'Photography enthusiast who enjoys teaching composition, lighting, and simple editing.',
      rating: 4.7,
      reviewCount: 7,
      completedSwaps: 9,
      responseRate: 90,
      memberSince: '2026',
      availability: 'Sunday mornings',
      language: 'Filipino / English',
      preferredMode: 'Online / Meetup',
      teachingStyle:
      'Relaxed, visual, and practice-focused.',
      emailVerified: true,
      profileCompleted: true,
    ),
    User(
      id: 'user_carlo_dela_cruz',
      name: 'Carlo Dela Cruz',
      initials: 'CD',
      city: 'Quezon City',
      bio:
      'Video editor who enjoys teaching practical editing techniques for school projects and social content.',
      rating: 4.8,
      reviewCount: 13,
      completedSwaps: 16,
      responseRate: 93,
      memberSince: '2026',
      availability: 'Weekday evenings',
      language: 'Filipino / English',
      preferredMode: 'Online',
      teachingStyle:
      'Hands-on, practical, and workflow-based.',
      emailVerified: true,
      profileCompleted: true,
    ),
    User(
      id: 'user_jamie_garcia',
      name: 'Jamie Garcia',
      initials: 'JG',
      city: 'San Fernando, Pampanga',
      bio:
      'I enjoy helping beginners edit simple videos and improve their storytelling through clips, captions, and pacing.',
      rating: 4.7,
      reviewCount: 8,
      completedSwaps: 8,
      responseRate: 89,
      memberSince: '2026',
      availability: 'Saturday evenings',
      language: 'Filipino / English',
      preferredMode: 'Online',
      teachingStyle:
      'Beginner-friendly, patient, and practical.',
      emailVerified: true,
      profileCompleted: true,
    ),
    User(
      id: 'user_nico_villanueva',
      name: 'Nico Villanueva',
      initials: 'NV',
      city: 'Manila',
      bio:
      'UI/UX learner and designer who enjoys explaining interface design through simple real-world examples.',
      rating: 4.8,
      reviewCount: 11,
      completedSwaps: 14,
      responseRate: 92,
      memberSince: '2026',
      availability: 'Sunday afternoons',
      language: 'Filipino / English',
      preferredMode: 'Online',
      teachingStyle:
      'Structured, visual, and beginner-friendly.',
      emailVerified: true,
      profileCompleted: true,
    ),
    User(
      id: 'user_joshua_lim',
      name: 'Joshua Lim',
      initials: 'JL',
      city: 'Cebu City',
      bio:
      'Web developer who enjoys teaching beginners how websites work from HTML and CSS fundamentals.',
      rating: 4.9,
      reviewCount: 16,
      completedSwaps: 20,
      responseRate: 96,
      memberSince: '2026',
      availability: 'Weekday evenings',
      language: 'Filipino / English',
      preferredMode: 'Online',
      teachingStyle:
      'Step-by-step, practical, and exercise-based.',
      emailVerified: true,
      profileCompleted: true,
    ),
    User(
      id: 'user_andrea_flores',
      name: 'Andrea Flores',
      initials: 'AF',
      city: 'Baguio City',
      bio:
      'I help learners build confidence in spoken English through relaxed and practical conversation.',
      rating: 4.9,
      reviewCount: 19,
      completedSwaps: 23,
      responseRate: 97,
      memberSince: '2026',
      availability: 'Weekday evenings',
      language: 'English / Filipino',
      preferredMode: 'Online',
      teachingStyle:
      'Conversational, supportive, and confidence-focused.',
      emailVerified: true,
      profileCompleted: true,
    ),
  ];

  // ============================================================
  // SKILLS
  // ============================================================

  final List<Skill> _skills = const [
    Skill(
      id: 'skill_graphic_design',
      title: 'Graphic Design',
      category: 'Design',
      level: 'Beginner–Intermediate',
      icon: Icons.design_services_outlined,
      sessionLength: '45–60 mins',
      mode: 'Online / Meetup',
      language: 'Filipino / English',
      prerequisite:
      'A phone, tablet, or laptop. Canva is enough for beginners.',
      description:
      'Learn practical graphic design for school projects, social media posts, small businesses, presentations, and basic branding.',
      learnings: [
        'Basic layout and visual hierarchy',
        'Color combinations and typography',
        'Creating posters and social media graphics',
        'Using Canva efficiently',
      ],
    ),
    Skill(
      id: 'skill_photography',
      title: 'Photography',
      category: 'Photography',
      level: 'Beginner–Intermediate',
      icon: Icons.camera_alt_outlined,
      sessionLength: '45–60 mins',
      mode: 'Online / Meetup',
      language: 'Filipino / English',
      prerequisite:
      'Any smartphone or camera. A DSLR or mirrorless camera is not required.',
      description:
      'Learn practical photography using equipment you already have, from smartphone cameras to dedicated cameras.',
      learnings: [
        'Composition and framing',
        'Using natural and available light',
        'Basic camera or smartphone settings',
        'Simple photo editing and color correction',
      ],
    ),
    Skill(
      id: 'skill_video_editing',
      title: 'Video Editing',
      category: 'Video',
      level: 'Beginner–Intermediate',
      icon: Icons.movie_creation_outlined,
      sessionLength: '60 mins',
      mode: 'Online',
      language: 'Filipino / English',
      prerequisite:
      'A smartphone or computer capable of running CapCut, VN, Premiere Pro, or a similar editor.',
      description:
      'Learn practical video editing for school requirements, short-form content, personal projects, and small business promotion.',
      learnings: [
        'Trimming and arranging clips',
        'Basic transitions and pacing',
        'Audio, captions, and simple effects',
        'Export settings for social media',
      ],
    ),
    Skill(
      id: 'skill_ui_ux_design',
      title: 'UI/UX Design',
      category: 'Design',
      level: 'Beginner',
      icon: Icons.dashboard_customize_outlined,
      sessionLength: '60 mins',
      mode: 'Online',
      language: 'Filipino / English',
      prerequisite:
      'A laptop or desktop computer. No prior Figma experience required.',
      description:
      'Learn how to plan and design simple mobile or web interfaces with a focus on usability rather than decoration alone.',
      learnings: [
        'Basic UI and UX principles',
        'Wireframes and screen planning',
        'Using Figma for simple interfaces',
        'Building consistent layouts and components',
      ],
    ),
    Skill(
      id: 'skill_basic_web_development',
      title: 'Basic Web Development',
      category: 'Technology',
      level: 'Beginner',
      icon: Icons.code_rounded,
      sessionLength: '60–90 mins',
      mode: 'Online',
      language: 'Filipino / English',
      prerequisite:
      'A laptop or desktop computer and willingness to practice between sessions.',
      description:
      'Learn the foundations of building simple websites using HTML, CSS, and basic programming concepts.',
      learnings: [
        'HTML page structure',
        'Basic CSS styling',
        'Simple responsive layouts',
        'How websites and browsers work',
      ],
    ),
    Skill(
      id: 'skill_english_conversation',
      title: 'English Conversation',
      category: 'Communication',
      level: 'Beginner–Intermediate',
      icon: Icons.record_voice_over_outlined,
      sessionLength: '30–45 mins',
      mode: 'Online / Meetup',
      language: 'English with Filipino support',
      prerequisite:
      'No formal requirement. Best for learners who want more confidence speaking English.',
      description:
      'Practice everyday English conversation in a low-pressure setting for school, work, interviews, and daily communication.',
      learnings: [
        'Conversational vocabulary',
        'Speaking with more confidence',
        'Common grammar corrections',
        'Interview and presentation practice',
      ],
    ),
    Skill(
      id: 'skill_basic_excel',
      title: 'Basic Excel',
      category: 'Technology',
      level: 'Beginner',
      icon: Icons.table_chart_outlined,
      sessionLength: '45–60 mins',
      mode: 'Online',
      language: 'Filipino / English',
      prerequisite:
      'A computer with Microsoft Excel or compatible spreadsheet software.',
      description:
      'Learn basic spreadsheet organization, formulas, formatting, and practical Excel tasks.',
      learnings: [
        'Basic spreadsheet navigation',
        'Simple formulas and functions',
        'Formatting tables and data',
        'Organizing information efficiently',
      ],
    ),
    Skill(
      id: 'skill_public_speaking',
      title: 'Public Speaking',
      category: 'Communication',
      level: 'Beginner',
      icon: Icons.campaign_outlined,
      sessionLength: '30–45 mins',
      mode: 'Online / Meetup',
      language: 'Filipino / English',
      prerequisite:
      'No formal requirement.',
      description:
      'Build confidence speaking in front of groups for school presentations, interviews, and everyday communication.',
      learnings: [
        'Managing speaking anxiety',
        'Organizing ideas clearly',
        'Voice and delivery basics',
        'Presentation practice',
      ],
    ),
    Skill(
      id: 'skill_basic_guitar',
      title: 'Basic Guitar',
      category: 'Music',
      level: 'Beginner',
      icon: Icons.music_note_rounded,
      sessionLength: '45–60 mins',
      mode: 'Online / Meetup',
      language: 'Filipino / English',
      prerequisite:
      'Access to an acoustic or electric guitar.',
      description:
      'Learn basic guitar fundamentals for complete beginners.',
      learnings: [
        'Basic chords',
        'Simple strumming patterns',
        'Changing chords smoothly',
        'Playing beginner songs',
      ],
    ),
    Skill(
      id: 'skill_canva_design',
      title: 'Canva Design',
      category: 'Design',
      level: 'Beginner',
      icon: Icons.palette_outlined,
      sessionLength: '30–45 mins',
      mode: 'Online',
      language: 'Filipino / English',
      prerequisite:
      'A Canva account and phone, tablet, or computer.',
      description:
      'Learn practical Canva basics for school projects, social posts, and simple visual materials.',
      learnings: [
        'Using Canva templates',
        'Editing text and elements',
        'Simple visual hierarchy',
        'Exporting finished designs',
      ],
    ),
  ];

  // ============================================================
  // USER ↔ SKILL RELATIONSHIPS
  // ============================================================

  final List<UserSkill> _userSkills = const [
    // Mika
    UserSkill(
      id: 'us_mika_graphic_design_offer',
      userId: 'user_mika_santos',
      skillId: 'skill_graphic_design',
      type: UserSkillType.offered,
      level: 'Intermediate',
      availability: 'Weekends • 2:00 PM onwards',
    ),
    UserSkill(
      id: 'us_mika_excel_wanted',
      userId: 'user_mika_santos',
      skillId: 'skill_basic_excel',
      type: UserSkillType.wanted,
      level: 'Beginner',
      availability: 'Weekends',
    ),

    // Paolo
    UserSkill(
      id: 'us_paolo_graphic_design_offer',
      userId: 'user_paolo_reyes',
      skillId: 'skill_graphic_design',
      type: UserSkillType.offered,
      level: 'Advanced',
      availability: 'Weekday evenings',
    ),
    UserSkill(
      id: 'us_paolo_photography_wanted',
      userId: 'user_paolo_reyes',
      skillId: 'skill_photography',
      type: UserSkillType.wanted,
      level: 'Beginner',
      availability: 'Weekday evenings',
    ),

    // Alex
    UserSkill(
      id: 'us_alex_photography_offer',
      userId: 'user_alex_rivera',
      skillId: 'skill_photography',
      type: UserSkillType.offered,
      level: 'Advanced',
      availability: 'Saturday afternoons',
    ),
    UserSkill(
      id: 'us_alex_graphic_design_wanted',
      userId: 'user_alex_rivera',
      skillId: 'skill_graphic_design',
      type: UserSkillType.wanted,
      level: 'Beginner',
      availability: 'Saturday afternoons',
    ),

    // Bea
    UserSkill(
      id: 'us_bea_photography_offer',
      userId: 'user_bea_mendoza',
      skillId: 'skill_photography',
      type: UserSkillType.offered,
      level: 'Intermediate',
      availability: 'Sunday mornings',
    ),
    UserSkill(
      id: 'us_bea_video_editing_wanted',
      userId: 'user_bea_mendoza',
      skillId: 'skill_video_editing',
      type: UserSkillType.wanted,
      level: 'Beginner',
      availability: 'Sunday mornings',
    ),

    // Carlo
    UserSkill(
      id: 'us_carlo_video_editing_offer',
      userId: 'user_carlo_dela_cruz',
      skillId: 'skill_video_editing',
      type: UserSkillType.offered,
      level: 'Advanced',
      availability: 'Weekday evenings',
    ),
    UserSkill(
      id: 'us_carlo_english_wanted',
      userId: 'user_carlo_dela_cruz',
      skillId: 'skill_english_conversation',
      type: UserSkillType.wanted,
      level: 'Beginner',
      availability: 'Weekday evenings',
    ),

    // Jamie
    UserSkill(
      id: 'us_jamie_video_editing_offer',
      userId: 'user_jamie_garcia',
      skillId: 'skill_video_editing',
      type: UserSkillType.offered,
      level: 'Intermediate',
      availability: 'Saturday evenings',
    ),
    UserSkill(
      id: 'us_jamie_canva_wanted',
      userId: 'user_jamie_garcia',
      skillId: 'skill_canva_design',
      type: UserSkillType.wanted,
      level: 'Beginner',
      availability: 'Saturday evenings',
    ),

    // Nico
    UserSkill(
      id: 'us_nico_uiux_offer',
      userId: 'user_nico_villanueva',
      skillId: 'skill_ui_ux_design',
      type: UserSkillType.offered,
      level: 'Intermediate',
      availability: 'Sunday afternoons',
    ),
    UserSkill(
      id: 'us_nico_public_speaking_wanted',
      userId: 'user_nico_villanueva',
      skillId: 'skill_public_speaking',
      type: UserSkillType.wanted,
      level: 'Beginner',
      availability: 'Sunday afternoons',
    ),

    // Joshua
    UserSkill(
      id: 'us_joshua_web_offer',
      userId: 'user_joshua_lim',
      skillId: 'skill_basic_web_development',
      type: UserSkillType.offered,
      level: 'Intermediate',
      availability: 'Weekday evenings',
    ),
    UserSkill(
      id: 'us_joshua_guitar_wanted',
      userId: 'user_joshua_lim',
      skillId: 'skill_basic_guitar',
      type: UserSkillType.wanted,
      level: 'Beginner',
      availability: 'Weekday evenings',
    ),

    // Andrea
    UserSkill(
      id: 'us_andrea_english_offer',
      userId: 'user_andrea_flores',
      skillId: 'skill_english_conversation',
      type: UserSkillType.offered,
      level: 'Advanced',
      availability: 'Weekday evenings',
    ),
    UserSkill(
      id: 'us_andrea_video_wanted',
      userId: 'user_andrea_flores',
      skillId: 'skill_video_editing',
      type: UserSkillType.wanted,
      level: 'Beginner',
      availability: 'Weekday evenings',
    ),
  ];

  // ============================================================
  // PUBLIC READ METHODS
  // ============================================================

  List<User> get users =>
      List.unmodifiable(_users);

  List<Skill> get skills =>
      List.unmodifiable(_skills);

  List<UserSkill> get userSkills =>
      List.unmodifiable(_userSkills);

  User? findUserById(
      String userId,
      ) {
    for (final User user in _users) {
      if (user.id == userId) {
        return user;
      }
    }

    return null;
  }

  Skill? findSkillById(
      String skillId,
      ) {
    for (final Skill skill in _skills) {
      if (skill.id == skillId) {
        return skill;
      }
    }

    return null;
  }

  List<UserSkill> getOfferedSkillsForUser(
      String userId,
      ) {
    return _userSkills.where(
          (item) =>
      item.userId == userId &&
          item.type == UserSkillType.offered,
    ).toList();
  }

  List<UserSkill> getWantedSkillsForUser(
      String userId,
      ) {
    return _userSkills.where(
          (item) =>
      item.userId == userId &&
          item.type == UserSkillType.wanted,
    ).toList();
  }

  List<User> getProvidersForSkill(
      String skillId,
      ) {
    final Set<String> providerIds =
    _userSkills
        .where(
          (item) =>
      item.skillId == skillId &&
          item.type == UserSkillType.offered,
    )
        .map(
          (item) => item.userId,
    )
        .toSet();

    return _users
        .where(
          (user) =>
          providerIds.contains(user.id),
    )
        .toList();
  }

  UserSkill? findUserSkill({
    required String userId,
    required String skillId,
    required UserSkillType type,
  }) {
    for (final UserSkill item
    in _userSkills) {
      if (item.userId == userId &&
          item.skillId == skillId &&
          item.type == type) {
        return item;
      }
    }

    return null;
  }
}