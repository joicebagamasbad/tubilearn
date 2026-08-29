import 'package:flutter/material.dart';

import '../model/repositories/my_skills_repository.dart';
import '../services/current_user_service.dart';

import 'add_skill_screen.dart';
import 'edit_skill_screen.dart';

class MySkillsScreen extends StatefulWidget {
  const MySkillsScreen({
    super.key,
  });

  @override
  State<MySkillsScreen> createState() =>
      _MySkillsScreenState();
}

class _MySkillsScreenState
    extends State<MySkillsScreen> {
  static const Color primary =
  Color(0xFF5B5FEF);

  static const Color darkText =
  Color(0xFF171A2B);

  static const Color mutedText =
  Color(0xFF8A8FA3);

  static const Color background =
  Color(0xFFF9F9FF);

  static const Color border =
  Color(0xFFE8E8F2);

  final MySkillsRepository _repository =
      MySkillsRepository.instance;

  final CurrentUserService _currentUser =
      CurrentUserService.instance;

  List<ManagedSkill> _skills = [];

  bool _loading = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    _loadSkills();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadSkills() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final List<ManagedSkill> skills =
      await _repository.getOfferedSkills(
        _currentUser.userId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _skills = skills;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = error.toString();
      });
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
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primary,
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_skills.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: primary,
      onRefresh: _loadSkills,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding:
        const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          30,
        ),
        children: [
          _buildTubiIntro(),

          const SizedBox(height: 16),

          ..._skills.map(
                (managedSkill) {
              return Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 14,
                ),
                child: _buildSkillCard(
                  managedSkill,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 64,
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
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: primary,
            ),
          ),

          const Expanded(
            child: Center(
              child: Text(
                'My Skills',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w800,
                  color: darkText,
                ),
              ),
            ),
          ),

          TextButton.icon(
            onPressed: _openAddSkill,
            icon: const Icon(
              Icons.add_rounded,
              size: 15,
              color: primary,
            ),
            label: const Text(
              'ADD SKILL',
              style: TextStyle(
                fontSize: 9,
                fontWeight:
                FontWeight.w700,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _buildTubiIntro() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Manage your skills',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w800,
                  color: darkText,
                ),
              ),

              SizedBox(height: 4),

              Text(
                'Update, add, or review the skills you share.',
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.4,
                  color: mutedText,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Image.asset(
          'assets/images/mascot/tubi_checking.png',
          width: 66,
          height: 66,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  // ============================================================
  // SKILL CARD
  // ============================================================

  Widget _buildSkillCard(
      ManagedSkill managedSkill,
      ) {
    final skill =
        managedSkill.skill;

    final userSkill =
        managedSkill.userSkill;

    final bool customSkill =
    managedSkill
        .metadataCanBeEditedBy(
      _currentUser.userId,
    );

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border:
        Border.all(
          color: border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.025,
            ),
            blurRadius: 10,
            offset:
            const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFF3F0FF,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  skill.icon,
                  size: 30,
                  color: primary,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            skill.title,
                            style:
                            const TextStyle(
                              fontSize: 14,
                              fontWeight:
                              FontWeight
                                  .w800,
                              color:
                              darkText,
                            ),
                          ),
                        ),

                        if (customSkill)
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              const Color(
                                0xFFF3F0FF,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                20,
                              ),
                            ),
                            child:
                            const Text(
                              'CUSTOM',
                              style:
                              TextStyle(
                                fontSize: 7.5,
                                fontWeight:
                                FontWeight
                                    .w700,
                                color:
                                primary,
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
                        const Icon(
                          Icons
                              .bar_chart_rounded,
                          size: 14,
                          color: primary,
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        const Text(
                          'Level:',
                          style:
                          TextStyle(
                            fontSize: 9.5,
                            color:
                            mutedText,
                          ),
                        ),

                        const SizedBox(
                          width: 4,
                        ),

                        Text(
                          userSkill.level,
                          style:
                          const TextStyle(
                            fontSize: 9.5,
                            fontWeight:
                            FontWeight
                                .w600,
                            color: darkText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .schedule_rounded,
                          size: 14,
                          color: primary,
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        const Text(
                          'Availability:',
                          style:
                          TextStyle(
                            fontSize: 9.5,
                            color:
                            mutedText,
                          ),
                        ),

                        const SizedBox(
                          width: 4,
                        ),

                        Expanded(
                          child: Text(
                            userSkill
                                .availability,
                            style:
                            const TextStyle(
                              fontSize:
                              9.5,
                              fontWeight:
                              FontWeight
                                  .w600,
                              color:
                              darkText,
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

          const SizedBox(
            height: 14,
          ),

          const Divider(
            height: 1,
            color: border,
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
                  _openEditSkill(
                    managedSkill,
                  );
                },
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: primary,
                ),
                label:
                const Text(
                  'EDIT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight:
                    FontWeight
                        .w700,
                    color: primary,
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              TextButton.icon(
                onPressed: () {
                  _showDeleteDialog(
                    managedSkill,
                  );
                },
                icon: const Icon(
                  Icons
                      .delete_outline_rounded,
                  size: 15,
                  color:
                  Colors.redAccent,
                ),
                label:
                const Text(
                  'DELETE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight:
                    FontWeight
                        .w700,
                    color:
                    Colors.redAccent,
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
  // ADD
  // ============================================================

  Future<void> _openAddSkill() async {
    final bool? changed =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const AddSkillScreen(),
      ),
    );

    if (changed == true) {
      await _loadSkills();
    }
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _openEditSkill(
      ManagedSkill managedSkill,
      ) async {
    final bool? changed =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditSkillScreen(
              managedSkill:
              managedSkill,
            ),
      ),
    );

    if (changed == true) {
      await _loadSkills();
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  void _showDeleteDialog(
      ManagedSkill managedSkill,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) {
        bool deleting = false;

        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            return AlertDialog(
              backgroundColor:
              Colors.white,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
              ),
              icon: Container(
                width: 58,
                height: 58,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFFFEFEF,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                ),
                child:
                const Icon(
                  Icons
                      .delete_outline_rounded,
                  color:
                  Colors.redAccent,
                  size: 30,
                ),
              ),
              title:
              const Text(
                'Delete Skill?',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                  FontWeight.w800,
                  color: darkText,
                ),
              ),
              content: Text(
                'Remove "${managedSkill.skill.title}" from your offered skills?',
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 10.5,
                  height: 1.5,
                  color: mutedText,
                ),
              ),
              actionsAlignment:
              MainAxisAlignment
                  .center,
              actions: [
                OutlinedButton(
                  onPressed:
                  deleting
                      ? null
                      : () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                  const Text(
                    'CANCEL',
                  ),
                ),

                ElevatedButton(
                  onPressed:
                  deleting
                      ? null
                      : () async {
                    setDialogState(
                          () {
                        deleting =
                        true;
                      },
                    );

                    try {
                      await _repository
                          .deleteOfferedSkill(
                        userId:
                        _currentUser
                            .userId,
                        userSkillId:
                        managedSkill
                            .userSkill
                            .id,
                      );

                      if (!mounted) {
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                      );

                      await _loadSkills();

                      if (!mounted) {
                        return;
                      }

                      ScaffoldMessenger
                          .of(
                        context,
                      )
                          .showSnackBar(
                        SnackBar(
                          content:
                          Text(
                            '${managedSkill.skill.title} removed.',
                          ),
                        ),
                      );
                    } catch (error) {
                      setDialogState(
                            () {
                          deleting =
                          false;
                        },
                      );

                      if (!mounted) {
                        return;
                      }

                      ScaffoldMessenger
                          .of(
                        context,
                      )
                          .showSnackBar(
                        SnackBar(
                          content:
                          Text(
                            error
                                .toString(),
                          ),
                        ),
                      );
                    }
                  },
                  style:
                  ElevatedButton
                      .styleFrom(
                    backgroundColor:
                    Colors
                        .redAccent,
                    foregroundColor:
                    Colors.white,
                    minimumSize:
                    const Size(
                      90,
                      40,
                    ),
                  ),
                  child: deleting
                      ? const SizedBox(
                    width: 17,
                    height: 17,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Text(
                    'DELETE',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 35,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/mascot/tubi_confused.png',
              width: 130,
              height: 130,
            ),

            const SizedBox(
              height: 15,
            ),

            const Text(
              'No skills yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w800,
                color: darkText,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            const Text(
              'Add a skill you can share with the TubiLearn community.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.5,
                color: mutedText,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed:
              _openAddSkill,
              style:
              ElevatedButton
                  .styleFrom(
                backgroundColor:
                primary,
                foregroundColor:
                Colors.white,
                minimumSize:
                const Size(
                  140,
                  44,
                ),
              ),
              child:
              const Text(
                'ADD A SKILL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                  FontWeight
                      .w800,
                ),
              ),
            ),
          ],
        ),
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
          30,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              size: 46,
              color:
              Colors.redAccent,
            ),

            const SizedBox(
              height: 14,
            ),

            const Text(
              'Could not load your skills.',
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight.w800,
                color: darkText,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              _error ?? '',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize: 10,
                color: mutedText,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            ElevatedButton(
              onPressed:
              _loadSkills,
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
}