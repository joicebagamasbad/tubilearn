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

  String? _errorMessage;

  String? _openingSwapUserId;

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

  Future<void> _loadMatches() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await _repository.refresh();

      final String currentUserId =
      _currentUserService.requireUserId();

      final List<SkillMatch> matches =
      _repository.getSmartMatchesForUser(
        currentUserId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _matches =
            matches;
        _isLoading =
        false;
        _errorMessage =
        null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading =
        false;
        _errorMessage =
        'Smart matches could not be loaded. Please try again.';
      });
    }
  }

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
        appBar: AppBar(
          backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,
          surfaceTintColor:
          Colors.transparent,
          elevation:
          0,
          leading: IconButton(
            onPressed:
            _hasPendingAction
                ? null
                : () {
              Navigator.pop(
                context,
              );
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size:
              20,
              color:
              _hasPendingAction
                  ? _mutedColor
                  : _textColor,
            ),
          ),
          title: Text(
            'Smart Matches',
            style:
            AppTextStyles.sectionTitle
                .copyWith(
              color:
              _textColor,
            ),
          ),
        ),
        body: SafeArea(
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
      _hasPendingAction
          ? () async {}
          : _loadMatches,
      child: ListView.separated(
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
        _matches.length + 1,
        separatorBuilder:
            (
            _,
            index,
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
            _matches[index - 1],
            rank:
            index,
          );
        },
      ),
    );
  }

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
      child: Row(
        children: [
          Expanded(
            child: Column(
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
                  'Ranked using skill compatibility, availability, mode, language, location, and trust signals.',
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
        match.skillToLearn != null;

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
                  user.initials,
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
                width:
                12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
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
                          Icons.location_on_outlined,
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
                          child: Text(
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
                child: Text(
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
            child: Column(
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
                  Icons.info_outline_rounded,
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
                  child: Text(
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
                    Navigator.pushNamed(
                      context,
                      '/user-profile',
                      arguments:
                      user,
                    );
                  },
                  icon:
                  const Icon(
                    Icons.person_outline_rounded,
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
                    Icons.swap_horiz_rounded,
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

    setState(() {
      _openingSwapUserId =
          match.user.id;
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
                match.user.id,
                skillToLearnId:
                skillToLearn.id,
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

      if (requestCreated ==
          true) {
        _showMessage(
          'Your request to ${match.user.name} is now Pending.',
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
          _openingSwapUserId =
          null;
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
      child: Column(
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
      child: Padding(
        padding:
        const EdgeInsets.all(
          28,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
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

            ElevatedButton(
              onPressed:
              _loadMatches,
              child:
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
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          28,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
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
              'Add or update your offered skills and learning interests to find compatible people.',
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
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/my-skills',
                );
              },
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
      ),
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