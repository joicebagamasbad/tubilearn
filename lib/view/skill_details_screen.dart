import 'dart:io';

import 'package:flutter/material.dart';

import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/user.dart';
import '../model/user_skill.dart';
import '../services/current_user_service.dart';
import '../theme/app_theme.dart';
import 'create_swap_request_screen.dart';

class SkillDetailsScreen extends StatelessWidget {
  final Skill skill;

  const SkillDetailsScreen({
    super.key,
    required this.skill,
  });

  static final ExploreRepository _repository =
      ExploreRepository.instance;

  static final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  // ============================================================
  // THEME
  // ============================================================

  Color _primaryColor(
      BuildContext context,
      ) {
    return Theme.of(
      context,
    ).colorScheme.primary;
  }

  Color _surfaceColor(
      BuildContext context,
      ) {
    return Theme.of(
      context,
    ).colorScheme.surface;
  }

  Color _textColor(
      BuildContext context,
      ) {
    return Theme.of(
      context,
    ).colorScheme.onSurface;
  }

  Color _mutedColor(
      BuildContext context,
      ) {
    return Theme.of(
      context,
    ).colorScheme.onSurfaceVariant;
  }

  Color _borderColor(
      BuildContext context,
      ) {
    return Theme.of(
      context,
    ).colorScheme.outlineVariant;
  }

  bool _isDarkMode(
      BuildContext context,
      ) {
    return Theme.of(
      context,
    ).brightness ==
        Brightness.dark;
  }

  Color _softPrimaryColor(
      BuildContext context,
      ) {
    return _isDarkMode(
      context,
    )
        ? _primaryColor(
      context,
    ).withValues(
      alpha: 0.16,
    )
        : const Color(
      0xFFE4F0EF,
    );
  }

  Color _softPrimaryBorderColor(
      BuildContext context,
      ) {
    return _isDarkMode(
      context,
    )
        ? _primaryColor(
      context,
    ).withValues(
      alpha: 0.28,
    )
        : const Color(
      0xFFD2E5E2,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final String? currentUserId =
    _currentUserIdOrNull();

    final List<User> providers =
    _repository
        .getProvidersForSkill(
      skill.id,
    )
        .where(
          (
          User provider,
          ) =>
      provider.id.trim().isNotEmpty &&
          provider.id != currentUserId,
    )
        .toList();

    return Scaffold(
      backgroundColor:
      Theme.of(
        context,
      ).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(
              context,
            ),
            Expanded(
              child:
              SingleChildScrollView(
                physics:
                const BouncingScrollPhysics(),
                padding:
                const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _buildSkillHeader(
                      context,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildQuickInfo(
                      context,
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    Text(
                      'About this skill',
                      style:
                      AppTextStyles.cardTitle
                          .copyWith(
                        color:
                        _textColor(
                          context,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      skill.description,
                      style:
                      AppTextStyles.bodyMuted
                          .copyWith(
                        color:
                        _mutedColor(
                          context,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    Text(
                      'What you can learn',
                      style:
                      AppTextStyles.cardTitle
                          .copyWith(
                        color:
                        _textColor(
                          context,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    if (skill.learnings.isEmpty)
                      Text(
                        'No learning topics are listed for this skill yet.',
                        style:
                        AppTextStyles.bodyMuted
                            .copyWith(
                          color:
                          _mutedColor(
                            context,
                          ),
                        ),
                      )
                    else
                      ...skill.learnings.map(
                            (
                            String item,
                            ) {
                          return Padding(
                            padding:
                            const EdgeInsets.only(
                              bottom: 8,
                            ),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin:
                                  const EdgeInsets.only(
                                    top: 2,
                                  ),
                                  width: 20,
                                  height: 20,
                                  decoration:
                                  BoxDecoration(
                                    color:
                                    _softPrimaryColor(
                                      context,
                                    ),
                                    borderRadius:
                                    BorderRadius.circular(
                                      7,
                                    ),
                                    border:
                                    Border.all(
                                      color:
                                      _softPrimaryBorderColor(
                                        context,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color:
                                    _primaryColor(
                                      context,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 9,
                                ),
                                Expanded(
                                  child: Text(
                                    item,
                                    style:
                                    AppTextStyles.secondary
                                        .copyWith(
                                      color:
                                      _textColor(
                                        context,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildPrerequisiteCard(
                      context,
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    _buildProviderHeader(
                      context,
                      providerCount:
                      providers.length,
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      'Choose someone based on their profile, experience, and listed learning interests.',
                      style:
                      AppTextStyles.secondary
                          .copyWith(
                        color:
                        _mutedColor(
                          context,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    if (providers.isEmpty)
                      _buildNoProviders(
                        context,
                      )
                    else
                      ...providers.map(
                            (
                            User provider,
                            ) {
                          return Padding(
                            padding:
                            const EdgeInsets.only(
                              bottom: 14,
                            ),
                            child:
                            _buildProviderCard(
                              context,
                              provider,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? _currentUserIdOrNull() {
    try {
      final String userId =
      _currentUserService
          .requireUserId()
          .trim();

      if (userId.isEmpty) {
        return null;
      }

      return userId;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(
      BuildContext context,
      ) {
    return Container(
      height: 62,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration:
      BoxDecoration(
        color:
        _surfaceColor(
          context,
        ),
        border:
        Border(
          bottom:
          BorderSide(
            color:
            _borderColor(
              context,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip:
            'Back',
            onPressed:
                () {
              Navigator.pop(
                context,
              );
            },
            icon:
            Icon(
              Icons
                  .arrow_back_ios_new_rounded,
              size: 18,
              color:
              _primaryColor(
                context,
              ),
            ),
          ),

          Expanded(
            child:
            Center(
              child:
              Text(
                'Skill Details',
                style:
                AppTextStyles.cardTitle
                    .copyWith(
                  color:
                  _textColor(
                    context,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 48,
            height: 48,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SKILL HEADER
  // ============================================================

  Widget _buildSkillHeader(
      BuildContext context,
      ) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        16,
        16,
        10,
        16,
      ),
      decoration:
      BoxDecoration(
        color:
        _softPrimaryColor(
          context,
        ),
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color:
          _softPrimaryBorderColor(
            context,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration:
            BoxDecoration(
              color:
              _surfaceColor(
                context,
              ),
              borderRadius:
              BorderRadius.circular(
                16,
              ),
              border:
              Border.all(
                color:
                _borderColor(
                  context,
                ),
              ),
            ),
            child:
            Icon(
              skill.icon,
              color:
              _primaryColor(
                context,
              ),
              size: 30,
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  skill.title,
                  style:
                  AppTextStyles.sectionTitle
                      .copyWith(
                    color:
                    _textColor(
                      context,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  skill.category,
                  style:
                  AppTextStyles.secondary
                      .copyWith(
                    color:
                    _mutedColor(
                      context,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    _surfaceColor(
                      context,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                    border:
                    Border.all(
                      color:
                      _borderColor(
                        context,
                      ),
                    ),
                  ),
                  child:
                  Text(
                    skill.level,
                    style:
                    AppTextStyles.caption
                        .copyWith(
                      color:
                      _primaryColor(
                        context,
                      ),
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Image.asset(
            'assets/images/mascot/tubi_explaining.png',
            width: 70,
            height: 70,
            fit:
            BoxFit.contain,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK INFO
  // ============================================================

  Widget _buildQuickInfo(
      BuildContext context,
      ) {
    return Row(
      children: [
        Expanded(
          child:
          _infoBox(
            context:
            context,
            icon:
            Icons.schedule_outlined,
            label:
            'Session',
            value:
            skill.sessionLength,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child:
          _infoBox(
            context:
            context,
            icon:
            Icons.language_rounded,
            label:
            'Language',
            value:
            skill.language,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child:
          _infoBox(
            context:
            context,
            icon:
            Icons.laptop_mac_rounded,
            label:
            'Mode',
            value:
            skill.mode,
          ),
        ),
      ],
    );
  }

  Widget _infoBox({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final String displayValue =
    value.trim().isEmpty
        ? 'Not listed'
        : value.trim();

    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 13,
        horizontal: 8,
      ),
      decoration:
      BoxDecoration(
        color:
        _surfaceColor(
          context,
        ),
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border:
        Border.all(
          color:
          _borderColor(
            context,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color:
            _primaryColor(
              context,
            ),
            size: 19,
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            label,
            style:
            AppTextStyles.caption
                .copyWith(
              color:
              _mutedColor(
                context,
              ),
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            displayValue,
            maxLines: 2,
            textAlign:
            TextAlign.center,
            overflow:
            TextOverflow.ellipsis,
            style:
            AppTextStyles.caption
                .copyWith(
              color:
              _textColor(
                context,
              ),
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PREREQUISITE
  // ============================================================

  Widget _buildPrerequisiteCard(
      BuildContext context,
      ) {
    final String prerequisite =
    skill.prerequisite
        .trim()
        .isEmpty
        ? 'No prerequisite listed.'
        : skill.prerequisite
        .trim();

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
        _isDarkMode(
          context,
        )
            ? const Color(
          0xFF3B2B1F,
        )
            : const Color(
          0xFFFFF6E8,
        ),
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border:
        Border.all(
          color:
          _isDarkMode(
            context,
          )
              ? const Color(
            0xFF5B4632,
          )
              : const Color(
            0xFFF2D1A6,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color:
            AppTheme.accent,
            size: 19,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'What you need',
                  style:
                  AppTextStyles.secondary
                      .copyWith(
                    color:
                    _textColor(
                      context,
                    ),
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  prerequisite,
                  style:
                  AppTextStyles.secondary
                      .copyWith(
                    color:
                    _mutedColor(
                      context,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROVIDER HEADER
  // ============================================================

  Widget _buildProviderHeader(
      BuildContext context, {
        required int providerCount,
      }) {
    final String providerLabel =
    providerCount == 1
        ? '1 provider'
        : '$providerCount providers';

    return Row(
      children: [
        Expanded(
          child:
          Text(
            'People offering this skill',
            style:
            AppTextStyles.cardTitle
                .copyWith(
              color:
              _textColor(
                context,
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Text(
          providerLabel,
          style:
          AppTextStyles.caption
              .copyWith(
            color:
            _mutedColor(
              context,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROVIDER CARD
  // ============================================================

  Widget _buildProviderCard(
      BuildContext context,
      User provider,
      ) {
    final UserSkill? offeredRelationship =
    _repository.findUserSkill(
      userId:
      provider.id,
      skillId:
      skill.id,
      type:
      UserSkillType.offered,
    );

    final List<String> wantedSkillTitles =
    _getWantedSkillTitles(
      provider.id,
    );

    final String learningInterest =
    _buildLearningInterestText(
      wantedSkillTitles,
    );

    final String providerLevel =
    offeredRelationship
        ?.level
        .trim()
        .isNotEmpty ==
        true
        ? offeredRelationship!.level.trim()
        : skill.level.trim().isEmpty
        ? 'Level not listed'
        : skill.level.trim();

    final bool hasReviews =
        provider.reviewCount > 0;

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
        _surfaceColor(
          context,
        ),
        borderRadius:
        BorderRadius.circular(
          17,
        ),
        border:
        Border.all(
          color:
          _borderColor(
            context,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProviderAvatar(
                provider,
                size: 48,
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      AppTextStyles.cardTitle
                          .copyWith(
                        color:
                        _textColor(
                          context,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      '${provider.city} • $providerLevel',
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      AppTextStyles.caption
                          .copyWith(
                        color:
                        _mutedColor(
                          context,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              _buildProviderRating(
                context,
                provider,
                hasReviews:
                hasReviews,
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          _buildProviderInfoRow(
            context,
            icon:
            Icons.swap_horiz_rounded,
            text:
            '${provider.completedSwaps} completed skill swap${provider.completedSwaps == 1 ? '' : 's'}',
          ),

          const SizedBox(
            height: 7,
          ),

          _buildProviderInfoRow(
            context,
            icon:
            Icons.school_outlined,
            text:
            learningInterest,
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              Expanded(
                child:
                SizedBox(
                  height: 40,
                  child:
                  OutlinedButton(
                    onPressed:
                        () {
                      _openProfile(
                        context,
                        provider,
                      );
                    },
                    child:
                    const Text(
                      'VIEW PROFILE',
                      style:
                      AppTextStyles.button,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child:
                SizedBox(
                  height: 40,
                  child:
                  ElevatedButton(
                    onPressed:
                        () {
                      _openSwapRequest(
                        context,
                        provider,
                      );
                    },
                    child:
                    const Text(
                      'REQUEST SWAP',
                      style:
                      AppTextStyles.button,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderRating(
      BuildContext context,
      User provider, {
        required bool hasReviews,
      }) {
    if (!hasReviews) {
      return Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        decoration:
        BoxDecoration(
          color:
          _softPrimaryColor(
            context,
          ),
          borderRadius:
          BorderRadius.circular(
            14,
          ),
        ),
        child:
        Row(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons.star_border_rounded,
              size: 15,
              color:
              _mutedColor(
                context,
              ),
            ),
            const SizedBox(
              width: 3,
            ),
            Text(
              'No reviews',
              style:
              AppTextStyles.caption
                  .copyWith(
                color:
                _mutedColor(
                  context,
                ),
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
      BoxDecoration(
        color:
        _softPrimaryColor(
          context,
        ),
        borderRadius:
        BorderRadius.circular(
          14,
        ),
      ),
      child:
      Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 15,
            color:
            AppTheme.accent,
          ),
          const SizedBox(
            width: 3,
          ),
          Text(
            provider.rating
                .toStringAsFixed(
              1,
            ),
            style:
            AppTextStyles.caption
                .copyWith(
              color:
              _textColor(
                context,
              ),
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(
            width: 3,
          ),
          Text(
            '(${provider.reviewCount})',
            style:
            AppTextStyles.caption
                .copyWith(
              color:
              _mutedColor(
                context,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderInfoRow(
      BuildContext context, {
        required IconData icon,
        required String text,
      }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color:
          _primaryColor(
            context,
          ),
        ),

        const SizedBox(
          width: 6,
        ),

        Expanded(
          child:
          Text(
            text,
            maxLines: 2,
            overflow:
            TextOverflow.ellipsis,
            style:
            AppTextStyles.secondary
                .copyWith(
              color:
              _textColor(
                context,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _buildLearningInterestText(
      List<String> wantedSkillTitles,
      ) {
    if (wantedSkillTitles.isEmpty) {
      return 'No learning interests listed';
    }

    if (wantedSkillTitles.length == 1) {
      return 'Wants to learn: ${wantedSkillTitles.first}';
    }

    final int remaining =
        wantedSkillTitles.length - 1;

    return 'Wants to learn: '
        '${wantedSkillTitles.first} '
        '+ $remaining more';
  }

  // ============================================================
  // PROVIDER AVATAR
  // ============================================================

  Widget _buildProviderAvatar(
      User provider, {
        required double size,
      }) {
    final String? path =
    provider.profileImagePath?.trim();

    final bool hasImage =
        path != null &&
            path.isNotEmpty &&
            _profileImageExists(
              path,
            );

    return ClipOval(
      child:
      SizedBox(
        width:
        size,
        height:
        size,
        child:
        hasImage
            ? Image.file(
          File(
            path,
          ),
          width:
          size,
          height:
          size,
          fit:
          BoxFit.cover,
          errorBuilder:
              (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
              ) {
            return _buildInitialAvatar(
              provider,
              size:
              size,
            );
          },
        )
            : _buildInitialAvatar(
          provider,
          size:
          size,
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(
      User provider, {
        required double size,
      }) {
    final String initials =
    provider.initials
        .trim()
        .isEmpty
        ? '?'
        : provider.initials
        .trim();

    return Container(
      width:
      size,
      height:
      size,
      color:
      AppTheme.accent,
      alignment:
      Alignment.center,
      child:
      Text(
        initials,
        style:
        TextStyle(
          fontSize:
          size >= 48
              ? 12
              : 11,
          fontWeight:
          FontWeight.w800,
          color:
          Colors.white,
        ),
      ),
    );
  }

  bool _profileImageExists(
      String path,
      ) {
    try {
      return File(
        path,
      ).existsSync();
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // WANTED SKILLS
  // ============================================================

  List<String> _getWantedSkillTitles(
      String userId,
      ) {
    final Set<String> seenTitles =
    <String>{};

    final List<String> titles =
    <String>[];

    for (final UserSkill relationship
    in _repository.getWantedSkillsForUser(
      userId,
    )) {
      final Skill? wantedSkill =
      _repository.findSkillById(
        relationship.skillId,
      );

      if (wantedSkill == null) {
        continue;
      }

      final String title =
      wantedSkill.title.trim();

      if (title.isEmpty) {
        continue;
      }

      final String normalized =
      title.toLowerCase();

      if (!seenTitles.add(
        normalized,
      )) {
        continue;
      }

      titles.add(
        title,
      );
    }

    titles.sort(
          (
          String first,
          String second,
          ) =>
          first
              .toLowerCase()
              .compareTo(
            second.toLowerCase(),
          ),
    );

    return titles;
  }

  // ============================================================
  // OPEN PROFILE
  // ============================================================

  void _openProfile(
      BuildContext context,
      User provider,
      ) {
    Navigator.pushNamed(
      context,
      '/user-profile',
      arguments:
      provider,
    );
  }

  // ============================================================
  // OPEN SWAP REQUEST
  // ============================================================

  Future<void> _openSwapRequest(
      BuildContext context,
      User provider,
      ) async {
    final String? currentUserId =
    _currentUserIdOrNull();

    if (currentUserId == null) {
      _showMessage(
        context,
        'Current user identity is unavailable.',
      );
      return;
    }

    if (provider.id ==
        currentUserId) {
      _showMessage(
        context,
        'You cannot request a skill swap with yourself.',
      );
      return;
    }

    final bool stillOffersSkill =
    _repository
        .getOfferedSkillsForUser(
      provider.id,
    )
        .any(
          (
          UserSkill relationship,
          ) =>
      relationship.skillId ==
          skill.id,
    );

    if (!stillOffersSkill) {
      _showMessage(
        context,
        '${provider.name} no longer offers this skill.',
      );
      return;
    }

    final bool? requestCreated =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (
            BuildContext routeContext,
            ) =>
            CreateSwapRequestScreen(
              providerUserId:
              provider.id,
              skillToLearnId:
              skill.id,
              providerName:
              provider.name,
              providerInitials:
              provider.initials,
              providerCity:
              provider.city,
              skillToLearn:
              skill.title,
            ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    if (requestCreated ==
        true) {
      _showMessage(
        context,
        'Your request to ${provider.name} is now Pending.',
      );
    }
  }

  // ============================================================
  // NO PROVIDERS
  // ============================================================

  Widget _buildNoProviders(
      BuildContext context,
      ) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        18,
      ),
      decoration:
      BoxDecoration(
        color:
        _surfaceColor(
          context,
        ),
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border:
        Border.all(
          color:
          _borderColor(
            context,
          ),
        ),
      ),
      child:
      Column(
        children: [
          Icon(
            Icons
                .person_search_outlined,
            size: 28,
            color:
            _mutedColor(
              context,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'No other providers listed',
            style:
            AppTextStyles.cardTitle
                .copyWith(
              color:
              _textColor(
                context,
              ),
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'No other learner is currently listed as offering this skill.',
            textAlign:
            TextAlign.center,
            style:
            AppTextStyles.bodyMuted
                .copyWith(
              color:
              _mutedColor(
                context,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FEEDBACK
  // ============================================================

  void _showMessage(
      BuildContext context,
      String message,
      ) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
          Text(
            message,
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }
}