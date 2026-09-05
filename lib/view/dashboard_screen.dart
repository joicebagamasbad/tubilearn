import 'package:flutter/material.dart';

import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/skill_match.dart';
import '../model/swap_request.dart';
import '../model/user.dart';
import '../services/current_user_service.dart';
import '../services/swap_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
  });

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  final ExploreRepository _repository =
      ExploreRepository.instance;

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  final SwapService _swapService =
      SwapService.instance;

  final ScrollController _scrollController =
  ScrollController();

  final GlobalKey _matchSectionKey =
  GlobalKey();

  int _selectedNav = 0;

  final List<Map<String, dynamic>> skills = [
    {
      'title': 'Graphic Design',
      'icon': Icons.design_services_outlined,
    },
    {
      'title': 'Photography',
      'icon': Icons.camera_alt_outlined,
    },
    {
      'title': 'Video Editing',
      'icon': Icons.movie_creation_outlined,
    },
    {
      'title': 'Illustration',
      'icon': Icons.brush_outlined,
    },
    {
      'title': 'UI/UX Design',
      'icon': Icons.dashboard_customize_outlined,
    },
  ];

  bool get _isDarkMode =>
      Theme.of(context).brightness ==
          Brightness.dark;

  Color get _primaryColor =>
      Theme.of(context).colorScheme.primary;

  Color get _surfaceColor =>
      Theme.of(context).colorScheme.surface;

  Color get _surfaceVariantColor =>
      Theme.of(context)
          .colorScheme
          .surfaceContainerHighest;

  Color get _textColor =>
      Theme.of(context).colorScheme.onSurface;

  Color get _mutedColor =>
      Theme.of(context)
          .colorScheme
          .onSurfaceVariant;

  Color get _borderColor =>
      Theme.of(context)
          .colorScheme
          .outlineVariant;

  Color get _softPrimaryColor =>
      _isDarkMode
          ? _primaryColor.withValues(
        alpha: 0.16,
      )
          : const Color(
        0xFFE4F0EF,
      );

  Color get _skillCardColor =>
      _isDarkMode
          ? _surfaceVariantColor
          : const Color(
        0xFFF1F5F3,
      );

  Color get _skillCardBorderColor =>
      _isDarkMode
          ? _borderColor
          : const Color(
        0xFFDCE6E2,
      );

  Color get _skillIconBackground =>
      _isDarkMode
          ? _surfaceColor
          : Colors.white;

  User? get _currentUser {
    try {
      final String userId =
      _currentUserService.requireUserId();

      return _repository.findUserById(
        userId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final SkillMatch? match =
    _findBestSmartMatch();

    final SwapRequest? upcomingSession =
    _findUpcomingSession();

    return Scaffold(
      backgroundColor:
      Theme.of(context)
          .scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller:
                _scrollController,
                physics:
                const BouncingScrollPhysics(),
                padding:
                const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  24,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildSearchBar(),

                    const SizedBox(
                      height: 24,
                    ),

                    Container(
                      key:
                      _matchSectionKey,
                      child: Column(
                        children: [
                          _buildSectionHeader(
                            title:
                            '✦ Your Smart Match',
                            action:
                            'See all',
                            onAction: () {
                              Navigator.pushNamed(
                                context,
                                '/smart-matches',
                              );
                            },
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          _buildMatchCard(
                            match,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    _buildSectionHeader(
                      title:
                      'Popular Skills',
                      action:
                      'Explore',
                      onAction: () {
                        Navigator.pushNamed(
                          context,
                          '/explore',
                        );
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildPopularSkills(),

                    const SizedBox(
                      height: 28,
                    ),

                    _buildSectionHeader(
                      title:
                      'Upcoming Session',
                      action:
                      'Requests',
                      onAction: () {
                        Navigator.pushNamed(
                          context,
                          '/swap-requests',
                        );
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _buildUpcomingSession(
                      upcomingSession,
                    ),
                  ],
                ),
              ),
            ),

            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final User? currentUser =
        _currentUser;

    final String displayName;

    if (currentUser == null ||
        currentUser.name.trim().isEmpty) {
      displayName =
      'there';
    } else {
      displayName =
          currentUser.name
              .trim()
              .split(
            RegExp(
              r'\s+',
            ),
          )
              .first;
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $displayName! 👋',
                style:
                AppTextStyles.pageTitle
                    .copyWith(
                  color:
                  _textColor,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                'Ready to share and learn?',
                style:
                AppTextStyles.secondary
                    .copyWith(
                  color:
                  _mutedColor,
                ),
              ),
            ],
          ),
        ),

        Container(
          width:
          40,
          height:
          40,
          decoration:
          BoxDecoration(
            color:
            _surfaceColor,
            borderRadius:
            BorderRadius.circular(
              12,
            ),
            border:
            Border.all(
              color:
              _borderColor,
            ),
          ),
          child: IconButton(
            tooltip:
            'Swap activity',
            padding:
            EdgeInsets.zero,
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/swap-requests',
              );
            },
            icon: Icon(
              Icons.notifications_none_rounded,
              size:
              21,
              color:
              _textColor,
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Container(
          width:
          42,
          height:
          42,
          decoration:
          const BoxDecoration(
            color:
            AppTheme.accent,
            shape:
            BoxShape.circle,
          ),
          alignment:
          Alignment.center,
          child: Text(
            currentUser?.initials ??
                'TL',
            style:
            const TextStyle(
              fontSize:
              12,
              fontWeight:
              FontWeight.w800,
              color:
              Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return InkWell(
      borderRadius:
      BorderRadius.circular(
        14,
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/explore',
        );
      },
      child: Container(
        height:
        50,
        decoration:
        BoxDecoration(
          color:
          _surfaceColor,
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          border:
          Border.all(
            color:
            _borderColor,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
            ),

            Icon(
              Icons.search_rounded,
              color:
              _mutedColor,
              size:
              20,
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Text(
                'Search skills or people',
                style:
                AppTextStyles.secondary
                    .copyWith(
                  color:
                  _mutedColor,
                ),
              ),
            ),

            Icon(
              Icons.explore_outlined,
              color:
              _primaryColor,
              size:
              20,
            ),

            const SizedBox(
              width: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required String title,
    String? action,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style:
            AppTextStyles.sectionTitle
                .copyWith(
              color:
              _textColor,
            ),
          ),
        ),

        if (action != null &&
            onAction != null)
          InkWell(
            borderRadius:
            BorderRadius.circular(
              8,
            ),
            onTap:
            onAction,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: Text(
                action,
                style:
                AppTextStyles.caption
                    .copyWith(
                  color:
                  _primaryColor,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // SMART MATCH
  // ============================================================

  SkillMatch? _findBestSmartMatch() {
    final User? currentUser =
        _currentUser;

    if (currentUser == null) {
      return null;
    }

    final List<SkillMatch> matches =
    _repository.getSmartMatchesForUser(
      currentUser.id,
      limit:
      1,
    );

    if (matches.isEmpty) {
      return null;
    }

    return matches.first;
  }

  Widget _buildMatchCard(
      SkillMatch? match,
      ) {
    if (match == null) {
      return _buildNoMatchCard();
    }

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        _surfaceColor,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color:
          _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:
                48,
                height:
                48,
                decoration:
                const BoxDecoration(
                  color:
                  AppTheme.accent,
                  shape:
                  BoxShape.circle,
                ),
                alignment:
                Alignment.center,
                child: Text(
                  match.user.initials,
                  style:
                  const TextStyle(
                    fontSize:
                    12,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Colors.white,
                  ),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.user.name,
                      style:
                      AppTextStyles.cardTitle
                          .copyWith(
                        color:
                        _textColor,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      match.headline,
                      maxLines:
                      1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      AppTextStyles.secondary
                          .copyWith(
                        fontSize:
                        12,
                        color:
                        _mutedColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                BoxDecoration(
                  color:
                  _softPrimaryColor,
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  '${match.score}% Match',
                  style:
                  AppTextStyles.caption
                      .copyWith(
                    color:
                    _primaryColor,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/mascot/tubi_happy.png',
                width:
                52,
                height:
                52,
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  match.explanation,
                  style:
                  AppTextStyles.bodyMuted
                      .copyWith(
                    color:
                    _mutedColor,
                  ),
                ),
              ),
            ],
          ),

          if (match.reasons.isNotEmpty) ...[
            const SizedBox(
              height: 14,
            ),

            Text(
              'Why this match',
              style:
              AppTextStyles.caption
                  .copyWith(
                color:
                _textColor,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Wrap(
              spacing:
              7,
              runSpacing:
              7,
              children:
              match.reasons
                  .take(
                4,
              )
                  .map(
                    (
                    String reason,
                    ) =>
                    _buildReasonChip(
                      reason,
                    ),
              )
                  .toList(),
            ),
          ],

          const SizedBox(
            height: 14,
          ),

          SizedBox(
            width:
            double.infinity,
            height:
            44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/user-profile',
                  arguments:
                  match.user,
                );
              },
              child:
              const Text(
                'VIEW MATCH',
                style:
                AppTextStyles.button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonChip(
      String reason,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        9,
        vertical:
        6,
      ),
      decoration:
      BoxDecoration(
        color:
        _softPrimaryColor,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border:
        Border.all(
          color:
          _primaryColor.withValues(
            alpha:
            0.18,
          ),
        ),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size:
            13,
            color:
            _primaryColor,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            reason,
            style:
            AppTextStyles.caption
                .copyWith(
              fontSize:
              10,
              color:
              _textColor,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchCard() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      BoxDecoration(
        color:
        _surfaceColor,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color:
          _borderColor,
        ),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/mascot/tubi_thinking.png',
            width:
            82,
            height:
            82,
            fit:
            BoxFit.contain,
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'No smart match yet',
            textAlign:
            TextAlign.center,
            style:
            AppTextStyles.cardTitle
                .copyWith(
              color:
              _textColor,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Add offered skills and learning interests so TubiLearn can compare skills, availability, mode, language, location, and trust signals.',
            textAlign:
            TextAlign.center,
            style:
            AppTextStyles.bodyMuted
                .copyWith(
              color:
              _mutedColor,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          SizedBox(
            width:
            double.infinity,
            height:
            42,
            child:
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/my-skills',
                );
              },
              icon:
              const Icon(
                Icons.add_rounded,
                size:
                18,
              ),
              label:
              const Text(
                'UPDATE MY SKILLS',
                style:
                AppTextStyles.button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // POPULAR SKILLS
  // ============================================================

  Widget _buildPopularSkills() {
    return SizedBox(
      height:
      138,
      child:
      ListView.separated(
        scrollDirection:
        Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        itemCount:
        skills.length,
        separatorBuilder:
            (
            _,
            _,
            ) {
          return const SizedBox(
            width:
            12,
          );
        },
        itemBuilder:
            (
            BuildContext context,
            int index,
            ) {
          final Map<String, dynamic> skill =
          skills[index];

          final String title =
          skill['title'] as String;

          return InkWell(
            borderRadius:
            BorderRadius.circular(
              17,
            ),
            onTap: () {
              _openPopularSkill(
                title,
              );
            },
            child: Container(
              width:
              132,
              padding:
              const EdgeInsets.all(
                14,
              ),
              decoration:
              BoxDecoration(
                color:
                _skillCardColor,
                borderRadius:
                BorderRadius.circular(
                  17,
                ),
                border:
                Border.all(
                  color:
                  _skillCardBorderColor,
                ),
              ),
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Container(
                    width:
                    50,
                    height:
                    50,
                    decoration:
                    BoxDecoration(
                      color:
                      _skillIconBackground,
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                      border:
                      Border.all(
                        color:
                        _borderColor,
                      ),
                    ),
                    child: Icon(
                      skill['icon']
                      as IconData,
                      color:
                      _primaryColor,
                      size:
                      25,
                    ),
                  ),

                  const SizedBox(
                    height: 11,
                  ),

                  Text(
                    title,
                    maxLines:
                    1,
                    overflow:
                    TextOverflow.ellipsis,
                    textAlign:
                    TextAlign.center,
                    style:
                    AppTextStyles.cardTitle
                        .copyWith(
                      fontSize:
                      13,
                      color:
                      _textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPopularSkill(
      String title,
      ) {
    Skill? matchedSkill;

    for (final Skill skill
    in _repository.skills) {
      if (skill.title
          .trim()
          .toLowerCase() ==
          title
              .trim()
              .toLowerCase()) {
        matchedSkill =
            skill;
        break;
      }
    }

    if (matchedSkill != null) {
      Navigator.pushNamed(
        context,
        '/skill-details',
        arguments:
        matchedSkill,
      );

      return;
    }

    Navigator.pushNamed(
      context,
      '/explore',
    );
  }

  // ============================================================
  // UPCOMING SESSION
  // ============================================================

  SwapRequest? _findUpcomingSession() {
    final User? currentUser =
        _currentUser;

    if (currentUser == null) {
      return null;
    }

    final DateTime now =
    DateTime.now();

    final List<SwapRequest> sessions =
    _swapService.requests.where(
          (
          SwapRequest request,
          ) {
        return request.status ==
            SwapRequestStatus.scheduled &&
            request.involvesUser(
              currentUser.id,
            ) &&
            request.proposedAt.isAfter(
              now,
            );
      },
    ).toList();

    if (sessions.isEmpty) {
      return null;
    }

    sessions.sort(
          (
          SwapRequest a,
          SwapRequest b,
          ) =>
          a.proposedAt.compareTo(
            b.proposedAt,
          ),
    );

    return sessions.first;
  }

  Widget _buildUpcomingSession(
      SwapRequest? request,
      ) {
    if (request == null) {
      return _buildNoUpcomingSession();
    }

    final User? currentUser =
        _currentUser;

    final User? otherUser =
    _findOtherUser(
      request,
      currentUser,
    );

    final String displayName =
        otherUser?.name ??
            request.providerName;

    final String initials =
        otherUser?.initials ??
            request.providerInitials;

    final String skillText =
        '${request.skillToLearn} ↔ ${request.skillToOffer}';

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        _surfaceColor,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border:
        Border.all(
          color:
          _borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width:
            46,
            height:
            46,
            decoration:
            const BoxDecoration(
              color:
              AppTheme.accent,
              shape:
              BoxShape.circle,
            ),
            alignment:
            Alignment.center,
            child: Text(
              initials,
              style:
              const TextStyle(
                fontSize:
                11,
                fontWeight:
                FontWeight.w800,
                color:
                Colors.white,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines:
                  1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  AppTextStyles.cardTitle
                      .copyWith(
                    color:
                    _textColor,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  skillText,
                  maxLines:
                  1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  AppTextStyles.secondary
                      .copyWith(
                    fontSize:
                    12,
                    color:
                    _mutedColor,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  '${_formatSessionDate(request.proposedAt)} • ${request.mode}',
                  style:
                  AppTextStyles.caption
                      .copyWith(
                    color:
                    _mutedColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          SizedBox(
            height:
            38,
            child:
            ElevatedButton(
              onPressed: () {
                _showSessionDetails(
                  request,
                  displayName,
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                _primaryColor,
                foregroundColor:
                _isDarkMode
                    ? const Color(
                  0xFF092E31,
                )
                    : Colors.white,
                padding:
                const EdgeInsets.symmetric(
                  horizontal:
                  12,
                ),
              ),
              child:
              Text(
                'SESSION INFO',
                style:
                AppTextStyles.button
                    .copyWith(
                  fontSize:
                  9.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUpcomingSession() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      BoxDecoration(
        color:
        _surfaceColor,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border:
        Border.all(
          color:
          _borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width:
            48,
            height:
            48,
            decoration:
            BoxDecoration(
              color:
              _softPrimaryColor,
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              Icons.event_available_outlined,
              color:
              _primaryColor,
              size:
              24,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'No scheduled session yet',
                  style:
                  AppTextStyles.cardTitle
                      .copyWith(
                    color:
                    _textColor,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  'Accept a swap request and schedule it to make the session appear here.',
                  style:
                  AppTextStyles.secondary
                      .copyWith(
                    fontSize:
                    11.5,
                    color:
                    _mutedColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          SizedBox(
            height:
            38,
            child:
            OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/swap-requests',
                );
              },
              style:
              OutlinedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(
                  horizontal:
                  12,
                ),
              ),
              child:
              Text(
                'VIEW',
                style:
                AppTextStyles.button
                    .copyWith(
                  fontSize:
                  10,
                  color:
                  _primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  User? _findOtherUser(
      SwapRequest request,
      User? currentUser,
      ) {
    if (currentUser == null ||
        !request.hasStableIdentity) {
      return null;
    }

    final String? otherUserId;

    if (request.isRequester(
      currentUser.id,
    )) {
      otherUserId =
          request.providerUserId;
    } else if (request.isProvider(
      currentUser.id,
    )) {
      otherUserId =
          request.requesterUserId;
    } else {
      return null;
    }

    if (otherUserId == null ||
        otherUserId.trim().isEmpty) {
      return null;
    }

    return _repository.findUserById(
      otherUserId,
    );
  }

  void _showSessionDetails(
      SwapRequest request,
      String displayName,
      ) {
    final String meetingDetails =
    request.meetingDetails
        ?.trim()
        .isNotEmpty ==
        true
        ? request.meetingDetails!.trim()
        : 'No meeting details provided.';

    showDialog<void>(
      context:
      context,
      builder:
          (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          _surfaceColor,
          title:
          Row(
            children: [
              Container(
                width:
                38,
                height:
                38,
                decoration:
                BoxDecoration(
                  color:
                  _softPrimaryColor,
                  borderRadius:
                  BorderRadius.circular(
                    11,
                  ),
                ),
                child: Icon(
                  request.mode ==
                      'Online'
                      ? Icons.videocam_outlined
                      : Icons.place_outlined,
                  color:
                  _primaryColor,
                  size:
                  20,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  'Session with $displayName',
                  style:
                  AppTextStyles.cardTitle
                      .copyWith(
                    color:
                    _textColor,
                  ),
                ),
              ),
            ],
          ),
          content:
          Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildSessionDetailRow(
                icon:
                Icons.schedule_rounded,
                label:
                'Schedule',
                value:
                _formatSessionDate(
                  request.proposedAt,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              _buildSessionDetailRow(
                icon:
                request.mode ==
                    'Online'
                    ? Icons.language_rounded
                    : Icons.location_on_outlined,
                label:
                'Mode',
                value:
                request.mode,
              ),

              const SizedBox(
                height: 14,
              ),

              _buildSessionDetailRow(
                icon:
                Icons.info_outline_rounded,
                label:
                request.mode ==
                    'Online'
                    ? 'Meeting details'
                    : 'Location details',
                value:
                meetingDetails,
              ),

              const SizedBox(
                height: 14,
              ),

              _buildSessionDetailRow(
                icon:
                Icons.swap_horiz_rounded,
                label:
                'Skill exchange',
                value:
                '${request.skillToLearn} ↔ ${request.skillToOffer}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
              Text(
                'CLOSE',
                style:
                AppTextStyles.button
                    .copyWith(
                  color:
                  _primaryColor,
                ),
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                Navigator.pushNamed(
                  context,
                  '/swap-requests',
                );
              },
              child:
              const Text(
                'VIEW REQUEST',
                style:
                AppTextStyles.button,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSessionDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size:
          18,
          color:
          _primaryColor,
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                AppTextStyles.caption
                    .copyWith(
                  color:
                  _mutedColor,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                value,
                style:
                AppTextStyles.secondary
                    .copyWith(
                  color:
                  _textColor,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatSessionDate(
      DateTime date,
      ) {
    final DateTime now =
    DateTime.now();

    final DateTime today =
    DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime target =
    DateTime(
      date.year,
      date.month,
      date.day,
    );

    final int difference =
        target.difference(
          today,
        ).inDays;

    final String dayLabel;

    if (difference == 0) {
      dayLabel =
      'Today';
    } else if (difference == 1) {
      dayLabel =
      'Tomorrow';
    } else {
      const List<String> months =
      <String>[
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      dayLabel =
      '${months[date.month - 1]} ${date.day}, ${date.year}';
    }

    final int hour12 =
    date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final String minute =
    date.minute
        .toString()
        .padLeft(
      2,
      '0',
    );

    final String period =
    date.hour >= 12
        ? 'PM'
        : 'AM';

    return '$dayLabel • $hour12:$minute $period';
  }

  // ============================================================
  // NAVIGATION HELPERS
  // ============================================================

  Future<void> _scrollToHome() async {
    setState(() {
      _selectedNav =
      0;
    });

    if (!_scrollController.hasClients) {
      return;
    }

    await _scrollController.animateTo(
      0,
      duration:
      const Duration(
        milliseconds:
        280,
      ),
      curve:
      Curves.easeOut,
    );
  }

  Future<void> _scrollToMatch() async {
    setState(() {
      _selectedNav =
      2;
    });

    final BuildContext? matchContext =
        _matchSectionKey.currentContext;

    if (matchContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      matchContext,
      duration:
      const Duration(
        milliseconds:
        280,
      ),
      curve:
      Curves.easeOut,
      alignment:
      0.08,
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    final List<Map<String, dynamic>> items = [
      {
        'icon':
        Icons.home_outlined,
        'selected':
        Icons.home_rounded,
        'label':
        'Home',
      },
      {
        'icon':
        Icons.explore_outlined,
        'selected':
        Icons.explore,
        'label':
        'Explore',
      },
      {
        'icon':
        Icons.auto_awesome_outlined,
        'selected':
        Icons.auto_awesome,
        'label':
        'Match',
      },
      {
        'icon':
        Icons.chat_bubble_outline_rounded,
        'selected':
        Icons.chat_bubble_rounded,
        'label':
        'Chat',
      },
      {
        'icon':
        Icons.person_outline_rounded,
        'selected':
        Icons.person_rounded,
        'label':
        'Profile',
      },
    ];

    return Container(
      height:
      76,
      decoration:
      BoxDecoration(
        color:
        _isDarkMode
            ? Theme.of(context)
            .scaffoldBackgroundColor
            : _surfaceColor,
        border:
        Border(
          top:
          BorderSide(
            color:
            _borderColor,
          ),
        ),
      ),
      child: Row(
        children:
        List.generate(
          items.length,
              (
              int index,
              ) {
            final bool selected =
                _selectedNav ==
                    index;

            return Expanded(
              child: InkWell(
                onTap: () {
                  if (index == 0) {
                    _scrollToHome();
                    return;
                  }

                  if (index == 1) {
                    Navigator.pushNamed(
                      context,
                      '/explore',
                    );
                    return;
                  }

                  if (index == 2) {
                    _scrollToMatch();
                    return;
                  }

                  if (index == 3) {
                    Navigator.pushNamed(
                      context,
                      '/chat',
                    );
                    return;
                  }

                  if (index == 4) {
                    Navigator.pushNamed(
                      context,
                      '/profile',
                    );
                  }
                },
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration:
                      const Duration(
                        milliseconds:
                        180,
                      ),
                      width:
                      36,
                      height:
                      29,
                      decoration:
                      BoxDecoration(
                        color:
                        selected
                            ? _softPrimaryColor
                            : Colors.transparent,
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: Icon(
                        selected
                            ? items[index]['selected']
                        as IconData
                            : items[index]['icon']
                        as IconData,
                        size:
                        20,
                        color:
                        selected
                            ? _primaryColor
                            : _mutedColor,
                      ),
                    ),

                    const SizedBox(
                      height:
                      3,
                    ),

                    Text(
                      items[index]['label']
                      as String,
                      style:
                      AppTextStyles.navLabel
                          .copyWith(
                        color:
                        selected
                            ? _primaryColor
                            : _mutedColor,
                        fontWeight:
                        selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}