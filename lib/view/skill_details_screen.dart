import 'package:flutter/material.dart';

class SkillDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> skill;

  const SkillDetailsScreen({
    super.key,
    required this.skill,
  });

  static const Color primary = Color(0xFF5B5FEF);
  static const Color darkText = Color(0xFF171A2B);
  static const Color mutedText = Color(0xFF8A8FA3);
  static const Color background = Color(0xFFF9F9FF);
  static const Color border = Color(0xFFE8E8F2);

  @override
  Widget build(BuildContext context) {
    final List<String> learnings =
    List<String>.from(
      skill['learnings'] ?? [],
    );

    final List<Map<String, dynamic>> providers =
    List<Map<String, dynamic>>.from(
      (skill['providers'] ?? []).map(
            (provider) =>
        Map<String, dynamic>.from(
          provider,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),

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
                    _buildSkillHeader(),

                    const SizedBox(height: 20),

                    _buildQuickInfo(),

                    const SizedBox(height: 24),

                    const Text(
                      'About this skill',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w800,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      skill['description']
                      as String,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.55,
                        color: mutedText,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'What you can learn',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w800,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 10),

                    ...learnings.map(
                          (item) => Padding(
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
                                top: 3,
                              ),
                              width: 20,
                              height: 20,
                              decoration:
                              BoxDecoration(
                                color: const Color(
                                  0xFFF0EFFF,
                                ),
                                borderRadius:
                                BorderRadius.circular(
                                  7,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 13,
                                color: primary,
                              ),
                            ),

                            const SizedBox(
                              width: 9,
                            ),

                            Expanded(
                              child: Text(
                                item,
                                style:
                                const TextStyle(
                                  fontSize: 10.5,
                                  height: 1.45,
                                  color: darkText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildPrerequisiteCard(),

                    const SizedBox(height: 28),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'People offering this skill',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                              FontWeight.w800,
                              color: darkText,
                            ),
                          ),
                        ),

                        Text(
                          '${providers.length} available',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Choose someone based on availability, experience, and what they want to learn in exchange.',
                      style: TextStyle(
                        fontSize: 9.5,
                        height: 1.45,
                        color: mutedText,
                      ),
                    ),

                    const SizedBox(height: 14),

                    ...providers.map(
                          (provider) => Padding(
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

  Widget _buildTopBar(
      BuildContext context,
      ) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: const BoxDecoration(
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
              Navigator.pop(context);
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
                'Skill Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w800,
                  color: darkText,
                ),
              ),
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.favorite_border_rounded,
              size: 20,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        10,
        16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFFF),
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: const Color(
            0xFFE4E0FF,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: Icon(
              skill['icon'] as IconData,
              color: primary,
              size: 30,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  skill['title'] as String,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.w800,
                    color: darkText,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  skill['category'] as String,
                  style: const TextStyle(
                    fontSize: 10,
                    color: mutedText,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Text(
                    skill['level'] as String,
                    style:
                    const TextStyle(
                      fontSize: 8.5,
                      fontWeight:
                      FontWeight.w700,
                      color: primary,
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

  Widget _buildQuickInfo() {
    return Row(
      children: [
        Expanded(
          child: _infoBox(
            icon:
            Icons.schedule_outlined,
            label: 'Session',
            value:
            skill['sessionLength']
            as String,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _infoBox(
            icon:
            Icons.language_rounded,
            label: 'Language',
            value:
            skill['language']
            as String,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _infoBox(
            icon:
            Icons.laptop_mac_rounded,
            label: 'Mode',
            value: skill['mode']
            as String,
          ),
        ),
      ],
    );
  }

  Widget _infoBox({
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color: border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: primary,
            size: 19,
          ),

          const SizedBox(height: 6),

          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: mutedText,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            maxLines: 2,
            textAlign:
            TextAlign.center,
            overflow:
            TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight:
              FontWeight.w700,
              color: darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrerequisiteCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
        const Color(0xFFFFFAEE),
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color:
          const Color(0xFFFFE8AF),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color:
            Color(0xFFE5A72C),
            size: 19,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'What you need',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight:
                    FontWeight.w800,
                    color: darkText,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  skill['prerequisite']
                  as String,
                  style: const TextStyle(
                    fontSize: 9.5,
                    height: 1.45,
                    color: mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(
      BuildContext context,
      Map<String, dynamic> provider,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color: border,
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
                  Color(0xFFFFB45E),
                  shape:
                  BoxShape.circle,
                ),
                alignment:
                Alignment.center,
                child: Text(
                  provider['initials']
                  as String,
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

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider['name']
                      as String,
                      style:
                      const TextStyle(
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w800,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${provider['city']} • ${provider['level']}',
                      style:
                      const TextStyle(
                        fontSize: 9.5,
                        color:
                        mutedText,
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
                    color: Color(
                      0xFFFFB547,
                    ),
                  ),

                  const SizedBox(width: 3),

                  Text(
                    provider['rating']
                        .toString(),
                    style:
                    const TextStyle(
                      fontSize: 10,
                      fontWeight:
                      FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.swap_horiz_rounded,
                size: 15,
                color: primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${provider['completedSwaps']} completed skill swaps',
                  style:
                  const TextStyle(
                    fontSize: 9.5,
                    color: darkText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              const Icon(
                Icons.school_outlined,
                size: 15,
                color: primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Wants to learn: ${provider['wantsToLearn']}',
                  style:
                  const TextStyle(
                    fontSize: 9.5,
                    color: darkText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child:
                  OutlinedButton(
                    onPressed: () {
                      final profileData =
                      <String, dynamic>{
                        ...provider,
                        'reviewCount':
                        provider[
                        'reviewCount'] ??
                            8,
                        'responseRate':
                        provider[
                        'responseRate'] ??
                            92,
                        'memberSince':
                        provider[
                        'memberSince'] ??
                            '2026',
                        'preferredMode':
                        provider[
                        'preferredMode'] ??
                            skill[
                            'mode'],
                        'teachingStyle':
                        provider[
                        'teachingStyle'] ??
                            'Practical, beginner-friendly, and hands-on.',
                        'bio': provider[
                        'bio'] ??
                            'I enjoy sharing practical skills and learning from other people through skill exchange.',
                        'offeredSkills':
                        provider[
                        'offeredSkills'] ??
                            [
                              skill[
                              'title']
                            ],
                        'wantedSkills':
                        provider[
                        'wantedSkills'] ??
                            [
                              provider[
                              'wantsToLearn']
                            ],
                      };

                      Navigator.pushNamed(
                        context,
                        '/user-profile',
                        arguments:
                        profileData,
                      );
                    },
                    style:
                    OutlinedButton
                        .styleFrom(
                      foregroundColor:
                      primary,
                      side:
                      const BorderSide(
                        color: primary,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          11,
                        ),
                      ),
                    ),
                    child:
                    const Text(
                      'VIEW PROFILE',
                      style:
                      TextStyle(
                        fontSize: 8.5,
                        fontWeight:
                        FontWeight
                            .w800,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: SizedBox(
                  height: 40,
                  child:
                  ElevatedButton(
                    onPressed: () {
                      _showSwapRequestDialog(
                        context,
                        provider,
                      );
                    },
                    style:
                    ElevatedButton
                        .styleFrom(
                      elevation: 0,
                      backgroundColor:
                      primary,
                      foregroundColor:
                      Colors.white,
                      minimumSize:
                      const Size(
                        0,
                        40,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          11,
                        ),
                      ),
                    ),
                    child:
                    const Text(
                      'REQUEST SWAP',
                      style:
                      TextStyle(
                        fontSize: 8.5,
                        fontWeight:
                        FontWeight
                            .w800,
                      ),
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

  void _showSwapRequestDialog(
      BuildContext context,
      Map<String, dynamic> provider,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
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
          title: const Text(
            'Request a Skill Swap?',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w800,
              color: darkText,
            ),
          ),
          content: Text(
            'You’re requesting to learn ${skill['title']} from ${provider['name']}.\n\nThey are currently interested in learning ${provider['wantsToLearn']} in exchange.',
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.5,
              color: mutedText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
              const Text('CANCEL'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Swap request sent!',
                    ),
                  ),
                );
              },
              style:
              ElevatedButton
                  .styleFrom(
                backgroundColor:
                primary,
                foregroundColor:
                Colors.white,
                minimumSize:
                const Size(
                  90,
                  40,
                ),
              ),
              child: const Text(
                'SEND REQUEST',
              ),
            ),
          ],
        );
      },
    );
  }
}