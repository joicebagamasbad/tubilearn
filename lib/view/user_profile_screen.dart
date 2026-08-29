import 'package:flutter/material.dart';

import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/user.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import 'create_swap_request_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final User user;

  const UserProfileScreen({
    super.key,
    required this.user,
  });

  static const Color primary = AppTheme.primary;
  static const Color darkText = AppTheme.darkText;
  static const Color mutedText = AppTheme.mutedText;
  static const Color background = AppTheme.background;
  static const Color border = AppTheme.border;

  static final ExploreRepository _repository =
  ExploreRepository();

  @override
  Widget build(
      BuildContext context,
      ) {
    final List<Skill> offeredSkills =
    _getOfferedSkills();

    final List<Skill> wantedSkills =
    _getWantedSkills();

    return Scaffold(
      backgroundColor: background,
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
                    _buildProfileHeader(),

                    const SizedBox(
                      height: 22,
                    ),

                    _buildStatsRow(),

                    const SizedBox(
                      height: 24,
                    ),

                    const Text(
                      'About',
                      style:
                      AppTextStyles.cardTitle,
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      user.bio,
                      style:
                      AppTextStyles.bodyMuted,
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    _buildInfoCard(),

                    const SizedBox(
                      height: 24,
                    ),

                    const Text(
                      'Skills offered',
                      style:
                      AppTextStyles.cardTitle,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    if (offeredSkills.isEmpty)
                      const Text(
                        'No offered skills yet.',
                        style:
                        AppTextStyles.bodyMuted,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                        offeredSkills.map(
                              (
                              skill,
                              ) {
                            return _skillChip(
                              skill.title,
                              const Color(
                                0xFFF0EFFF,
                              ),
                              primary,
                            );
                          },
                        ).toList(),
                      ),

                    const SizedBox(
                      height: 24,
                    ),

                    const Text(
                      'Wants to learn',
                      style:
                      AppTextStyles.cardTitle,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    if (wantedSkills.isEmpty)
                      const Text(
                        'No learning interests yet.',
                        style:
                        AppTextStyles.bodyMuted,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                        wantedSkills.map(
                              (
                              skill,
                              ) {
                            return _skillChip(
                              skill.title,
                              const Color(
                                0xFFFFF4E8,
                              ),
                              const Color(
                                0xFFCA7A1B,
                              ),
                            );
                          },
                        ).toList(),
                      ),

                    const SizedBox(
                      height: 24,
                    ),

                    _buildTrustCard(),

                    const SizedBox(
                      height: 26,
                    ),

                    _buildActionButtons(
                      context,
                      offeredSkills,
                      wantedSkills,
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
      const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: border,
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
            icon: const Icon(
              Icons
                  .arrow_back_ios_new_rounded,
              size: 18,
              color: primary,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Profile',
                style:
                AppTextStyles.cardTitle,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration:
          const BoxDecoration(
            color:
            Color(
              0xFFFFB45E,
            ),
            shape:
            BoxShape.circle,
          ),
          alignment:
          Alignment.center,
          child: Text(
            user.initials,
            style:
            const TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.w800,
              color:
              Colors.white,
            ),
          ),
        ),
        const SizedBox(
          width: 16,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style:
                AppTextStyles.pageTitle,
              ),
              const SizedBox(
                height: 4,
              ),
              Row(
                children: [
                  const Icon(
                    Icons
                        .location_on_outlined,
                    size: 15,
                    color: mutedText,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Expanded(
                    child: Text(
                      user.city,
                      style:
                      AppTextStyles.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 17,
                    color:
                    Color(
                      0xFFFFB547,
                    ),
                  ),
                  const SizedBox(
                    width: 3,
                  ),
                  Text(
                    user.rating
                        .toStringAsFixed(
                      1,
                    ),
                    style:
                    AppTextStyles.secondary
                        .copyWith(
                      color: darkText,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(
                    '(${user.reviewCount} reviews)',
                    style:
                    AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
        Image.asset(
          'assets/images/mascot/tubi_happy.png',
          width: 58,
          height: 58,
        ),
      ],
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statBox(
            '${user.completedSwaps}',
            'Completed swaps',
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _statBox(
            '${user.responseRate}%',
            'Response rate',
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _statBox(
            user.memberSince,
            'Member since',
          ),
        ),
      ],
    );
  }

  Widget _statBox(
      String value,
      String label,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: border,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style:
            AppTextStyles.cardTitle,
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            label,
            textAlign:
            TextAlign.center,
            style:
            AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _buildInfoCard() {
    return Container(
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: border,
        ),
      ),
      child: Column(
        children: [
          _infoRow(
            Icons.language_rounded,
            'Languages',
            user.language,
          ),
          const Divider(
            height: 22,
            color: border,
          ),
          _infoRow(
            Icons.schedule_rounded,
            'Availability',
            user.availability,
          ),
          const Divider(
            height: 22,
            color: border,
          ),
          _infoRow(
            Icons.devices_rounded,
            'Preferred mode',
            user.preferredMode,
          ),
          const Divider(
            height: 22,
            color: border,
          ),
          _infoRow(
            Icons.school_outlined,
            'Teaching style',
            user.teachingStyle,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: primary,
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
                AppTextStyles.caption,
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                value,
                style:
                AppTextStyles.secondary
                    .copyWith(
                  color: darkText,
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

  // ============================================================
  // SKILL CHIP
  // ============================================================

  Widget _skillChip(
      String skill,
      Color backgroundColor,
      Color textColor,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration:
      BoxDecoration(
        color:
        backgroundColor,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        skill,
        style:
        AppTextStyles.secondary
            .copyWith(
          color:
          textColor,
          fontWeight:
          FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // TRUST CARD
  // ============================================================

  Widget _buildTrustCard() {
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
        const Color(
          0xFFF3FBF6,
        ),
        borderRadius:
        BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color:
          const Color(
            0xFFD9F0E0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'Profile & trust',
            style:
            AppTextStyles.cardTitle
                .copyWith(
              fontSize:
              14,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          if (user.emailVerified)
            _trustRow(
              'Email verified',
            ),
          if (user.emailVerified)
            const SizedBox(
              height: 7,
            ),
          if (user.profileCompleted)
            _trustRow(
              'Profile completed',
            ),
          if (user.profileCompleted)
            const SizedBox(
              height: 7,
            ),
          _trustRow(
            '${user.completedSwaps} completed exchanges',
          ),
        ],
      ),
    );
  }

  Widget _trustRow(
      String text,
      ) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 16,
          color:
          Color(
            0xFF47A568,
          ),
        ),
        const SizedBox(
          width: 7,
        ),
        Expanded(
          child: Text(
            text,
            style:
            AppTextStyles.secondary
                .copyWith(
              color:
              darkText,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SKILL RELATIONSHIPS
  // ============================================================

  List<Skill> _getOfferedSkills() {
    return _repository
        .getOfferedSkillsForUser(
      user.id,
    )
        .map(
          (
          relationship,
          ) =>
          _repository
              .findSkillById(
            relationship.skillId,
          ),
    )
        .whereType<Skill>()
        .toList();
  }

  List<Skill> _getWantedSkills() {
    return _repository
        .getWantedSkillsForUser(
      user.id,
    )
        .map(
          (
          relationship,
          ) =>
          _repository
              .findSkillById(
            relationship.skillId,
          ),
    )
        .whereType<Skill>()
        .toList();
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons(
      BuildContext context,
      List<Skill> offeredSkills,
      List<Skill> wantedSkills,
      ) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child:
            OutlinedButton.icon(
              onPressed: () {
                _openConversation(
                  context,
                  offeredSkills,
                  wantedSkills,
                );
              },
              icon: const Icon(
                Icons
                    .chat_bubble_outline_rounded,
                size: 16,
              ),
              label:
              const Text(
                'MESSAGE',
                style:
                AppTextStyles.button,
              ),
              style:
              OutlinedButton
                  .styleFrom(
                foregroundColor:
                primary,
                side:
                const BorderSide(
                  color:
                  primary,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: SizedBox(
            height: 46,
            child:
            ElevatedButton.icon(
              onPressed: () {
                _openSwapRequest(
                  context,
                  offeredSkills,
                );
              },
              icon: const Icon(
                Icons
                    .swap_horiz_rounded,
                size: 17,
              ),
              label:
              const Text(
                'REQUEST SWAP',
                style:
                AppTextStyles.button,
              ),
              style:
              ElevatedButton
                  .styleFrom(
                backgroundColor:
                primary,
                foregroundColor:
                Colors.white,
                elevation: 0,
                minimumSize:
                const Size(
                  0,
                  46,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  Future<void> _openConversation(
      BuildContext context,
      List<Skill> offeredSkills,
      List<Skill> wantedSkills,
      ) async {
    try {
      final conversation =
      await ChatService.instance
          .getOrCreateConversation(
        userId:
        user.id,
        userName:
        user.name,
        initials:
        user.initials,
        city:
        user.city,
        skillWanted:
        offeredSkills.isEmpty
            ? 'Skill'
            : offeredSkills.first.title,
        skillOffered:
        wantedSkills.isEmpty
            ? 'Skill'
            : wantedSkills.first.title,
      );

      if (!context.mounted) {
        return;
      }

      Navigator.pushNamed(
        context,
        '/conversation',
        arguments:
        conversation.id,
      );
    } on ChatServiceException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
          Text(
            error.message,
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // CREATE SWAP REQUEST
  // ============================================================

  Future<void> _openSwapRequest(
      BuildContext context,
      List<Skill> offeredSkills,
      ) async {
    if (offeredSkills.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'This user has no offered skill available for swap.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final Skill skillToLearn =
        offeredSkills.first;

    final bool? requestCreated =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateSwapRequestScreen(
              providerUserId:
              user.id,
              skillToLearnId:
              skillToLearn.id,
              providerName:
              user.name,
              providerInitials:
              user.initials,
              providerCity:
              user.city,
              skillToLearn:
              skillToLearn.title,
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
          content: Text(
            'Your request to ${user.name} is now Pending.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    }
  }
}