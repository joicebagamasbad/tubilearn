import 'package:flutter/material.dart';

import '../model/repositories/my_skills_repository.dart';
import '../model/repositories/wanted_skills_repository.dart';
import '../services/current_user_service.dart';
import '../theme/app_theme.dart';
import 'add_skill_screen.dart';
import 'add_wanted_skill_screen.dart';
import 'edit_skill_screen.dart';
import 'edit_wanted_skill_screen.dart';

class MySkillsScreen extends StatefulWidget {
  const MySkillsScreen({
    super.key,
  });

  @override
  State<MySkillsScreen> createState() =>
      _MySkillsScreenState();
}

class _MySkillsScreenState
    extends State<MySkillsScreen>
    with SingleTickerProviderStateMixin {
  final MySkillsRepository _offeredRepository =
      MySkillsRepository.instance;

  final WantedSkillsRepository _wantedRepository =
      WantedSkillsRepository.instance;

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  late final TabController _tabController;

  List<ManagedSkill> _offeredSkills =
  <ManagedSkill>[];

  List<ManagedWantedSkill> _wantedSkills =
  <ManagedWantedSkill>[];

  bool _loading = true;
  bool _refreshing = false;

  String? _error;

  bool get _isDarkMode =>
      Theme.of(context).brightness ==
          Brightness.dark;

  Color get _primaryColor =>
      Theme.of(context).colorScheme.primary;

  Color get _surfaceColor =>
      Theme.of(context).colorScheme.surface;

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

  Color get _wantedForegroundColor =>
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

    _tabController =
        TabController(
          length: 2,
          vsync: this,
        );

    _loadAllSkills();
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD ALL
  // ============================================================

  Future<void> _loadAllSkills() async {
    if (!_refreshing &&
        mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final String userId =
      _currentUserService.requireUserId();

      final List<ManagedSkill> offered =
      await _offeredRepository
          .getOfferedSkills(
        userId,
      );

      final List<ManagedWantedSkill> wanted =
      await _wantedRepository
          .getWantedSkills(
        userId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _offeredSkills = offered;
        _wantedSkills = wanted;
        _loading = false;
        _refreshing = false;
        _error = null;
      });
    } on CurrentUserServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _refreshing = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _refreshing = false;
        _error = error.toString();
      });
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshAllSkills() async {
    if (_refreshing) {
      return;
    }

    setState(() {
      _refreshing = true;
    });

    await _loadAllSkills();
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
        elevation: 0,
        title:
        Text(
          'My Skills',
          style:
          TextStyle(
            fontSize: 19,
            fontWeight:
            FontWeight.w800,
            color:
            _textColor,
          ),
        ),
        bottom:
        TabBar(
          controller:
          _tabController,
          labelColor:
          _primaryColor,
          unselectedLabelColor:
          _mutedColor,
          indicatorColor:
          _primaryColor,
          indicatorWeight:
          3,
          labelStyle:
          const TextStyle(
            fontSize: 12,
            fontWeight:
            FontWeight.w800,
          ),
          unselectedLabelStyle:
          const TextStyle(
            fontSize: 12,
            fontWeight:
            FontWeight.w600,
          ),
          tabs:
          const [
            Tab(
              text:
              'I OFFER',
            ),
            Tab(
              text:
              'I WANT TO LEARN',
            ),
          ],
        ),
      ),
      body:
      _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return TabBarView(
      controller:
      _tabController,
      children: [
        _buildOfferedTab(),
        _buildWantedTab(),
      ],
    );
  }

  // ============================================================
  // OFFERED TAB
  // ============================================================

  Widget _buildOfferedTab() {
    return RefreshIndicator(
      onRefresh:
      _refreshAllSkills,
      child:
      ListView(
        physics:
        const AlwaysScrollableScrollPhysics(
          parent:
          BouncingScrollPhysics(),
        ),
        padding:
        const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          32,
        ),
        children: [
          _buildSectionIntro(
            title:
            'Skills you can teach',
            message:
            'Manage the skills you offer to other learners.',
            mascot:
            'assets/images/mascot/tubi_checking.png',
          ),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
            width:
            double.infinity,
            height:
            44,
            child:
            ElevatedButton.icon(
              onPressed:
              _openAddOfferedSkill,
              icon:
              const Icon(
                Icons.add_rounded,
                size: 19,
              ),
              label:
              const Text(
                'ADD SKILL I CAN TEACH',
                style:
                AppTextStyles.button,
              ),
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          if (_offeredSkills.isEmpty)
            _buildEmptyState(
              icon:
              Icons.school_outlined,
              title:
              'No offered skills yet',
              message:
              'Add a skill you can teach so other learners can discover you.',
              buttonText:
              'ADD OFFERED SKILL',
              onPressed:
              _openAddOfferedSkill,
            )
          else
            ..._offeredSkills.map(
                  (
                  ManagedSkill managedSkill,
                  ) =>
                  Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 14,
                    ),
                    child:
                    _buildOfferedSkillCard(
                      managedSkill,
                    ),
                  ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // WANTED TAB
  // ============================================================

  Widget _buildWantedTab() {
    return RefreshIndicator(
      onRefresh:
      _refreshAllSkills,
      child:
      ListView(
        physics:
        const AlwaysScrollableScrollPhysics(
          parent:
          BouncingScrollPhysics(),
        ),
        padding:
        const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          32,
        ),
        children: [
          _buildSectionIntro(
            title:
            'Skills you want to learn',
            message:
            'Keep your learning interests updated for better future matches.',
            mascot:
            'assets/images/mascot/tubi_studying.png',
          ),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
            width:
            double.infinity,
            height:
            44,
            child:
            ElevatedButton.icon(
              onPressed:
              _openAddWantedSkill,
              icon:
              const Icon(
                Icons.add_rounded,
                size: 19,
              ),
              label:
              const Text(
                'ADD LEARNING INTEREST',
                style:
                AppTextStyles.button,
              ),
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          if (_wantedSkills.isEmpty)
            _buildEmptyState(
              icon:
              Icons.auto_awesome_outlined,
              title:
              'No learning interests yet',
              message:
              'Add skills you want to learn so TubiLearn can understand your goals.',
              buttonText:
              'ADD LEARNING INTEREST',
              onPressed:
              _openAddWantedSkill,
            )
          else
            ..._wantedSkills.map(
                  (
                  ManagedWantedSkill managedWantedSkill,
                  ) =>
                  Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 14,
                    ),
                    child:
                    _buildWantedSkillCard(
                      managedWantedSkill,
                    ),
                  ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION INTRO
  // ============================================================

  Widget _buildSectionIntro({
    required String title,
    required String message,
    required String mascot,
  }) {
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
                  title,
                  style:
                  AppTextStyles
                      .cardTitle
                      .copyWith(
                    color:
                    _textColor,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  message,
                  style:
                  AppTextStyles
                      .bodyMuted
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
          Image.asset(
            mascot,
            width: 66,
            height: 66,
            fit:
            BoxFit.contain,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OFFERED CARD
  // ============================================================

  Widget _buildOfferedSkillCard(
      ManagedSkill managedSkill,
      ) {
    final skill =
        managedSkill.skill;

    final userSkill =
        managedSkill.userSkill;

    final bool customSkill =
    managedSkill.metadataCanBeEditedBy(
      _currentUserService.userId,
    );

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
      child:
      Column(
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildSkillIcon(
                skill.icon,
              ),
              const SizedBox(
                width: 14,
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
                            skill.title,
                            style:
                            AppTextStyles
                                .cardTitle
                                .copyWith(
                              color:
                              _textColor,
                            ),
                          ),
                        ),
                        if (customSkill)
                          _buildCustomBadge(),
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    _buildMetaRow(
                      icon:
                      Icons.bar_chart_rounded,
                      label:
                      'Level',
                      value:
                      userSkill.level,
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    _buildMetaRow(
                      icon:
                      Icons.schedule_rounded,
                      label:
                      'Availability',
                      value:
                      userSkill.availability,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          Divider(
            height: 1,
            color:
            _borderColor,
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  _openEditOfferedSkill(
                    managedSkill,
                  );
                },
                icon:
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color:
                  _primaryColor,
                ),
                label:
                Text(
                  'EDIT',
                  style:
                  AppTextStyles.button
                      .copyWith(
                    color:
                    _primaryColor,
                  ),
                ),
              ),
              const SizedBox(
                width: 4,
              ),
              TextButton.icon(
                onPressed: () {
                  _confirmDeleteOfferedSkill(
                    managedSkill,
                  );
                },
                icon:
                const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color:
                  AppTheme.error,
                ),
                label:
                const Text(
                  'DELETE',
                  style:
                  TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    AppTheme.error,
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
  // WANTED CARD
  // ============================================================

  Widget _buildWantedSkillCard(
      ManagedWantedSkill managedWantedSkill,
      ) {
    final skill =
        managedWantedSkill.skill;

    final userSkill =
        managedWantedSkill.userSkill;

    final bool customSkill =
    managedWantedSkill.metadataCanBeEditedBy(
      _currentUserService.userId,
    );

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
      child:
      Column(
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildSkillIcon(
                skill.icon,
                wanted: true,
              ),
              const SizedBox(
                width: 14,
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
                            skill.title,
                            style:
                            AppTextStyles
                                .cardTitle
                                .copyWith(
                              color:
                              _textColor,
                            ),
                          ),
                        ),
                        if (customSkill)
                          _buildCustomBadge(),
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    _buildMetaRow(
                      icon:
                      Icons.bar_chart_rounded,
                      label:
                      'Current level',
                      value:
                      userSkill.level,
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    _buildMetaRow(
                      icon:
                      Icons.schedule_rounded,
                      label:
                      'Availability',
                      value:
                      userSkill.availability,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          Divider(
            height: 1,
            color:
            _borderColor,
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  _openEditWantedSkill(
                    managedWantedSkill,
                  );
                },
                icon:
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color:
                  _primaryColor,
                ),
                label:
                Text(
                  'EDIT',
                  style:
                  AppTextStyles.button
                      .copyWith(
                    color:
                    _primaryColor,
                  ),
                ),
              ),
              const SizedBox(
                width: 4,
              ),
              TextButton.icon(
                onPressed: () {
                  _confirmDeleteWantedSkill(
                    managedWantedSkill,
                  );
                },
                icon:
                const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color:
                  AppTheme.error,
                ),
                label:
                const Text(
                  'DELETE',
                  style:
                  TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    AppTheme.error,
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
  // CARD HELPERS
  // ============================================================

  Widget _buildSkillIcon(
      IconData icon, {
        bool wanted = false,
      }) {
    final Color backgroundColor =
    wanted
        ? _wantedBackgroundColor
        : _softPrimaryColor;

    final Color iconColor =
    wanted
        ? _wantedForegroundColor
        : _primaryColor;

    return Container(
      width: 56,
      height: 56,
      decoration:
      BoxDecoration(
        color:
        backgroundColor,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
      ),
      child:
      Icon(
        icon,
        size: 28,
        color:
        iconColor,
      ),
    );
  }

  Widget _buildCustomBadge() {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
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
        'CUSTOM',
        style:
        TextStyle(
          fontSize: 7.5,
          fontWeight:
          FontWeight.w700,
          color:
          _primaryColor,
        ),
      ),
    );
  }

  Widget _buildMetaRow({
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
          size: 14,
          color:
          _primaryColor,
        ),
        const SizedBox(
          width: 6,
        ),
        Text(
          '$label:',
          style:
          AppTextStyles
              .caption
              .copyWith(
            color:
            _mutedColor,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Expanded(
          child:
          Text(
            value,
            style:
            AppTextStyles
                .caption
                .copyWith(
              color:
              _textColor,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        22,
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
      child:
      Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration:
            BoxDecoration(
              color:
              _softPrimaryColor,
              shape:
              BoxShape.circle,
            ),
            child:
            Icon(
              icon,
              color:
              _primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            title,
            textAlign:
            TextAlign.center,
            style:
            AppTextStyles
                .cardTitle
                .copyWith(
              color:
              _textColor,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            message,
            textAlign:
            TextAlign.center,
            style:
            AppTextStyles
                .bodyMuted
                .copyWith(
              color:
              _mutedColor,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          OutlinedButton.icon(
            onPressed:
            onPressed,
            icon:
            const Icon(
              Icons.add_rounded,
              size: 17,
            ),
            label:
            Text(
              buttonText,
              style:
              AppTextStyles.button,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADD OFFERED
  // ============================================================

  Future<void> _openAddOfferedSkill() async {
    final bool? changed =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (
            BuildContext routeContext,
            ) =>
        const AddSkillScreen(),
      ),
    );

    if (!mounted ||
        changed != true) {
      return;
    }

    await _loadAllSkills();
  }

  // ============================================================
  // ADD WANTED
  // ============================================================

  Future<void> _openAddWantedSkill() async {
    final bool? changed =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (
            BuildContext routeContext,
            ) =>
        const AddWantedSkillScreen(),
      ),
    );

    if (!mounted ||
        changed != true) {
      return;
    }

    await _loadAllSkills();
  }

  // ============================================================
  // EDIT OFFERED
  // ============================================================

  Future<void> _openEditOfferedSkill(
      ManagedSkill managedSkill,
      ) async {
    final bool? changed =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (
            BuildContext routeContext,
            ) =>
            EditSkillScreen(
              managedSkill:
              managedSkill,
            ),
      ),
    );

    if (!mounted ||
        changed != true) {
      return;
    }

    await _loadAllSkills();
  }

  // ============================================================
  // EDIT WANTED
  // ============================================================

  Future<void> _openEditWantedSkill(
      ManagedWantedSkill managedWantedSkill,
      ) async {
    final bool? changed =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (
            BuildContext routeContext,
            ) =>
            EditWantedSkillScreen(
              managedWantedSkill:
              managedWantedSkill,
            ),
      ),
    );

    if (!mounted ||
        changed != true) {
      return;
    }

    await _loadAllSkills();
  }

  // ============================================================
  // DELETE OFFERED
  // ============================================================

  Future<void> _confirmDeleteOfferedSkill(
      ManagedSkill managedSkill,
      ) async {
    final bool? confirmed =
    await _showDeleteDialog(
      title:
      'Delete offered skill?',
      message:
      'Remove "${managedSkill.skill.title}" from the skills you offer?',
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    try {
      final String userId =
      _currentUserService.requireUserId();

      await _offeredRepository
          .deleteOfferedSkill(
        userId:
        userId,
        userSkillId:
        managedSkill.userSkill.id,
      );

      if (!mounted) {
        return;
      }

      await _loadAllSkills();

      if (!mounted) {
        return;
      }

      _showMessage(
        '${managedSkill.skill.title} removed.',
      );
    } on CurrentUserServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.toString(),
      );
    }
  }

  // ============================================================
  // DELETE WANTED
  // ============================================================

  Future<void> _confirmDeleteWantedSkill(
      ManagedWantedSkill managedWantedSkill,
      ) async {
    final bool? confirmed =
    await _showDeleteDialog(
      title:
      'Remove learning interest?',
      message:
      'Remove "${managedWantedSkill.skill.title}" from the skills you want to learn?',
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    try {
      final String userId =
      _currentUserService.requireUserId();

      await _wantedRepository
          .deleteWantedSkill(
        userId:
        userId,
        userSkillId:
        managedWantedSkill.userSkill.id,
      );

      if (!mounted) {
        return;
      }

      await _loadAllSkills();

      if (!mounted) {
        return;
      }

      _showMessage(
        '${managedWantedSkill.skill.title} removed from your learning interests.',
      );
    } on CurrentUserServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    } on WantedSkillsRepositoryException catch (error) {
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
        'Could not remove the learning interest. Please try again.',
      );
    }
  }

  // ============================================================
  // DELETE DIALOG
  // ============================================================

  Future<bool?> _showDeleteDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
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
              20,
            ),
          ),
          icon:
          Container(
            width: 58,
            height: 58,
            decoration:
            BoxDecoration(
              color:
              _isDarkMode
                  ? AppTheme.error
                  .withValues(
                alpha: 0.16,
              )
                  : const Color(
                0xFFFFEFEF,
              ),
              borderRadius:
              BorderRadius.circular(
                18,
              ),
            ),
            child:
            const Icon(
              Icons.delete_outline_rounded,
              color:
              AppTheme.error,
              size: 30,
            ),
          ),
          title:
          Text(
            title,
            textAlign:
            TextAlign.center,
            style:
            AppTextStyles
                .cardTitle
                .copyWith(
              color:
              _textColor,
            ),
          ),
          content:
          Text(
            message,
            textAlign:
            TextAlign.center,
            style:
            AppTextStyles
                .bodyMuted
                .copyWith(
              color:
              _mutedColor,
            ),
          ),
          actionsAlignment:
          MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
              const Text(
                'CANCEL',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                AppTheme.error,
                foregroundColor:
                Colors.white,
                elevation:
                0,
              ),
              child:
              const Text(
                'DELETE',
              ),
            ),
          ],
        );
      },
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
        child:
        Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 44,
              color:
              _mutedColor,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              'Could not load your skills',
              style:
              AppTextStyles
                  .cardTitle
                  .copyWith(
                color:
                _textColor,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              _error ??
                  'Something went wrong while loading your skills.',
              textAlign:
              TextAlign.center,
              style:
              AppTextStyles
                  .bodyMuted
                  .copyWith(
                color:
                _mutedColor,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            OutlinedButton.icon(
              onPressed:
              _loadAllSkills,
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