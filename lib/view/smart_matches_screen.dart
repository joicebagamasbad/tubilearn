import 'dart:io';

import 'package:flutter/material.dart';

import '../model/repositories/explore_repository.dart';
import '../model/skill_match.dart';
import '../model/user.dart';
import '../services/current_user_service.dart';
import '../theme/app_theme.dart';
import 'create_swap_request_screen.dart';

class SmartMatchesScreen extends StatefulWidget {
  const SmartMatchesScreen({
    super.key,
  });

  @override
  State<SmartMatchesScreen> createState() =>
      _SmartMatchesScreenState();
}

class _SmartMatchesScreenState
    extends State<SmartMatchesScreen> {
  final ExploreRepository _repository =
      ExploreRepository.instance;

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _errorMessage;
  String? _openingSwapUserId;
  String? _currentUserId;

  bool _hasOfferedSkills = false;
  bool _hasWantedSkills = false;

  List<SkillMatch> _matches =
  <SkillMatch>[];

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

  Color get _primaryForeground =>
      _isDarkMode
          ? const Color(
        0xFF092E31,
      )
          : Colors.white;

  bool get _hasPendingAction =>
      _openingSwapUserId != null;

  @override
  void initState() {
    super.initState();

    _loadMatches();
  }

  // ============================================================
  // LOAD / REFRESH
  // ============================================================

  Future<void> _loadMatches({
    bool showLoading = true,
  }) async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;

    if (mounted && showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await _repository.refresh();

      final String currentUserId =
      _currentUserService.requireUserId();

      final List<SkillMatch> rawMatches =
      _repository.getSmartMatchesForUser(
        currentUserId,
      );

      final List<SkillMatch> safeMatches =
      _sanitizeMatches(
        rawMatches,
        currentUserId:
        currentUserId,
      );

      final bool hasOfferedSkills =
          _repository
              .getOfferedSkillsForUser(
            currentUserId,
          )
              .isNotEmpty;

      final bool hasWantedSkills =
          _repository
              .getWantedSkillsForUser(
            currentUserId,
          )
              .isNotEmpty;

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUserId =
            currentUserId;

        _matches =
            safeMatches;

        _hasOfferedSkills =
            hasOfferedSkills;

        _hasWantedSkills =
            hasWantedSkills;

        _isLoading =
        false;

        _errorMessage =
        null;
      });
    } on CurrentUserServiceException catch (error) {
      if (!mounted) {
        return;
      }

      if (!showLoading &&
          _matches.isNotEmpty) {
        _showMessage(
          error.message,
        );

        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            error.message;
      });
    } on ExploreRepositoryException catch (error) {
      if (!mounted) {
        return;
      }

      if (!showLoading &&
          _matches.isNotEmpty) {
        _showMessage(
          error.message,
        );

        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      if (!showLoading &&
          _matches.isNotEmpty) {
        _showMessage(
          'Smart matches could not be refreshed.',
        );

        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
        'Smart matches could not be loaded. Please try again.';
      });
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _refreshMatches() async {
    if (_hasPendingAction) {
      return;
    }

    await _loadMatches(
      showLoading:
      false,
    );
  }

  List<SkillMatch> _sanitizeMatches(
      List<SkillMatch> matches, {
        required String currentUserId,
      }) {
    final String cleanCurrentUserId =
    currentUserId.trim();

    final Set<String> seenUserIds =
    <String>{};

    final List<SkillMatch> result =
    <SkillMatch>[];

    for (final SkillMatch match
    in matches) {
      final String candidateUserId =
      match.user.id.trim();

      if (candidateUserId.isEmpty) {
        continue;
      }

      if (candidateUserId ==
          cleanCurrentUserId) {
        continue;
      }

      if (!seenUserIds.add(
        candidateUserId,
      )) {
        continue;
      }

      result.add(
        match,
      );
    }

    return List<SkillMatch>.unmodifiable(
      result,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return PopScope(
      canPop:
      !_hasPendingAction,
      child: Scaffold(
        backgroundColor:
        Theme.of(context)
            .scaffoldBackgroundColor,
        appBar:
        AppBar(
          backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,
          surfaceTintColor:
          Colors.transparent,
          elevation:
          0,
          leading:
          IconButton(
            tooltip:
            'Back',
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
              Icons
                  .arrow_back_ios_new_rounded,
              size:
              20,
              color:
              _hasPendingAction
                  ? _mutedColor
                  : _textColor,
            ),
          ),
          title:
          Text(
            'Smart Matches',
            style:
            AppTextStyles.sectionTitle
                .copyWith(
              color:
              _textColor,
            ),
          ),
        ),
        body:
        SafeArea(
          child:
          _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_matches.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh:
      _refreshMatches,
      child:
      ListView.separated(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          28,
        ),
        itemCount:
        _matches.length +
            1,
        separatorBuilder:
            (
            _,
            int index,
            ) {
          if (index == 0) {
            return const SizedBox(
              height:
              16,
            );
          }

          return const SizedBox(
            height:
            12,
          );
        },
        itemBuilder:
            (
            BuildContext context,
            int index,
            ) {
          if (index == 0) {
            return _buildHeaderCard();
          }

          return _buildMatchCard(
            _matches[
            index - 1],
            rank:
            index,
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeaderCard() {
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
          20,
        ),
        border:
        Border.all(
          color:
          _borderColor,
        ),
      ),
      child:
      Row(
        children: [
          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  '${_matches.length} match${_matches.length == 1 ? '' : 'es'} found',
                  style:
                  AppTextStyles.cardTitle
                      .copyWith(
                    color:
                    _textColor,
                  ),
                ),

                const SizedBox(
                  height:
                  5,
                ),

                Text(
                  'Ranked using skill compatibility, availability, session mode, language, location, completed swaps, and reviewed ratings.',
                  style:
                  AppTextStyles.bodyMuted
                      .copyWith(
                    color:
                    _mutedColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width:
            12,
          ),

          Image.asset(
            'assets/images/mascot/tubi_happy.png',
            width:
            68,
            height:
            68,
            fit:
            BoxFit.contain,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildUserAvatar(
      User user, {
        required double size,
      }) {
    final String? path =
    user.profileImagePath?.trim();

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
              initials:
              user.initials,
              size:
              size,
            );
          },
        )
            : _buildInitialAvatar(
          initials:
          user.initials,
          size:
          size,
        ),
      ),
    );
  }

  Widget _buildInitialAvatar({
    required String initials,
    required double size,
  }) {
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
        initials.trim().isEmpty
            ? '?'
            : initials,
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
  // MATCH CARD
  // ============================================================

  Widget _buildMatchCard(
      SkillMatch match, {
        required int rank,
      }) {
    final User user =
        match.user;

    final bool isOpeningSwap =
        _openingSwapUserId ==
            user.id;

    final bool canRequestSwap =
        match.skillToLearn !=
            null;

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
          20,
        ),
        border:
        Border.all(
          color:
          _borderColor,
        ),
      ),
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildUserAvatar(
                user,
                size:
                48,
              ),

              const SizedBox(
                width:
                12,
              ),

              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child:
                          Text(
                            user.name,
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
                        ),

                        const SizedBox(
                          width:
                          8,
                        ),

                        Text(
                          '#$rank',
                          style:
                          AppTextStyles.caption
                              .copyWith(
                            color:
                            _mutedColor,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height:
                      3,
                    ),

                    Row(
                      children: [
                        Icon(
                          Icons
                              .location_on_outlined,
                          size:
                          13,
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
                            maxLines:
                            1,
                            overflow:
                            TextOverflow.ellipsis,
                            style:
                            AppTextStyles.caption
                                .copyWith(
                              color:
                              _mutedColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width:
                10,
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal:
                  10,
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
                ),
                child:
                Text(
                  '${match.score}%',
                  style:
                  AppTextStyles.caption
                      .copyWith(
                    color:
                    _primaryColor,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          if (match.isTwoWayMatch) ...[
            const SizedBox(
              height:
              12,
            ),

            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal:
                10,
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
              ),
              child:
              Row(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Icon(
                    Icons
                        .swap_horiz_rounded,
                    size:
                    14,
                    color:
                    _primaryColor,
                  ),

                  const SizedBox(
                    width:
                    5,
                  ),

                  Text(
                    'Two-way match',
                    style:
                    AppTextStyles.caption
                        .copyWith(
                      color:
                      _primaryColor,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(
            height:
            14,
          ),

          Container(
            width:
            double.infinity,
            padding:
            const EdgeInsets.all(
              12,
            ),
            decoration:
            BoxDecoration(
              color:
              _surfaceVariantColor,
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
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  match.headline,
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
                  height:
                  6,
                ),

                Text(
                  match.explanation,
                  style:
                  AppTextStyles.bodyMuted
                      .copyWith(
                    color:
                    _mutedColor,
                  ),
                ),
              ],
            ),
          ),

          if (match.reasons.isNotEmpty) ...[
            const SizedBox(
              height:
              14,
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
              height:
              8,
            ),

            Wrap(
              spacing:
              7,
              runSpacing:
              7,
              children:
              match.reasons
                  .take(
                5,
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

          if (!canRequestSwap) ...[
            const SizedBox(
              height:
              12,
            ),

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons
                      .info_outline_rounded,
                  size:
                  15,
                  color:
                  _mutedColor,
                ),

                const SizedBox(
                  width:
                  7,
                ),

                Expanded(
                  child:
                  Text(
                    'This person wants a skill you offer, but they do not currently offer one of your learning interests.',
                    style:
                    AppTextStyles.caption
                        .copyWith(
                      color:
                      _mutedColor,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(
            height:
            14,
          ),

          Row(
            children: [
              Expanded(
                child:
                OutlinedButton.icon(
                  onPressed:
                  _hasPendingAction
                      ? null
                      : () {
                    _openUserProfile(
                      user,
                    );
                  },
                  icon:
                  const Icon(
                    Icons
                        .person_outline_rounded,
                    size:
                    18,
                  ),
                  label:
                  const Text(
                    'VIEW PROFILE',
                  ),
                ),
              ),

              const SizedBox(
                width:
                10,
              ),

              Expanded(
                child:
                ElevatedButton.icon(
                  onPressed:
                  _hasPendingAction ||
                      !canRequestSwap
                      ? null
                      : () {
                    _openSwapRequest(
                      match,
                    );
                  },
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
                  ),
                  icon:
                  isOpeningSwap
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
                    Icons
                        .swap_horiz_rounded,
                    size:
                    18,
                  ),
                  label:
                  Text(
                    isOpeningSwap
                        ? 'OPENING...'
                        : 'REQUEST SWAP',
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
  // PROFILE
  // ============================================================

  Future<void> _openUserProfile(
      User user,
      ) async {
    if (_hasPendingAction) {
      return;
    }

    await Navigator.pushNamed(
      context,
      '/user-profile',
      arguments:
      user,
    );

    if (!mounted) {
      return;
    }

    await _loadMatches(
      showLoading:
      false,
    );
  }

  // ============================================================
  // DIRECT SWAP REQUEST
  // ============================================================

  Future<void> _openSwapRequest(
      SkillMatch match,
      ) async {
    if (_hasPendingAction) {
      return;
    }

    final skillToLearn =
        match.skillToLearn;

    if (skillToLearn == null) {
      _showMessage(
        '${match.user.name} does not currently offer one of your learning interests.',
      );

      return;
    }

    final String candidateUserId =
    match.user.id.trim();

    final String currentUserId =
        _currentUserId?.trim() ??
            '';

    if (candidateUserId.isEmpty ||
        currentUserId.isEmpty ||
        candidateUserId ==
            currentUserId) {
      _showMessage(
        'This match is no longer available.',
      );

      return;
    }

    setState(() {
      _openingSwapUserId =
          candidateUserId;
    });

    try {
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
                candidateUserId,
                skillToLearnId:
                skillToLearn.id,
                skillToOfferId:
                match.skillToTeach?.id,
                providerName:
                match.user.name,
                providerInitials:
                match.user.initials,
                providerCity:
                match.user.city,
                skillToLearn:
                skillToLearn.title,
              ),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _openingSwapUserId = null;
      });

      if (requestCreated == true) {
        _showMessage(
          'Your request to ${match.user.name} is now Pending.',
        );
      }

      await _loadMatches(
        showLoading:
        false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      if (_openingSwapUserId !=
          null) {
        setState(() {
          _openingSwapUserId = null;
        });
      }

      _showMessage(
        'Swap request screen could not be opened. Please try again.',
      );
    } finally {
      if (mounted &&
          _openingSwapUserId !=
              null) {
        setState(() {
          _openingSwapUserId = null;
        });
      }
    }
  }

  // ============================================================
  // REASON CHIP
  // ============================================================

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
      child:
      Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            Icons
                .check_circle_outline_rounded,
            size:
            13,
            color:
            _primaryColor,
          ),

          const SizedBox(
            width:
            5,
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

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return Center(
      child:
      Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          SizedBox(
            width:
            30,
            height:
            30,
            child:
            CircularProgressIndicator(
              strokeWidth:
              2.5,
              color:
              _primaryColor,
            ),
          ),

          const SizedBox(
            height:
            14,
          ),

          Text(
            'Finding your best matches...',
            style:
            AppTextStyles.secondary
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
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child:
      Padding(
        padding:
        const EdgeInsets.all(
          28,
        ),
        child:
        Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons
                  .error_outline_rounded,
              size:
              44,
              color:
              _mutedColor,
            ),

            const SizedBox(
              height:
              14,
            ),

            Text(
              'Could not load matches',
              style:
              AppTextStyles.cardTitle
                  .copyWith(
                color:
                _textColor,
              ),
            ),

            const SizedBox(
              height:
              7,
            ),

            Text(
              _errorMessage ??
                  'Something went wrong.',
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
              height:
              18,
            ),

            ElevatedButton.icon(
              onPressed:
              _isRefreshing
                  ? null
                  : () {
                _loadMatches();
              },
              icon:
              const Icon(
                Icons.refresh_rounded,
                size:
                18,
              ),
              label:
              const Text(
                'TRY AGAIN',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh:
      _refreshMatches,
      child:
      ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.fromLTRB(
          28,
          70,
          28,
          28,
        ),
        children: [
          Image.asset(
            'assets/images/mascot/tubi_thinking.png',
            width:
            100,
            height:
            100,
            fit:
            BoxFit.contain,
          ),

          const SizedBox(
            height:
            14,
          ),

          Text(
            'No smart matches yet',
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
            height:
            7,
          ),

          Text(
            _emptyStateMessage(),
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
            height:
            18,
          ),

          OutlinedButton.icon(
            onPressed:
            _hasPendingAction
                ? null
                : _openMySkills,
            icon:
            const Icon(
              Icons.add_rounded,
            ),
            label:
            const Text(
              'UPDATE MY SKILLS',
            ),
          ),
        ],
      ),
    );
  }

  String _emptyStateMessage() {
    if (!_hasOfferedSkills &&
        !_hasWantedSkills) {
      return 'Add skills you can teach and skills you want to learn so TubiLearn can start comparing compatible people.';
    }

    if (!_hasOfferedSkills) {
      return 'You already have learning interests. Add at least one skill you can teach to unlock stronger skill exchanges.';
    }

    if (!_hasWantedSkills) {
      return 'You already have skills to offer. Add at least one skill you want to learn to find people who can teach you.';
    }

    return 'Your skill profile is ready, but no compatible people are available right now. Try adding more skills or refresh again later.';
  }

  Future<void> _openMySkills() async {
    if (_hasPendingAction) {
      return;
    }

    await Navigator.pushNamed(
      context,
      '/my-skills',
    );

    if (!mounted) {
      return;
    }

    await _loadMatches(
      showLoading:
      false,
    );
  }

  // ============================================================
  // MESSAGE
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
}