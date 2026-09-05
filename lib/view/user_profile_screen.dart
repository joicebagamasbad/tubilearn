import 'package:flutter/material.dart';

import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/user.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import 'create_swap_request_screen.dart';

enum _PreviousConversationAction {
  cancel,
  restore,
  startNew,
}

class UserProfileScreen extends StatefulWidget {
  final User user;

  const UserProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserProfileScreen> createState() =>
      _UserProfileScreenState();
}

class _UserProfileScreenState
    extends State<UserProfileScreen> {
  static final ExploreRepository _repository =
  ExploreRepository();

  bool _isOpeningConversation = false;
  bool _isOpeningSwapRequest = false;

  User get user =>
      widget.user;

  bool get _hasPendingAction =>
      _isOpeningConversation ||
          _isOpeningSwapRequest;

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

  Color get _wantedBackgroundColor =>
      _isDarkMode
          ? AppTheme.accent.withValues(
        alpha: 0.16,
      )
          : const Color(
        0xFFFFF4E8,
      );

  Color get _wantedTextColor =>
      _isDarkMode
          ? const Color(
        0xFFFFC37B,
      )
          : const Color(
        0xFFB66C18,
      );

  Color get _trustBackgroundColor =>
      _isDarkMode
          ? AppTheme.success.withValues(
        alpha: 0.13,
      )
          : const Color(
        0xFFF2F8F4,
      );

  Color get _trustBorderColor =>
      _isDarkMode
          ? AppTheme.success.withValues(
        alpha: 0.32,
      )
          : const Color(
        0xFFD4E8DB,
      );

  Color get _primaryForeground =>
      _isDarkMode
          ? const Color(
        0xFF092E31,
      )
          : Colors.white;

  @override
  Widget build(
      BuildContext context,
      ) {
    final List<Skill> offeredSkills =
    _getOfferedSkills();

    final List<Skill> wantedSkills =
    _getWantedSkills();

    return Scaffold(
      backgroundColor:
      Theme.of(context)
          .scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
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
                    _buildProfileHeader(),

                    const SizedBox(
                      height: 22,
                    ),

                    _buildStatsRow(),

                    const SizedBox(
                      height: 24,
                    ),

                    Text(
                      'About',
                      style:
                      AppTextStyles.cardTitle
                          .copyWith(
                        color:
                        _textColor,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      user.bio,
                      style:
                      AppTextStyles.bodyMuted
                          .copyWith(
                        color:
                        _mutedColor,
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    _buildInfoCard(),

                    const SizedBox(
                      height: 24,
                    ),

                    Text(
                      'Skills offered',
                      style:
                      AppTextStyles.cardTitle
                          .copyWith(
                        color:
                        _textColor,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    if (offeredSkills.isEmpty)
                      Text(
                        'No offered skills yet.',
                        style:
                        AppTextStyles.bodyMuted
                            .copyWith(
                          color:
                          _mutedColor,
                        ),
                      )
                    else
                      Wrap(
                        spacing:
                        8,
                        runSpacing:
                        8,
                        children:
                        offeredSkills.map(
                              (
                              Skill skill,
                              ) {
                            return _skillChip(
                              skill.title,
                              _softPrimaryColor,
                              _primaryColor,
                            );
                          },
                        ).toList(),
                      ),

                    const SizedBox(
                      height: 24,
                    ),

                    Text(
                      'Wants to learn',
                      style:
                      AppTextStyles.cardTitle
                          .copyWith(
                        color:
                        _textColor,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    if (wantedSkills.isEmpty)
                      Text(
                        'No learning interests yet.',
                        style:
                        AppTextStyles.bodyMuted
                            .copyWith(
                          color:
                          _mutedColor,
                        ),
                      )
                    else
                      Wrap(
                        spacing:
                        8,
                        runSpacing:
                        8,
                        children:
                        wantedSkills.map(
                              (
                              Skill skill,
                              ) {
                            return _skillChip(
                              skill.title,
                              _wantedBackgroundColor,
                              _wantedTextColor,
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

  Widget _buildTopBar() {
    return Container(
      height:
      62,
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        10,
      ),
      decoration:
      BoxDecoration(
        color:
        _surfaceColor,
        border:
        Border(
          bottom:
          BorderSide(
            color:
            _borderColor,
          ),
        ),
      ),
      child:
      Row(
        children: [
          IconButton(
            onPressed:
            _hasPendingAction
                ? null
                : () {
              Navigator.pop(
                context,
              );
            },
            icon:
            Icon(
              Icons.arrow_back_ios_new_rounded,
              size:
              18,
              color:
              _hasPendingAction
                  ? _mutedColor
                  : _primaryColor,
            ),
          ),

          Expanded(
            child:
            Center(
              child:
              Text(
                'Profile',
                style:
                AppTextStyles.cardTitle
                    .copyWith(
                  color:
                  _textColor,
                ),
              ),
            ),
          ),

          IconButton(
            onPressed:
            _hasPendingAction
                ? null
                : () {},
            icon:
            Icon(
              Icons.more_horiz_rounded,
              color:
              _mutedColor,
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
          width:
          78,
          height:
          78,
          decoration:
          const BoxDecoration(
            color:
            AppTheme.accent,
            shape:
            BoxShape.circle,
          ),
          alignment:
          Alignment.center,
          child:
          Text(
            user.initials,
            style:
            const TextStyle(
              fontSize:
              20,
              fontWeight:
              FontWeight.w800,
              color:
              Colors.white,
            ),
          ),
        ),

        const SizedBox(
          width:
          16,
        ),

        Expanded(
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style:
                AppTextStyles.pageTitle
                    .copyWith(
                  color:
                  _textColor,
                ),
              ),

              const SizedBox(
                height:
                4,
              ),

              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size:
                    15,
                    color:
                    _mutedColor,
                  ),

                  const SizedBox(
                    width:
                    4,
                  ),

                  Expanded(
                    child:
                    Text(
                      user.city,
                      style:
                      AppTextStyles.secondary
                          .copyWith(
                        color:
                        _mutedColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height:
                8,
              ),

              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size:
                    17,
                    color:
                    AppTheme.accent,
                  ),

                  const SizedBox(
                    width:
                    3,
                  ),

                  Text(
                    user.rating.toStringAsFixed(
                      1,
                    ),
                    style:
                    AppTextStyles.secondary
                        .copyWith(
                      color:
                      _textColor,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    width:
                    5,
                  ),

                  Text(
                    '(${user.reviewCount} reviews)',
                    style:
                    AppTextStyles.caption
                        .copyWith(
                      color:
                      _mutedColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Image.asset(
          'assets/images/mascot/tubi_happy.png',
          width:
          58,
          height:
          58,
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
          child:
          _statBox(
            '${user.completedSwaps}',
            'Completed swaps',
          ),
        ),

        const SizedBox(
          width:
          10,
        ),

        Expanded(
          child:
          _statBox(
            '${user.responseRate}%',
            'Response rate',
          ),
        ),

        const SizedBox(
          width:
          10,
        ),

        Expanded(
          child:
          _statBox(
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
        vertical:
        14,
        horizontal:
        8,
      ),
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
      child:
      Column(
        children: [
          Text(
            value,
            style:
            AppTextStyles.cardTitle
                .copyWith(
              color:
              _textColor,
            ),
          ),

          const SizedBox(
            height:
            4,
          ),

          Text(
            label,
            textAlign:
            TextAlign.center,
            style:
            AppTextStyles.caption
                .copyWith(
              color:
              _mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO
  // ============================================================

  Widget _buildInfoCard() {
    return Container(
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
      child:
      Column(
        children: [
          _infoRow(
            Icons.language_rounded,
            'Languages',
            user.language,
          ),

          Divider(
            height:
            22,
            color:
            _borderColor,
          ),

          _infoRow(
            Icons.schedule_rounded,
            'Availability',
            user.availability,
          ),

          Divider(
            height:
            22,
            color:
            _borderColor,
          ),

          _infoRow(
            Icons.devices_rounded,
            'Preferred mode',
            user.preferredMode,
          ),

          Divider(
            height:
            22,
            color:
            _borderColor,
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
          size:
          18,
          color:
          _primaryColor,
        ),

        const SizedBox(
          width:
          10,
        ),

        Expanded(
          child:
          Column(
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
                ),
              ),

              const SizedBox(
                height:
                3,
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

  // ============================================================
  // SKILLS
  // ============================================================

  Widget _skillChip(
      String skill,
      Color backgroundColor,
      Color textColor,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        11,
        vertical:
        7,
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
      child:
      Text(
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

  List<Skill> _getOfferedSkills() {
    return _repository
        .getOfferedSkillsForUser(
      user.id,
    )
        .map(
          (
          relationship,
          ) =>
          _repository.findSkillById(
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
          _repository.findSkillById(
            relationship.skillId,
          ),
    )
        .whereType<Skill>()
        .toList();
  }

  // ============================================================
  // TRUST
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
        _trustBackgroundColor,
        borderRadius:
        BorderRadius.circular(
          15,
        ),
        border:
        Border.all(
          color:
          _trustBorderColor,
        ),
      ),
      child:
      Column(
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
              color:
              _textColor,
            ),
          ),

          const SizedBox(
            height:
            10,
          ),

          if (user.emailVerified)
            _trustRow(
              'Email verified',
            ),

          if (user.emailVerified)
            const SizedBox(
              height:
              7,
            ),

          if (user.profileCompleted)
            _trustRow(
              'Profile completed',
            ),

          if (user.profileCompleted)
            const SizedBox(
              height:
              7,
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
          size:
          16,
          color:
          AppTheme.success,
        ),

        const SizedBox(
          width:
          7,
        ),

        Expanded(
          child:
          Text(
            text,
            style:
            AppTextStyles.secondary
                .copyWith(
              color:
              _textColor,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons(
      List<Skill> offeredSkills,
      List<Skill> wantedSkills,
      ) {
    return Row(
      children: [
        Expanded(
          child:
          SizedBox(
            height:
            46,
            child:
            OutlinedButton.icon(
              onPressed:
              _hasPendingAction
                  ? null
                  : () {
                _openConversation(
                  offeredSkills,
                  wantedSkills,
                );
              },
              icon:
              _isOpeningConversation
                  ? SizedBox(
                width:
                16,
                height:
                16,
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2,
                  color:
                  _primaryColor,
                ),
              )
                  : const Icon(
                Icons.chat_bubble_outline_rounded,
                size:
                16,
              ),
              label:
              Text(
                _isOpeningConversation
                    ? 'OPENING...'
                    : 'MESSAGE',
                style:
                AppTextStyles.button,
              ),
              style:
              OutlinedButton.styleFrom(
                foregroundColor:
                _primaryColor,
                disabledForegroundColor:
                _mutedColor,
                side:
                BorderSide(
                  color:
                  _hasPendingAction
                      ? _borderColor
                      : _primaryColor,
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
          width:
          10,
        ),

        Expanded(
          child:
          SizedBox(
            height:
            46,
            child:
            ElevatedButton.icon(
              onPressed:
              _hasPendingAction
                  ? null
                  : () {
                _openSwapRequest(
                  offeredSkills,
                );
              },
              icon:
              _isOpeningSwapRequest
                  ? SizedBox(
                width:
                16,
                height:
                16,
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2,
                  color:
                  _primaryForeground,
                ),
              )
                  : const Icon(
                Icons.swap_horiz_rounded,
                size:
                17,
              ),
              label:
              Text(
                _isOpeningSwapRequest
                    ? 'OPENING...'
                    : 'REQUEST SWAP',
                style:
                AppTextStyles.button,
              ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                _primaryColor,
                foregroundColor:
                _primaryForeground,
                disabledBackgroundColor:
                _surfaceVariantColor,
                disabledForegroundColor:
                _mutedColor,
                elevation:
                0,
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
      List<Skill> offeredSkills,
      List<Skill> wantedSkills,
      ) async {
    if (_hasPendingAction) {
      return;
    }

    setState(() {
      _isOpeningConversation =
      true;
    });

    final String skillWanted =
    offeredSkills.isEmpty
        ? 'Skill'
        : offeredSkills.first.title;

    final String skillOffered =
    wantedSkills.isEmpty
        ? 'Skill'
        : wantedSkills.first.title;

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
        skillWanted,
        skillOffered:
        skillOffered,
      );

      if (!mounted) {
        return;
      }

      await _openConversationRoute(
        conversation.id,
      );
    } on HiddenConversationException catch (error) {
      if (!mounted) {
        return;
      }

      final _PreviousConversationAction action =
      await _showPreviousConversationDialog();

      if (!mounted) {
        return;
      }

      switch (action) {
        case _PreviousConversationAction.cancel:
          return;

        case _PreviousConversationAction.restore:
          await _restoreConversation(
            error.conversationId,
          );
          return;

        case _PreviousConversationAction.startNew:
          await _startNewConversation(
            skillWanted:
            skillWanted,
            skillOffered:
            skillOffered,
          );
          return;
      }
    } on ChatServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Conversation could not be opened. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningConversation =
          false;
        });
      }
    }
  }

  // ============================================================
  // RESTORE OLD CHAT
  // ============================================================

  Future<void> _restoreConversation(
      String conversationId,
      ) async {
    try {
      final conversation =
      await ChatService.instance
          .restoreConversation(
        conversationId,
      );

      if (!mounted) {
        return;
      }

      await _openConversationRoute(
        conversation.id,
      );
    } on ChatServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Conversation could not be restored. Please try again.',
      );
    }
  }

  // ============================================================
  // START NEW CHAT
  // ============================================================

  Future<void> _startNewConversation({
    required String skillWanted,
    required String skillOffered,
  }) async {
    try {
      final conversation =
      await ChatService.instance
          .startNewConversation(
        userId:
        user.id,
        userName:
        user.name,
        initials:
        user.initials,
        city:
        user.city,
        skillWanted:
        skillWanted,
        skillOffered:
        skillOffered,
      );

      if (!mounted) {
        return;
      }

      await _openConversationRoute(
        conversation.id,
      );
    } on ChatServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'A new conversation could not be created. Please try again.',
      );
    }
  }

  Future<void> _openConversationRoute(
      String conversationId,
      ) async {
    if (!mounted) {
      return;
    }

    await Navigator.pushNamed(
      context,
      '/conversation',
      arguments:
      conversationId,
    );
  }

  // ============================================================
  // PREVIOUS CONVERSATION DIALOG
  // ============================================================

  Future<_PreviousConversationAction>
  _showPreviousConversationDialog() async {
    if (!mounted) {
      return _PreviousConversationAction.cancel;
    }

    final _PreviousConversationAction? result =
    await showDialog<
        _PreviousConversationAction>(
      context:
      context,
      barrierDismissible:
      false,
      builder:
          (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          _surfaceColor,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
          ),
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
                  shape:
                  BoxShape.circle,
                ),
                child:
                Icon(
                  Icons.history_rounded,
                  color:
                  _primaryColor,
                  size:
                  21,
                ),
              ),

              const SizedBox(
                width:
                12,
              ),

              Expanded(
                child:
                Text(
                  'Previous chat found',
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
          Text(
            'You previously removed your conversation with ${user.name}. '
                'You can restore that chat and its messages, or start a fresh conversation.',
            style:
            AppTextStyles.bodyMuted
                .copyWith(
              color:
              _mutedColor,
            ),
          ),
          actionsPadding:
          const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            14,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  _PreviousConversationAction.cancel,
                );
              },
              child:
              Text(
                'CANCEL',
                style:
                AppTextStyles.button
                    .copyWith(
                  color:
                  _mutedColor,
                ),
              ),
            ),

            TextButton.icon(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  _PreviousConversationAction.restore,
                );
              },
              icon:
              const Icon(
                Icons.restore_rounded,
                size:
                17,
              ),
              label:
              const Text(
                'RESTORE',
                style:
                AppTextStyles.button,
              ),
              style:
              TextButton.styleFrom(
                foregroundColor:
                _primaryColor,
              ),
            ),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  _PreviousConversationAction.startNew,
                );
              },
              icon:
              const Icon(
                Icons.add_comment_outlined,
                size:
                17,
              ),
              label:
              const Text(
                'NEW CHAT',
                style:
                AppTextStyles.button,
              ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                _primaryColor,
                foregroundColor:
                _primaryForeground,
                elevation:
                0,
                minimumSize:
                const Size(
                  0,
                  42,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    11,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ??
        _PreviousConversationAction.cancel;
  }

  // ============================================================
  // MESSAGE FEEDBACK
  // ============================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) {
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

  // ============================================================
  // SWAP REQUEST
  // ============================================================

  Future<void> _openSwapRequest(
      List<Skill> offeredSkills,
      ) async {
    if (_hasPendingAction) {
      return;
    }

    if (offeredSkills.isEmpty) {
      _showMessage(
        'This user has no offered skill available for swap.',
      );

      return;
    }

    setState(() {
      _isOpeningSwapRequest =
      true;
    });

    try {
      final Skill skillToLearn =
          offeredSkills.first;

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

      if (!mounted) {
        return;
      }

      if (requestCreated ==
          true) {
        _showMessage(
          'Your request to ${user.name} is now Pending.',
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Swap request screen could not be opened. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningSwapRequest =
          false;
        });
      }
    }
  }
}