import 'package:flutter/material.dart';

import '../services/chat_service.dart';

class UserProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserProfileScreen({
    super.key,
    required this.user,
  });

  static const Color primary = Color(0xFF5B5FEF);
  static const Color darkText = Color(0xFF171A2B);
  static const Color mutedText = Color(0xFF8A8FA3);
  static const Color background = Color(0xFFF9F9FF);
  static const Color border = Color(0xFFE8E8F2);

  @override
  Widget build(BuildContext context) {
    final List<String> offeredSkills =
    List<String>.from(user['offeredSkills'] ?? []);

    final List<String> wantedSkills =
    List<String>.from(user['wantedSkills'] ?? []);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),

                    const SizedBox(height: 22),

                    _buildStatsRow(),

                    const SizedBox(height: 24),

                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      user['bio'] as String,
                      style: const TextStyle(
                        fontSize: 10.5,
                        height: 1.55,
                        color: mutedText,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildInfoCard(),

                    const SizedBox(height: 24),

                    const Text(
                      'Skills offered',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: offeredSkills.map((skill) {
                        return _skillChip(
                          skill,
                          const Color(0xFFF0EFFF),
                          primary,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Wants to learn',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: wantedSkills.map((skill) {
                        return _skillChip(
                          skill,
                          const Color(0xFFFFF4E8),
                          const Color(0xFFCA7A1B),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    _buildTrustCard(),

                    const SizedBox(height: 26),

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

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
                'Profile',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
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

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: const BoxDecoration(
            color: Color(0xFFFFB45E),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            user['initials'] as String,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['name'] as String,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: mutedText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user['city'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      color: mutedText,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Color(0xFFFFB547),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${user['rating']}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '(${user['reviewCount']} reviews)',
                    style: const TextStyle(
                      fontSize: 9,
                      color: mutedText,
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statBox(
            '${user['completedSwaps']}',
            'Completed swaps',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statBox(
            '${user['responseRate']}%',
            'Response rate',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statBox(
            user['memberSince'] as String,
            'Member since',
          ),
        ),
      ],
    );
  }

  Widget _statBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 8,
              color: mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          _infoRow(
            Icons.language_rounded,
            'Languages',
            user['language'] as String,
          ),
          const Divider(height: 22, color: border),
          _infoRow(
            Icons.schedule_rounded,
            'Availability',
            user['availability'] as String,
          ),
          const Divider(height: 22, color: border),
          _infoRow(
            Icons.devices_rounded,
            'Preferred mode',
            user['preferredMode'] as String,
          ),
          const Divider(height: 22, color: border),
          _infoRow(
            Icons.school_outlined,
            'Teaching style',
            user['teachingStyle'] as String,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: primary,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 8.5,
                  color: mutedText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _skillChip(
      String skill,
      Color backgroundColor,
      Color textColor,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTrustCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FBF6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFD9F0E0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile & trust',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
          ),

          const SizedBox(height: 10),

          _trustRow('Email verified'),
          const SizedBox(height: 7),
          _trustRow('Profile completed'),
          const SizedBox(height: 7),
          _trustRow(
            '${user['completedSwaps']} completed exchanges',
          ),
        ],
      ),
    );
  }

  Widget _trustRow(String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: Color(0xFF47A568),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontSize: 9.5,
            color: darkText,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context,
      List<String> offeredSkills,
      List<String> wantedSkills,
      ) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                final conversation =
                ChatService.instance.getOrCreateConversation(
                  userName: user['name'] as String,
                  initials: user['initials'] as String,
                  city: user['city'] as String,
                  skillWanted: offeredSkills.isEmpty
                      ? 'Skill'
                      : offeredSkills.first,
                  skillOffered: wantedSkills.isEmpty
                      ? 'Skill'
                      : wantedSkills.first,
                );

                Navigator.pushNamed(
                  context,
                  '/conversation',
                  arguments: conversation.id,
                );
              },
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 16,
              ),
              label: const Text(
                'MESSAGE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: const BorderSide(
                  color: primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                _showSwapDialog(context);
              },
              icon: const Icon(
                Icons.swap_horiz_rounded,
                size: 17,
              ),
              label: const Text(
                'REQUEST SWAP',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSwapDialog(BuildContext context) {
    final List<String> wantedSkills =
    List<String>.from(
      user['wantedSkills'] ?? [],
    );

    final String wantedText =
    wantedSkills.isEmpty
        ? 'another skill'
        : wantedSkills.first;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Request a Skill Swap?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
          ),
          content: Text(
            '${user['name']} is interested in learning $wantedText.\n\nYou can finalize the skill, schedule, and session mode through chat.',
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.5,
              color: mutedText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Swap request sent!',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
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