import 'package:flutter/material.dart';

import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/user.dart';
import '../model/user_skill.dart';
import '../theme/app_theme.dart';
import 'create_swap_request_screen.dart';

class SkillDetailsScreen extends StatelessWidget {
  final Skill skill;

  const SkillDetailsScreen({
    super.key,
    required this.skill,
  });

  static final ExploreRepository _repository =
  ExploreRepository();

  Color _primaryColor(
      BuildContext context,
      ) =>
      Theme.of(context).colorScheme.primary;

  Color _surfaceColor(
      BuildContext context,
      ) =>
      Theme.of(context).colorScheme.surface;

  Color _textColor(
      BuildContext context,
      ) =>
      Theme.of(context).colorScheme.onSurface;

  Color _mutedColor(
      BuildContext context,
      ) =>
      Theme.of(context)
          .colorScheme
          .onSurfaceVariant;

  Color _borderColor(
      BuildContext context,
      ) =>
      Theme.of(context)
          .colorScheme
          .outlineVariant;

  bool _isDarkMode(
      BuildContext context,
      ) =>
      Theme.of(context).brightness ==
          Brightness.dark;

  Color _softPrimaryColor(
      BuildContext context,
      ) =>
      _isDarkMode(
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

  Color _softPrimaryBorderColor(
      BuildContext context,
      ) =>
      _isDarkMode(
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

  @override
  Widget build(
      BuildContext context,
      ) {
    final List<User> providers =
    _repository.getProvidersForSkill(
      skill.id,
    );

    return Scaffold(
      backgroundColor:
      Theme.of(context)
          .scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(
              context,
            ),
            Expanded(
              child: SingleChildScrollView(
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
                    ...skill.learnings.map(
                          (
                          String item,
                          ) =>
                          Padding(
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
                          ),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
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
                        Text(
                          '${providers.length} available',
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
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      'Choose someone based on availability, experience, and what they want to learn in exchange.',
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
                            ) =>
                            Padding(
                              padding:
                              const EdgeInsets.only(
                                bottom: 14,
                              ),
                              child:
                              _buildProviderCard(
                                context,
                                provider,
                              ),
                            ),
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
            onPressed: () {
              Navigator.pop(
                context,
              );
            },
            icon: Icon(
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
            child: Center(
              child: Text(
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
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.favorite_border_rounded,
              size: 20,
              color:
              _primaryColor(
                context,
              ),
            ),
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
      width: double.infinity,
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
            child: Icon(
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
            child: Column(
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
                  child: Text(
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
            fit: BoxFit.contain,
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
          child: _infoBox(
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
          child: _infoBox(
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
          child: _infoBox(
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
            value,
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
    return Container(
      width: double.infinity,
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
            child: Column(
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
                  skill.prerequisite,
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

    final String wantsToLearn =
    wantedSkillTitles.isEmpty
        ? 'Open to learning'
        : wantedSkillTitles.first;

    return Container(
      width: double.infinity,
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
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
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
                  provider.initials,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Colors.white,
                  ),
                ),
              ),
              const SizedBox(
                width: 11,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
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
                      '${provider.city} • ${offeredRelationship?.level ?? skill.level}',
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
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
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
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
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
                child: Text(
                  '${provider.completedSwaps} completed skill swaps',
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
          const SizedBox(
            height: 7,
          ),
          Row(
            children: [
              Icon(
                Icons.school_outlined,
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
                child: Text(
                  'Wants to learn: $wantsToLearn',
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
          const SizedBox(
            height: 14,
          ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child:
                  OutlinedButton(
                    onPressed: () {
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
                child: SizedBox(
                  height: 40,
                  child:
                  ElevatedButton(
                    onPressed: () {
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

  // ============================================================
  // WANTED SKILL TITLES
  // ============================================================

  List<String> _getWantedSkillTitles(
      String userId,
      ) {
    return _repository
        .getWantedSkillsForUser(
      userId,
    )
        .map(
          (
          UserSkill relationship,
          ) =>
      _repository
          .findSkillById(
        relationship.skillId,
      )
          ?.title,
    )
        .whereType<String>()
        .toList();
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

    if (requestCreated == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
          Text(
            'Your request to ${provider.name} is now Pending.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
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
      width: double.infinity,
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
      child: Text(
        'No providers are currently available for this skill.',
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
    );
  }
}