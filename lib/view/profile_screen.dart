import 'package:flutter/material.dart';

import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/user.dart';
import '../model/user_skill.dart';
import '../services/current_user_service.dart';
import '../theme/app_theme.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final ExploreRepository _repository =
      ExploreRepository.instance;

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  User? _currentUser;

  List<Skill> _offeredSkills = <Skill>[];
  List<Skill> _wantedSkills = <Skill>[];

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _loadError;

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

  Color get _wantedBackground =>
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

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile({
    bool refreshRepository = false,
  }) async {
    try {
      if (refreshRepository) {
        await _repository.refresh();
      } else {
        await _repository.initialize();
      }

      final String userId =
      _currentUserService.requireUserId();

      final User? user =
      _repository.findUserById(
        userId,
      );

      if (user == null) {
        throw const ExploreRepositoryException(
          'Your profile could not be found.',
        );
      }

      final List<Skill> offeredSkills =
      _resolveSkills(
        _repository.getOfferedSkillsForUser(
          userId,
        ),
      );

      final List<Skill> wantedSkills =
      _resolveSkills(
        _repository.getWantedSkillsForUser(
          userId,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = user;
        _offeredSkills = offeredSkills;
        _wantedSkills = wantedSkills;
        _isLoading = false;
        _isRefreshing = false;
        _loadError = null;
      });
    } on CurrentUserServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = null;
        _offeredSkills = <Skill>[];
        _wantedSkills = <Skill>[];
        _isLoading = false;
        _isRefreshing = false;
        _loadError = error.message;
      });
    } on ExploreRepositoryException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = null;
        _offeredSkills = <Skill>[];
        _wantedSkills = <Skill>[];
        _isLoading = false;
        _isRefreshing = false;
        _loadError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = null;
        _offeredSkills = <Skill>[];
        _wantedSkills = <Skill>[];
        _isLoading = false;
        _isRefreshing = false;
        _loadError =
        'Your profile could not be loaded. Please try again.';
      });
    }
  }

  // ============================================================
  // RESOLVE SKILLS
  // ============================================================

  List<Skill> _resolveSkills(
      List<UserSkill> relationships,
      ) {
    final List<Skill> result = <Skill>[];
    final Set<String> seenSkillIds = <String>{};

    for (final UserSkill relationship
    in relationships) {
      if (!seenSkillIds.add(
        relationship.skillId,
      )) {
        continue;
      }

      final Skill? skill =
      _repository.findSkillById(
        relationship.skillId,
      );

      if (skill != null) {
        result.add(
          skill,
        );
      }
    }

    result.sort(
          (
          Skill a,
          Skill b,
          ) =>
          a.title
              .toLowerCase()
              .compareTo(
            b.title.toLowerCase(),
          ),
    );

    return result;
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshProfile() async {
    if (_isRefreshing ||
        _isLoading) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    await _loadProfile(
      refreshRepository: true,
    );
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  Future<void> _openEditProfile() async {
    final bool? updated =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (
            BuildContext routeContext,
            ) =>
        const EditProfileScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (updated == true) {
      await _loadProfile();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Profile updated successfully.',
      );
    }
  }

  // ============================================================
  // MY SKILLS
  // ============================================================

  Future<void> _openMySkills() async {
    await Navigator.pushNamed(
      context,
      '/my-skills',
    );

    if (!mounted) {
      return;
    }

    await _loadProfile(
      refreshRepository: true,
    );
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder:
            (
            BuildContext routeContext,
            ) =>
        const SettingsScreen(),
      ),
    );
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
      appBar: AppBar(
        backgroundColor:
        Theme.of(context)
            .scaffoldBackgroundColor,
        surfaceTintColor:
        Colors.transparent,
        elevation:
        0,
        title: Text(
          'My Profile',
          style: TextStyle(
            fontSize:
            19,
            fontWeight:
            FontWeight.w800,
            color:
            _textColor,
          ),
        ),
        actions: [
          if (!_isLoading &&
              _loadError == null)
            IconButton(
              tooltip:
              'Settings',
              onPressed:
              _openSettings,
              icon: Icon(
                Icons.settings_outlined,
                color:
                _textColor,
              ),
            ),
        ],
      ),
      body:
      _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_loadError != null) {
      return _buildErrorState();
    }

    final User? user =
        _currentUser;

    if (user == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh:
      _refreshProfile,
      child: SingleChildScrollView(
        physics:
        const BouncingScrollPhysics(
          parent:
          AlwaysScrollableScrollPhysics(),
        ),
        padding:
        const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          34,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(
              user,
            ),
            const SizedBox(
              height: 20,
            ),
            _buildStats(
              user,
            ),
            const SizedBox(
              height: 26,
            ),
            _buildSectionTitle(
              title:
              'About me',
              action:
              'EDIT',
              onAction:
              _openEditProfile,
            ),
            const SizedBox(
              height: 12,
            ),
            _buildAboutCard(
              user,
            ),
            const SizedBox(
              height: 26,
            ),
            _buildSectionTitle(
              title:
              'Skills I offer',
              action:
              'MANAGE',
              onAction:
              _openMySkills,
            ),
            const SizedBox(
              height: 12,
            ),
            _buildSkillsCard(
              skills:
              _offeredSkills,
              emptyTitle:
              'No skills offered yet',
              emptyMessage:
              'Add a skill you can teach so other learners can discover you.',
              icon:
              Icons.school_outlined,
            ),
            const SizedBox(
              height: 26,
            ),
            _buildSectionTitle(
              title:
              'Skills I want to learn',
              action:
              'MANAGE',
              onAction:
              _openMySkills,
            ),
            const SizedBox(
              height: 12,
            ),
            _buildSkillsCard(
              skills:
              _wantedSkills,
              emptyTitle:
              'No learning interests yet',
              emptyMessage:
              'Add skills you want to learn to make future matching more useful.',
              icon:
              Icons.auto_awesome_outlined,
              wanted:
              true,
            ),
            const SizedBox(
              height: 26,
            ),
            Text(
              'Your activity',
              style:
              AppTextStyles.sectionTitle
                  .copyWith(
                color:
                _textColor,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            _buildMenuCard(
              children: [
                _ProfileMenuItem(
                  icon:
                  Icons.school_outlined,
                  title:
                  'My Skills',
                  subtitle:
                  'Manage the skills you offer and want to learn',
                  onTap:
                  _openMySkills,
                ),
                _ProfileMenuItem(
                  icon:
                  Icons.swap_horiz_rounded,
                  title:
                  'My Swap Requests',
                  subtitle:
                  'View active and previous skill exchanges',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/swap-requests',
                    );
                  },
                ),
                _ProfileMenuItem(
                  icon:
                  Icons
                      .chat_bubble_outline_rounded,
                  title:
                  'Messages',
                  subtitle:
                  'Open your conversations with other learners',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/chat',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(
              height: 26,
            ),
            Text(
              'Account & preferences',
              style:
              AppTextStyles.sectionTitle
                  .copyWith(
                color:
                _textColor,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            _buildMenuCard(
              children: [
                _ProfileMenuItem(
                  icon:
                  Icons.person_outline_rounded,
                  title:
                  'Profile details',
                  subtitle:
                  'Edit your personal and learning information',
                  onTap:
                  _openEditProfile,
                ),
                _ProfileMenuItem(
                  icon:
                  Icons.settings_outlined,
                  title:
                  'Settings',
                  subtitle:
                  'App preferences and account information',
                  onTap:
                  _openSettings,
                ),
              ],
            ),
            const SizedBox(
              height: 24,
            ),
            _buildPrototypeNotice(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader(
      User user,
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
        children: [
          Row(
            children: [
              Container(
                width:
                72,
                height:
                72,
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
                    20,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Colors.white,
                  ),
                ),
              ),
              const SizedBox(
                width: 15,
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
                      height: 5,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons
                              .location_on_outlined,
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
                      height:
                      7,
                    ),
                    Text(
                      'Member since ${user.memberSince}',
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
              Image.asset(
                'assets/images/mascot/tubi_happy.png',
                width:
                58,
                height:
                58,
                fit:
                BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
            width:
            double.infinity,
            height:
            42,
            child:
            OutlinedButton.icon(
              onPressed:
              _openEditProfile,
              icon:
              const Icon(
                Icons.edit_outlined,
                size:
                17,
              ),
              label:
              const Text(
                'EDIT PROFILE',
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
  // STATS
  // ============================================================

  Widget _buildStats(
      User user,
      ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon:
            Icons.star_rounded,
            value:
            user.rating
                .toStringAsFixed(
              1,
            ),
            label:
            '${user.reviewCount} reviews',
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _buildStatCard(
            icon:
            Icons.swap_horiz_rounded,
            value:
            '${user.completedSwaps}',
            label:
            'Completed',
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _buildStatCard(
            icon:
            Icons.bolt_rounded,
            value:
            '${user.responseRate}%',
            label:
            'Response',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
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
          15,
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
            icon,
            size:
            18,
            color:
            _primaryColor,
          ),
          const SizedBox(
            height:
            6,
          ),
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
            3,
          ),
          Text(
            label,
            maxLines:
            1,
            overflow:
            TextOverflow.ellipsis,
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
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionTitle({
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
          TextButton(
            onPressed:
            onAction,
            style:
            TextButton.styleFrom(
              padding:
              const EdgeInsets.symmetric(
                horizontal:
                8,
                vertical:
                4,
              ),
              minimumSize:
              Size.zero,
              tapTargetSize:
              MaterialTapTargetSize
                  .shrinkWrap,
            ),
            child: Text(
              action,
              style:
              AppTextStyles.button
                  .copyWith(
                color:
                _primaryColor,
                fontSize:
                11,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // ABOUT
  // ============================================================

  Widget _buildAboutCard(
      User user,
      ) {
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            user.bio,
            style:
            AppTextStyles.bodyMuted
                .copyWith(
              color:
              _textColor,
            ),
          ),
          const SizedBox(
            height:
            16,
          ),
          Divider(
            height:
            1,
            color:
            _borderColor,
          ),
          const SizedBox(
            height:
            14,
          ),
          _buildInfoRow(
            icon:
            Icons.language_rounded,
            label:
            'Languages',
            value:
            user.language,
          ),
          const SizedBox(
            height:
            14,
          ),
          _buildInfoRow(
            icon:
            Icons.schedule_rounded,
            label:
            'Availability',
            value:
            user.availability,
          ),
          const SizedBox(
            height:
            14,
          ),
          _buildInfoRow(
            icon:
            Icons.devices_rounded,
            label:
            'Preferred mode',
            value:
            user.preferredMode,
          ),
          const SizedBox(
            height:
            14,
          ),
          _buildInfoRow(
            icon:
            Icons.school_outlined,
            label:
            'Teaching style',
            value:
            user.teachingStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          width:
          34,
          height:
          34,
          decoration:
          BoxDecoration(
            color:
            _softPrimaryColor,
            borderRadius:
            BorderRadius.circular(
              10,
            ),
          ),
          child: Icon(
            icon,
            size:
            17,
            color:
            _primaryColor,
          ),
        ),
        const SizedBox(
          width:
          10,
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
                height:
                2,
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

  Widget _buildSkillsCard({
    required List<Skill> skills,
    required String emptyTitle,
    required String emptyMessage,
    required IconData icon,
    bool wanted = false,
  }) {
    if (skills.isEmpty) {
      return _buildEmptySkillsCard(
        title:
        emptyTitle,
        message:
        emptyMessage,
        icon:
        icon,
      );
    }

    final List<Skill> visibleSkills =
    skills.take(5).toList();

    final int remaining =
        skills.length -
            visibleSkills.length;

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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing:
            8,
            runSpacing:
            8,
            children: [
              ...visibleSkills.map(
                    (
                    Skill skill,
                    ) {
                  return _buildSkillChip(
                    skill.title,
                    wanted:
                    wanted,
                  );
                },
              ),
              if (remaining > 0)
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal:
                    11,
                    vertical:
                    8,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    _surfaceVariantColor,
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
                  child: Text(
                    '+$remaining more',
                    style:
                    AppTextStyles.caption
                        .copyWith(
                      color:
                      _mutedColor,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(
            height:
            14,
          ),
          InkWell(
            borderRadius:
            BorderRadius.circular(
              10,
            ),
            onTap:
            _openMySkills,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(
                vertical:
                6,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size:
                    16,
                    color:
                    _primaryColor,
                  ),
                  const SizedBox(
                    width:
                    6,
                  ),
                  Text(
                    'Manage skills',
                    style:
                    AppTextStyles.secondary
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
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(
      String title, {
        required bool wanted,
      }) {
    final Color backgroundColor =
    wanted
        ? _wantedBackground
        : _softPrimaryColor;

    final Color textColor =
    wanted
        ? _wantedTextColor
        : _primaryColor;

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        11,
        vertical:
        8,
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
        title,
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

  Widget _buildEmptySkillsCard({
    required String title,
    required String message,
    required IconData icon,
  }) {
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
          Container(
            width:
            46,
            height:
            46,
            decoration:
            BoxDecoration(
              color:
              _softPrimaryColor,
              shape:
              BoxShape.circle,
            ),
            child: Icon(
              icon,
              color:
              _primaryColor,
              size:
              22,
            ),
          ),
          const SizedBox(
            height:
            10,
          ),
          Text(
            title,
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
            5,
          ),
          Text(
            message,
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
            12,
          ),
          OutlinedButton.icon(
            onPressed:
            _openMySkills,
            icon:
            const Icon(
              Icons.add_rounded,
              size:
              17,
            ),
            label:
            const Text(
              'MANAGE SKILLS',
              style:
              AppTextStyles.button,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENU CARD
  // ============================================================

  Widget _buildMenuCard({
    required List<Widget> children,
  }) {
    return Container(
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
        children:
        _withDividers(
          children,
        ),
      ),
    );
  }

  List<Widget> _withDividers(
      List<Widget> children,
      ) {
    final List<Widget> result =
    <Widget>[];

    for (int index = 0;
    index < children.length;
    index++) {
      result.add(
        children[index],
      );

      if (index !=
          children.length - 1) {
        result.add(
          Divider(
            height:
            1,
            indent:
            58,
            color:
            _borderColor,
          ),
        );
      }
    }

    return result;
  }

  // ============================================================
  // PROTOTYPE NOTICE
  // ============================================================

  Widget _buildPrototypeNotice() {
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
        _softPrimaryColor,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border:
        Border.all(
          color:
          _isDarkMode
              ? _primaryColor.withValues(
            alpha:
            0.24,
          )
              : const Color(
            0xFFD2E5E2,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size:
            18,
            color:
            _primaryColor,
          ),
          const SizedBox(
            width:
            9,
          ),
          Expanded(
            child: Text(
              'This prototype currently uses a local user session. Full authentication, cloud account syncing, and production account security will be added later.',
              style: TextStyle(
                fontSize:
                12,
                height:
                1.4,
                color:
                _mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child:
      SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(
          24,
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
              12,
            ),
            Text(
              'Could not load your profile',
              style:
              AppTextStyles.cardTitle
                  .copyWith(
                color:
                _textColor,
              ),
            ),
            const SizedBox(
              height:
              6,
            ),
            Text(
              _loadError ??
                  'Your profile could not be loaded.',
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
                setState(() {
                  _isLoading =
                  true;
                  _loadError =
                  null;
                });

                _loadProfile(
                  refreshRepository:
                  true,
                );
              },
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

class _ProfileMenuItem
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final Color primaryColor =
        Theme.of(context)
            .colorScheme
            .primary;

    final Color textColor =
        Theme.of(context)
            .colorScheme
            .onSurface;

    final Color mutedColor =
        Theme.of(context)
            .colorScheme
            .onSurfaceVariant;

    final bool isDarkMode =
        Theme.of(context).brightness ==
            Brightness.dark;

    final Color softPrimaryColor =
    isDarkMode
        ? primaryColor.withValues(
      alpha:
      0.16,
    )
        : const Color(
      0xFFE4F0EF,
    );

    return InkWell(
      borderRadius:
      BorderRadius.circular(
        18,
      ),
      onTap:
      onTap,
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          horizontal:
          14,
          vertical:
          14,
        ),
        child: Row(
          children: [
            Container(
              width:
              36,
              height:
              36,
              decoration:
              BoxDecoration(
                color:
                softPrimaryColor,
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
              ),
              child: Icon(
                icon,
                size:
                19,
                color:
                primaryColor,
              ),
            ),
            const SizedBox(
              width:
              10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                    TextStyle(
                      fontSize:
                      14,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      textColor,
                    ),
                  ),
                  const SizedBox(
                    height:
                    3,
                  ),
                  Text(
                    subtitle,
                    style:
                    TextStyle(
                      fontSize:
                      11.5,
                      height:
                      1.3,
                      color:
                      mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width:
              8,
            ),
            Icon(
              Icons.chevron_right_rounded,
              color:
              mutedColor,
            ),
          ],
        ),
      ),
    );
  }
}