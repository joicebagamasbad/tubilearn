import 'package:flutter/material.dart';

import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color primary = Color(0xFF5B5FEF);
  static const Color darkText = Color(0xFF171A2B);
  static const Color mutedText = Color(0xFF8A8FA3);
  static const Color background = Color(0xFFF9F9FF);
  static const Color border = Color(0xFFE8E8F2);

  @override
  Widget build(BuildContext context) {
    final conversations = [
      ...ChatService.instance.conversations,
    ];

    conversations.sort((a, b) {
      final aTime = a.messages.isEmpty
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : a.messages.last.sentAt;

      final bTime = b.messages.isEmpty
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : b.messages.last.sentAt;

      return bTime.compareTo(aTime);
    });

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            Expanded(
              child: conversations.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  30,
                ),
                itemCount: conversations.length,
                separatorBuilder: (_, __) {
                  return const SizedBox(height: 12);
                },
                itemBuilder: (context, index) {
                  final conversation = conversations[index];

                  final latestMessage =
                  conversation.messages.isEmpty
                      ? null
                      : conversation.messages.last;

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        '/conversation',
                        arguments: conversation.id,
                      );

                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.025,
                            ),
                            blurRadius: 10,
                            offset: const Offset(
                              0,
                              4,
                            ),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFB45E),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  conversation.initials,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 13,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF67),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        conversation.userName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                          FontWeight.w800,
                                          color: darkText,
                                        ),
                                      ),
                                    ),

                                    if (latestMessage != null)
                                      Text(
                                        _formatListTime(
                                          latestMessage.sentAt,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 8.5,
                                          color: mutedText,
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  conversation.city,
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    color: mutedText,
                                  ),
                                ),

                                const SizedBox(height: 7),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 14,
                                      color: primary,
                                    ),

                                    const SizedBox(width: 5),

                                    Expanded(
                                      child: Text(
                                        '${conversation.skillWanted} ↔ ${conversation.skillOffered}',
                                        maxLines: 1,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight:
                                          FontWeight.w600,
                                          color: primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        latestMessage == null
                                            ? 'No messages yet'
                                            : latestMessage.text,
                                        maxLines: 1,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: mutedText,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                        _statusBackground(
                                          conversation.status,
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                      child: Text(
                                        conversation.status,
                                        style: TextStyle(
                                          fontSize: 7.5,
                                          fontWeight:
                                          FontWeight.w700,
                                          color: _statusColor(
                                            conversation.status,
                                          ),
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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
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
                'Messages',
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
              Icons.search_rounded,
              size: 20,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 36,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/mascot/tubi_sleeping.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 14),

            const Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Find someone with a skill you want to learn and start a conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.5,
                color: mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusBackground(
      String status,
      ) {
    switch (status) {
      case 'Scheduled':
        return const Color(0xFFEAF8EE);

      case 'Planning':
        return const Color(0xFFFFF5E8);

      case 'New':
        return const Color(0xFFF0EFFF);

      default:
        return const Color(0xFFF2F2F6);
    }
  }

  Color _statusColor(
      String status,
      ) {
    switch (status) {
      case 'Scheduled':
        return const Color(0xFF3D9158);

      case 'Planning':
        return const Color(0xFFB97820);

      case 'New':
        return primary;

      default:
        return mutedText;
    }
  }

  String _formatListTime(
      DateTime dateTime,
      ) {
    final DateTime now = DateTime.now();

    final DateTime today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime messageDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    final int difference = today
        .difference(
      messageDate,
    )
        .inDays;

    if (difference == 0) {
      return _formatClockTime(
        dateTime,
      );
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    if (difference < 7) {
      return _weekdayName(
        dateTime.weekday,
      );
    }

    final List<String> months = [
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

    if (dateTime.year == now.year) {
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    }

    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatClockTime(
      DateTime dateTime,
      ) {
    int hour = dateTime.hour;

    final int minute =
        dateTime.minute;

    final String period =
    hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    final String formattedMinute =
    minute
        .toString()
        .padLeft(
      2,
      '0',
    );

    return '$hour:$formattedMinute $period';
  }

  String _weekdayName(
      int weekday,
      ) {
    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return weekdays[weekday - 1];
  }
}