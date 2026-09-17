import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/user_profile_controller.dart';
import '../model/skill.dart';
import '../model/user.dart';
import '../theme/app_theme.dart';
import 'create_swap_request_screen.dart';

enum _PreviousConversationAction {
  cancel,
  restore,
  startNew,
}

enum _ProfileMenuAction {
  message,
  requestSwap,
  copyProfile,
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
  final UserProfileController _controller =
  UserProfileController();

  UserProfileSnapshot? _snapshot;

  bool _isLoadingProfile = true;
  String? _profileError;

  bool _isLoadingReviews = true;
  String? _reviewsError;

  List<UserProfileReview> _reviews =
  <UserProfileReview>[];

  bool _showAllReviews = false;

  bool _isOpeningConversation = false;
  bool _isOpeningSwapRequest = false;

  // ============================================================
  // DATA
  // ============================================================

  User get user =>
      _snapshot?.user ??
          widget.user;

  List<Skill> get _offeredSkills =>
      _snapshot?.offeredSkills ??
          const <Skill>[];

  List<Skill> get _wantedSkills =>
      _snapshot?.wantedSkills ??
          const <Skill>[];

  bool get _hasPendingAction =>
      _isOpeningConversation ||
          _isOpeningSwapRequest;

  // ============================================================
  // THEME
  // ============================================================

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

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadProfileData();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadProfileData() async {
    if (mounted) {
      setState(() {
        _isLoadingProfile = true;
        _profileError = null;

        _isLoadingReviews = true;
        _reviewsError = null;
      });
    }

    try {
      final UserProfileSnapshot snapshot =
      await _controller.loadProfile(
        widget.user,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _snapshot = snapshot;

        _reviews =
        List<UserProfileReview>.from(
          snapshot.reviews,
        );

        _isLoadingProfile = false;
        _profileError = null;

        _isLoadingReviews = false;
        _reviewsError = null;

        _showAllReviews = false;
      });
    } on UserProfileControllerException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingProfile = false;
        _profileError = error.message;

        _isLoadingReviews = false;
        _reviewsError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingProfile = false;
        _profileError =
        'Profile details could not be loaded. Please try again.';

        _isLoadingReviews = false;
        _reviewsError =
        'Reviews could not be loaded.';
      });
    }
  }

  Future<void> _loadReviews() async {
    if (_isLoadingReviews) {
      return;
    }

    setState(() {
      _isLoadingReviews = true;
      _reviewsError = null;
    });

    try {
      final List<UserProfileReview> reviews =
      await _controller.loadReviews(
        user,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reviews =
        List<UserProfileReview>.from(
          reviews,
        );

        _isLoadingReviews = false;
        _reviewsError = null;
      });
    } on UserProfileControllerException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingReviews = false;
        _reviewsError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingReviews = false;
        _reviewsError =
        'Reviews could not be loaded.';
      });
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshProfile() async {
    try {
      final UserProfileSnapshot snapshot =
      await _controller.refreshProfile(
        user,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _snapshot = snapshot;

        _reviews =
        List<UserProfileReview>.from(
          snapshot.reviews,
        );

        _reviewsError = null;
        _isLoadingReviews = false;
      });
    } on UserProfileControllerException catch (error) {
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
        'Profile could not be refreshed.',
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
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
              _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingProfile) {
      return Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color:
              _primaryColor,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              'Loading profile...',
              style:
              AppTextStyles.bodyMuted
                  .copyWith(
                color:
                _mutedColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_profileError != null ||
        _snapshot == null) {
      return _buildProfileErrorState();
    }

    return RefreshIndicator(
      onRefresh:
      _refreshProfile,
      child: SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(
          parent:
          BouncingScrollPhysics(),
        ),
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

            if (_offeredSkills.isEmpty)
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
                spacing: 8,
                runSpacing: 8,
                children:
                _offeredSkills
                    .map(
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

            if (_wantedSkills.isEmpty)
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
                spacing: 8,
                runSpacing: 8,
                children:
                _wantedSkills
                    .map(
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

            _buildReviewsSection(),

            const SizedBox(
              height: 28,
            ),

            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileErrorState() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          26,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 42,
              color:
              _mutedColor,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              'Could not load profile',
              style:
              AppTextStyles.cardTitle
                  .copyWith(
                color:
                _textColor,
              ),
            ),
            const SizedBox(
              height: 7,
            ),
            Text(
              _profileError ??
                  'Profile details could not be loaded.',
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
              height: 16,
            ),
            OutlinedButton.icon(
              onPressed:
              _loadProfileData,
              icon:
              const Icon(
                Icons.refresh_rounded,
              ),
              label:
              const Text(
                'TRY AGAIN',
                style:
                AppTextStyles.button,
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
      height: 62,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
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
      child: Row(
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
            icon: Icon(
              Icons
                  .arrow_back_ios_new_rounded,
              size: 18,
              color:
              _hasPendingAction
                  ? _mutedColor
                  : _primaryColor,
            ),
          ),

          Expanded(
            child: Center(
              child: Text(
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

          PopupMenuButton<_ProfileMenuAction>(
            enabled:
            !_hasPendingAction &&
                !_isLoadingProfile &&
                _snapshot != null,
            tooltip:
            'More profile actions',
            color:
            _surfaceColor,
            surfaceTintColor:
            Colors.transparent,
            icon: Icon(
              Icons.more_horiz_rounded,
              color:
              _hasPendingAction
                  ? _mutedColor.withValues(
                alpha: 0.5,
              )
                  : _mutedColor,
            ),
            onSelected:
            _handleProfileMenuAction,
            itemBuilder: (
                BuildContext menuContext,
                ) {
              return <
                  PopupMenuEntry<
                      _ProfileMenuAction>>[
                PopupMenuItem<
                    _ProfileMenuAction>(
                  value:
                  _ProfileMenuAction.message,
                  child:
                  _buildMenuItem(
                    icon:
                    Icons
                        .chat_bubble_outline_rounded,
                    label:
                    'Message',
                  ),
                ),
                PopupMenuItem<
                    _ProfileMenuAction>(
                  value:
                  _ProfileMenuAction
                      .requestSwap,
                  child:
                  _buildMenuItem(
                    icon:
                    Icons.swap_horiz_rounded,
                    label:
                    'Request swap',
                  ),
                ),
                PopupMenuItem<
                    _ProfileMenuAction>(
                  value:
                  _ProfileMenuAction
                      .copyProfile,
                  child:
                  _buildMenuItem(
                    icon:
                    Icons.copy_rounded,
                    label:
                    'Copy profile summary',
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color:
          _primaryColor,
        ),
        const SizedBox(
          width: 11,
        ),
        Text(
          label,
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
    );
  }

  Future<void> _handleProfileMenuAction(
      _ProfileMenuAction action,
      ) async {
    if (_hasPendingAction ||
        _snapshot == null) {
      return;
    }

    switch (action) {
      case _ProfileMenuAction.message:
        await _openConversation();
        return;

      case _ProfileMenuAction.requestSwap:
        await _openSwapRequest();
        return;

      case _ProfileMenuAction.copyProfile:
        await _copyProfileSummary();
        return;
    }
  }

  // ============================================================
  // COPY PROFILE
  // ============================================================

  Future<void> _copyProfileSummary() async {
    final UserProfileSnapshot? snapshot =
        _snapshot;

    if (snapshot == null) {
      return;
    }

    final String summary =
    _controller.buildProfileSummary(
      snapshot,
    );

    try {
      await Clipboard.setData(
        ClipboardData(
          text:
          summary,
        ),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        '${snapshot.user.name}\'s profile summary copied.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Profile summary could not be copied.',
      );
    }
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader() {
    return Row(
      children: [
        _buildProfileAvatar(
          user,
          size: 78,
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
                AppTextStyles.pageTitle
                    .copyWith(
                  color:
                  _textColor,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color:
                    _mutedColor,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Expanded(
                    child: Text(
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
                height: 8,
              ),

              Row(
                children: [
                  Icon(
                    user.reviewCount > 0
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 17,
                    color:
                    user.reviewCount > 0
                        ? AppTheme.accent
                        : _mutedColor,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  if (user.reviewCount > 0) ...[
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
                      width: 5,
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
                  ] else
                    Text(
                      'No reviews yet',
                      style:
                      AppTextStyles.caption
                          .copyWith(
                        color:
                        _mutedColor,
                        fontWeight:
                        FontWeight.w600,
                      ),
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
  // AVATARS
  // ============================================================

  Widget _buildProfileAvatar(
      User profileUser, {
        required double size,
      }) {
    final String? path =
    profileUser.profileImagePath?.trim();

    final bool hasImage =
        path != null &&
            path.isNotEmpty &&
            _profileImageExists(
              path,
            );

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child:
        hasImage
            ? Image.file(
          File(
            path,
          ),
          width: size,
          height: size,
          fit:
          BoxFit.cover,
          errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
              ) {
            return _buildInitialAvatar(
              profileUser,
              size:
              size,
            );
          },
        )
            : _buildInitialAvatar(
          profileUser,
          size:
          size,
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(
      User profileUser, {
        required double size,
      }) {
    final String initials =
    profileUser.initials
        .trim()
        .isEmpty
        ? '?'
        : profileUser.initials.trim();

    return Container(
      width: size,
      height: size,
      color:
      AppTheme.accent,
      alignment:
      Alignment.center,
      child: Text(
        initials,
        style:
        TextStyle(
          fontSize:
          size >= 70
              ? 20
              : 16,
          fontWeight:
          FontWeight.w800,
          color:
          Colors.white,
        ),
      ),
    );
  }

  Widget _buildReviewerAvatar(
      User? reviewer, {
        required double size,
      }) {
    if (reviewer != null) {
      return _buildProfileAvatar(
        reviewer,
        size:
        size,
      );
    }

    return ClipOval(
      child: Container(
        width:
        size,
        height:
        size,
        color:
        AppTheme.accent,
        alignment:
        Alignment.center,
        child:
        const Icon(
          Icons.person_rounded,
          color:
          Colors.white,
          size:
          18,
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
            '${_offeredSkills.length}',
            'Skills offered',
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
      child: Column(
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
            height: 4,
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
      child: Column(
        children: [
          _infoRow(
            Icons.language_rounded,
            'Languages',
            user.language,
          ),
          Divider(
            height: 22,
            color:
            _borderColor,
          ),
          _infoRow(
            Icons.schedule_rounded,
            'Availability',
            user.availability,
          ),
          Divider(
            height: 22,
            color:
            _borderColor,
          ),
          _infoRow(
            Icons.devices_rounded,
            'Preferred mode',
            user.preferredMode,
          ),
          Divider(
            height: 22,
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
          size: 18,
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
                ),
              ),
              const SizedBox(
                height: 3,
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
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'Profile & activity',
            style:
            AppTextStyles.cardTitle
                .copyWith(
              fontSize: 14,
              color:
              _textColor,
            ),
          ),
          const SizedBox(
            height: 10,
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
          AppTheme.success,
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
              _textColor,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REVIEWS
  // ============================================================

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Reviews',
                style:
                AppTextStyles.cardTitle
                    .copyWith(
                  color:
                  _textColor,
                ),
              ),
            ),
            if (!_isLoadingReviews &&
                _reviewsError == null &&
                _reviews.isNotEmpty)
              Row(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 17,
                    color:
                    AppTheme.accent,
                  ),
                  const SizedBox(
                    width: 4,
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
                ],
              ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        if (_isLoadingReviews)
          _buildReviewsLoadingState()
        else if (_reviewsError != null)
          _buildReviewsErrorState()
        else if (_reviews.isEmpty)
            _buildNoReviewsState()
          else
            _buildReviewList(),
      ],
    );
  }

  Widget _buildReviewsLoadingState() {
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
          SizedBox(
            width: 18,
            height: 18,
            child:
            CircularProgressIndicator(
              strokeWidth: 2,
              color:
              _primaryColor,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Text(
            'Loading reviews...',
            style:
            AppTextStyles.bodyMuted
                .copyWith(
              color:
              _mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsErrorState() {
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
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 28,
            color:
            _mutedColor,
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            _reviewsError ??
                'Reviews could not be loaded.',
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
            height: 10,
          ),
          TextButton.icon(
            onPressed:
            _loadReviews,
            icon:
            const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),
            label:
            const Text(
              'TRY AGAIN',
              style:
              AppTextStyles.button,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoReviewsState() {
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
            width: 44,
            height: 44,
            decoration:
            BoxDecoration(
              color:
              _softPrimaryColor,
              borderRadius:
              BorderRadius.circular(
                13,
              ),
            ),
            child: Icon(
              Icons.reviews_outlined,
              color:
              _primaryColor,
              size: 22,
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
                  'No written reviews yet',
                  style:
                  AppTextStyles.cardTitle
                      .copyWith(
                    fontSize: 14,
                    color:
                    _textColor,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  user.reviewCount > 0
                      ? 'This profile has historical rating data, but no individual written reviews are stored on this device yet.'
                      : 'Reviews will appear after completed skill exchanges.',
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
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    final List<UserProfileReview> visibleReviews =
    _showAllReviews
        ? _reviews
        : _reviews
        .take(
      3,
    )
        .toList();

    return Column(
      children: [
        for (
        int index = 0;
        index < visibleReviews.length;
        index++
        ) ...[
          _buildReviewCard(
            visibleReviews[index],
          ),
          if (index <
              visibleReviews.length - 1)
            const SizedBox(
              height: 10,
            ),
        ],

        if (_reviews.length > 3) ...[
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width:
            double.infinity,
            child:
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showAllReviews =
                  !_showAllReviews;
                });
              },
              icon: Icon(
                _showAllReviews
                    ? Icons
                    .expand_less_rounded
                    : Icons
                    .expand_more_rounded,
                size: 19,
              ),
              label: Text(
                _showAllReviews
                    ? 'SHOW FEWER REVIEWS'
                    : 'SHOW ALL ${_reviews.length} REVIEWS',
                style:
                AppTextStyles.button,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewCard(
      UserProfileReview item,
      ) {
    final String? comment =
    item.review.comment?.trim();

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
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildReviewerAvatar(
                item.reviewer,
                size: 42,
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
                      item.reviewerName,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      AppTextStyles.cardTitle
                          .copyWith(
                        fontSize: 14,
                        color:
                        _textColor,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Row(
                      children: [
                        _buildStarRating(
                          item.review.rating,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Text(
                            _formatReviewDate(
                              item.review.createdAt,
                            ),
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
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
            ],
          ),

          if (comment != null &&
              comment.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            Text(
              comment,
              style:
              AppTextStyles.bodyMuted
                  .copyWith(
                color:
                _textColor,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRating(
      int rating,
      ) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children:
      List<Widget>.generate(
        5,
            (
            int index,
            ) {
          final bool filled =
              index < rating;

          return Icon(
            filled
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            size: 16,
            color:
            filled
                ? AppTheme.accent
                : _mutedColor,
          );
        },
      ),
    );
  }

  String _formatReviewDate(
      DateTime date,
      ) {
    final DateTime local =
    date.toLocal();

    final DateTime now =
    DateTime.now();

    final DateTime today =
    DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime reviewDay =
    DateTime(
      local.year,
      local.month,
      local.day,
    );

    final int difference =
        today
            .difference(
          reviewDay,
        )
            .inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    if (difference > 1 &&
        difference < 7) {
      return '$difference days ago';
    }

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

    if (local.year ==
        now.year) {
      return '${months[local.month - 1]} ${local.day}';
    }

    return '${months[local.month - 1]} '
        '${local.day}, '
        '${local.year}';
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child:
            OutlinedButton.icon(
              onPressed:
              _hasPendingAction
                  ? null
                  : _openConversation,
              icon:
              _isOpeningConversation
                  ? SizedBox(
                width: 16,
                height: 16,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                  _primaryColor,
                ),
              )
                  : const Icon(
                Icons
                    .chat_bubble_outline_rounded,
                size: 16,
              ),
              label: Text(
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
          width: 10,
        ),

        Expanded(
          child: SizedBox(
            height: 46,
            child:
            ElevatedButton.icon(
              onPressed:
              _hasPendingAction
                  ? null
                  : _openSwapRequest,
              icon:
              _isOpeningSwapRequest
                  ? SizedBox(
                width: 16,
                height: 16,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                  _primaryForeground,
                ),
              )
                  : const Icon(
                Icons.swap_horiz_rounded,
                size: 17,
              ),
              label: Text(
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

  Future<void> _openConversation() async {
    if (_hasPendingAction) {
      return;
    }

    final UserProfileSnapshot? snapshot =
        _snapshot;

    if (snapshot == null) {
      return;
    }

    setState(() {
      _isOpeningConversation = true;
    });

    try {
      final UserProfileConversationResult result =
      await _controller.openConversation(
        snapshot,
      );

      if (!mounted) {
        return;
      }

      if (result.status ==
          UserProfileConversationStatus.ready) {
        final String? conversationId =
            result.conversationId;

        if (conversationId == null ||
            conversationId.trim().isEmpty) {
          throw const UserProfileControllerException(
            'Conversation could not be opened.',
          );
        }

        await _openConversationRoute(
          conversationId,
        );

        return;
      }

      final String? hiddenConversationId =
          result.hiddenConversationId;

      if (hiddenConversationId == null ||
          hiddenConversationId
              .trim()
              .isEmpty) {
        throw const UserProfileControllerException(
          'Previous conversation could not be found.',
        );
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
            hiddenConversationId,
          );
          return;

        case _PreviousConversationAction.startNew:
          await _startNewConversation(
            snapshot,
          );
          return;
      }
    } on UserProfileControllerException catch (error) {
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
          _isOpeningConversation = false;
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
      final String restoredConversationId =
      await _controller.restoreConversation(
        conversationId,
      );

      if (!mounted) {
        return;
      }

      await _openConversationRoute(
        restoredConversationId,
      );
    } on UserProfileControllerException catch (error) {
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

  Future<void> _startNewConversation(
      UserProfileSnapshot snapshot,
      ) async {
    try {
      final String conversationId =
      await _controller.startNewConversation(
        snapshot,
      );

      if (!mounted) {
        return;
      }

      await _openConversationRoute(
        conversationId,
      );
    } on UserProfileControllerException catch (error) {
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
      builder: (
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
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                BoxDecoration(
                  color:
                  _softPrimaryColor,
                  shape:
                  BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_rounded,
                  color:
                  _primaryColor,
                  size: 21,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
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
          content: Text(
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
              child: Text(
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
                size: 17,
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
                size: 17,
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
                elevation: 0,
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
  // SWAP REQUEST
  // ============================================================

  Future<void> _openSwapRequest() async {
    if (_hasPendingAction) {
      return;
    }

    setState(() {
      _isOpeningSwapRequest = true;
    });

    try {
      final UserProfileSwapRequestData data =
      await _controller.prepareSwapRequest(
        user,
      );

      if (!mounted) {
        return;
      }

      final bool? requestCreated =
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (
              BuildContext routeContext,
              ) =>
              CreateSwapRequestScreen(
                providerUserId:
                data.provider.id,
                skillToLearnId:
                data.skillToLearn.id,
                providerName:
                data.provider.name,
                providerInitials:
                data.provider.initials,
                providerCity:
                data.provider.city,
                skillToLearn:
                data.skillToLearn.title,
              ),
        ),
      );

      if (!mounted) {
        return;
      }

      if (requestCreated == true) {
        _showMessage(
          'Your request to ${data.provider.name} is now Pending.',
        );

        await _refreshProfile();
      }
    } on UserProfileControllerException catch (error) {
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
        'Swap request screen could not be opened. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningSwapRequest = false;
        });
      }
    }
  }

  // ============================================================
  // FEEDBACK
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