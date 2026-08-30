import 'package:flutter/material.dart';

import '../model/conversation.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
  });

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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

  final TextEditingController
  _searchController =
  TextEditingController();

  bool _isLoading = true;
  bool _isSearchVisible = false;

  String? _loadError;
  String? _openingConversationId;
  String? _deletingConversationId;

  bool get _hasPendingAction =>
      _openingConversationId != null ||
          _deletingConversationId != null;

  @override
  void initState() {
    super.initState();

    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadConversations() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      await ChatService.instance.initialize();

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } on ChatServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError =
        'Messages could not be loaded. Please try again.';
      });
    }
  }

  // ============================================================
  // CONVERSATION LIST
  // ============================================================

  List<Conversation> _visibleConversations() {
    final List<Conversation> conversations =
    <Conversation>[
      ...ChatService.instance.conversations,
    ];

    conversations.sort(
          (
          Conversation a,
          Conversation b,
          ) {
        final DateTime aTime =
        a.messages.isEmpty
            ? DateTime.fromMillisecondsSinceEpoch(
          0,
        )
            : a.messages.last.sentAt;

        final DateTime bTime =
        b.messages.isEmpty
            ? DateTime.fromMillisecondsSinceEpoch(
          0,
        )
            : b.messages.last.sentAt;

        return bTime.compareTo(
          aTime,
        );
      },
    );

    final String query =
    _searchController.text
        .trim()
        .toLowerCase();

    if (query.isEmpty) {
      return conversations;
    }

    return conversations.where(
          (
          Conversation conversation,
          ) {
        return conversation.userName
            .toLowerCase()
            .contains(query) ||
            conversation.city
                .toLowerCase()
                .contains(query) ||
            conversation.skillWanted
                .toLowerCase()
                .contains(query) ||
            conversation.skillOffered
                .toLowerCase()
                .contains(query) ||
            conversation.status
                .toLowerCase()
                .contains(query);
      },
    ).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final List<Conversation> conversations =
    _visibleConversations();

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            if (_isSearchVisible)
              _buildSearchBar(),

            Expanded(
              child: _buildBody(
                conversations,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      List<Conversation> conversations,
      ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primary,
        ),
      );
    }

    if (_loadError != null) {
      return _buildErrorState();
    }

    if (conversations.isEmpty) {
      if (_searchController.text
          .trim()
          .isNotEmpty) {
        return _buildNoSearchResults();
      }

      return _buildEmptyState();
    }

    return ListView.separated(
      physics:
      const BouncingScrollPhysics(),
      padding:
      const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        30,
      ),
      itemCount:
      conversations.length,
      separatorBuilder:
          (
          _,
          _,
          ) {
        return const SizedBox(
          height: 12,
        );
      },
      itemBuilder:
          (
          BuildContext context,
          int index,
          ) {
        return _buildConversationCard(
          conversations[index],
        );
      },
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
            onPressed:
            _hasPendingAction
                ? null
                : () {
              Navigator.pop(
                context,
              );
            },
            icon: const Icon(
              Icons
                  .arrow_back_ios_new_rounded,
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
                  fontWeight:
                  FontWeight.w800,
                  color: darkText,
                ),
              ),
            ),
          ),

          IconButton(
            onPressed:
            _hasPendingAction
                ? null
                : _toggleSearch,
            icon: Icon(
              _isSearchVisible
                  ? Icons.close_rounded
                  : Icons.search_rounded,
              size: 20,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding:
      const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        12,
      ),
      child: TextField(
        controller:
        _searchController,
        autofocus: true,
        textInputAction:
        TextInputAction.search,
        onChanged: (_) {
          if (!mounted) {
            return;
          }

          setState(() {});
        },
        decoration:
        InputDecoration(
          hintText:
          'Search conversations',
          hintStyle:
          const TextStyle(
            fontSize: 12,
            color: mutedText,
          ),
          prefixIcon:
          const Icon(
            Icons.search_rounded,
            size: 19,
            color: mutedText,
          ),
          suffixIcon:
          _searchController
              .text
              .isEmpty
              ? null
              : IconButton(
            onPressed: () {
              _searchController
                  .clear();

              setState(() {});
            },
            icon:
            const Icon(
              Icons
                  .clear_rounded,
              size: 18,
            ),
          ),
          filled: true,
          fillColor:
          background,
          contentPadding:
          const EdgeInsets
              .symmetric(
            vertical: 12,
          ),
          border:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            borderSide:
            BorderSide.none,
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            borderSide:
            const BorderSide(
              color: border,
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            borderSide:
            const BorderSide(
              color: primary,
            ),
          ),
        ),
      ),
    );
  }

  void _toggleSearch() {
    FocusScope.of(
      context,
    ).unfocus();

    setState(() {
      _isSearchVisible =
      !_isSearchVisible;

      if (!_isSearchVisible) {
        _searchController.clear();
      }
    });
  }

  // ============================================================
  // CONVERSATION CARD
  // ============================================================

  Widget _buildConversationCard(
      Conversation conversation,
      ) {
    final latestMessage =
    conversation.messages.isEmpty
        ? null
        : conversation.messages.last;

    final bool isOpening =
        _openingConversationId ==
            conversation.id;

    final bool isDeleting =
        _deletingConversationId ==
            conversation.id;

    final bool isBusy =
        isOpening || isDeleting;

    return InkWell(
      borderRadius:
      BorderRadius.circular(
        16,
      ),
      onTap:
      _hasPendingAction
          ? null
          : () {
        _openConversation(
          conversation,
        );
      },
      onLongPress:
      _hasPendingAction
          ? null
          : () {
        _showConversationOptions(
          conversation,
        );
      },
      child: Container(
        padding:
        const EdgeInsets.all(
          14,
        ),
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          border: Border.all(
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
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior:
              Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration:
                  const BoxDecoration(
                    color: Color(
                      0xFFFFB45E,
                    ),
                    shape:
                    BoxShape.circle,
                  ),
                  alignment:
                  Alignment.center,
                  child: Text(
                    conversation.initials,
                    style:
                    const TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w800,
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
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFF4CAF67,
                      ),
                      shape:
                      BoxShape.circle,
                      border:
                      Border.all(
                        color:
                        Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              width: 12,
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
                          conversation
                              .userName,
                          style:
                          const TextStyle(
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w800,
                            color:
                            darkText,
                          ),
                        ),
                      ),

                      if (isBusy)
                        const SizedBox(
                          width: 15,
                          height: 15,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primary,
                          ),
                        )
                      else if (latestMessage !=
                          null)
                        Text(
                          _formatListTime(
                            latestMessage
                                .sentAt,
                          ),
                          style:
                          const TextStyle(
                            fontSize: 8.5,
                            color:
                            mutedText,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    conversation.city,
                    style:
                    const TextStyle(
                      fontSize: 8.5,
                      color: mutedText,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .swap_horiz_rounded,
                        size: 14,
                        color: primary,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Expanded(
                        child: Text(
                          '${conversation.skillWanted} ↔ ${conversation.skillOffered}',
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 9,
                            fontWeight:
                            FontWeight.w600,
                            color: primary,
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
                      Expanded(
                        child: Text(
                          latestMessage ==
                              null
                              ? 'No messages yet'
                              : latestMessage
                              .text,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 10,
                            color:
                            mutedText,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          _statusBackground(
                            conversation
                                .status,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            12,
                          ),
                        ),
                        child: Text(
                          conversation.status,
                          style:
                          TextStyle(
                            fontSize: 7.5,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            _statusColor(
                              conversation
                                  .status,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 2,
                      ),

                      IconButton(
                        visualDensity:
                        VisualDensity
                            .compact,
                        constraints:
                        const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding:
                        EdgeInsets.zero,
                        onPressed:
                        _hasPendingAction
                            ? null
                            : () {
                          _showConversationOptions(
                            conversation,
                          );
                        },
                        icon:
                        const Icon(
                          Icons
                              .more_vert_rounded,
                          size: 17,
                          color:
                          mutedText,
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
  }

  // ============================================================
  // OPEN CONVERSATION
  // ============================================================

  Future<void> _openConversation(
      Conversation conversation,
      ) async {
    if (_hasPendingAction) {
      return;
    }

    setState(() {
      _openingConversationId =
          conversation.id;
    });

    try {
      await Navigator.pushNamed(
        context,
        '/conversation',
        arguments:
        conversation.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Conversation could not be opened. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingConversationId =
          null;
        });
      }
    }
  }

  // ============================================================
  // OPTIONS
  // ============================================================

  Future<void> _showConversationOptions(
      Conversation conversation,
      ) async {
    if (_hasPendingAction) {
      return;
    }

    final String? action =
    await showModalBottomSheet<String>(
      context: context,
      backgroundColor:
      Colors.white,
      showDragHandle: true,
      builder:
          (
          BuildContext sheetContext,
          ) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.only(
              bottom: 12,
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                ListTile(
                  leading:
                  const Icon(
                    Icons
                        .chat_bubble_outline_rounded,
                    color: primary,
                  ),
                  title: const Text(
                    'Open conversation',
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      'open',
                    );
                  },
                ),

                ListTile(
                  leading:
                  const Icon(
                    Icons.delete_outline_rounded,
                    color:
                    Colors.redAccent,
                  ),
                  title: const Text(
                    'Delete conversation',
                    style:
                    TextStyle(
                      color:
                      Colors.redAccent,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      'delete',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted ||
        action == null) {
      return;
    }

    if (action == 'open') {
      await _openConversation(
        conversation,
      );

      return;
    }

    if (action == 'delete') {
      await _confirmDeleteConversation(
        conversation,
      );
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _confirmDeleteConversation(
      Conversation conversation,
      ) async {
    if (_hasPendingAction) {
      return;
    }

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          title:
          const Text(
            'Delete conversation?',
          ),
          content: Text(
            'This will permanently delete your conversation with ${conversation.userName} and its saved messages.',
          ),
          actions: [
            TextButton(
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

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
              const Text(
                'DELETE',
                style:
                TextStyle(
                  color:
                  Colors.redAccent,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    await _deleteConversation(
      conversation,
    );
  }

  Future<void> _deleteConversation(
      Conversation conversation,
      ) async {
    if (_hasPendingAction) {
      return;
    }

    setState(() {
      _deletingConversationId =
          conversation.id;
    });

    try {
      await ChatService.instance
          .deleteConversation(
        conversation.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {});

      _showSnackBar(
        'Conversation with ${conversation.userName} deleted.',
      );
    } on ChatServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Conversation could not be deleted. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingConversationId =
          null;
        });
      }
    }
  }

  // ============================================================
  // ERROR / EMPTY STATES
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 36,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              size: 48,
              color: mutedText,
            ),

            const SizedBox(
              height: 14,
            ),

            const Text(
              'Couldn’t load messages',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.w800,
                color: darkText,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              _loadError ??
                  'Something went wrong.',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize: 10.5,
                height: 1.5,
                color: mutedText,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            ElevatedButton(
              onPressed:
              _loadConversations,
              child:
              const Text(
                'RETRY',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 36,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/mascot/tubi_sleeping.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),

            const SizedBox(
              height: 14,
            ),

            const Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.w800,
                color: darkText,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'Find someone with a skill you want to learn and start a conversation.',
              textAlign:
              TextAlign.center,
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

  Widget _buildNoSearchResults() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 36,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: mutedText,
            ),

            const SizedBox(
              height: 14,
            ),

            const Text(
              'No conversations found',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.w800,
                color: darkText,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'Try searching by name, city, skill, or status.',
              textAlign:
              TextAlign.center,
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

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(
      String message,
      ) {
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
  // STATUS
  // ============================================================

  Color _statusBackground(
      String status,
      ) {
    switch (status) {
      case 'Scheduled':
        return const Color(
          0xFFEAF8EE,
        );

      case 'Planning':
        return const Color(
          0xFFFFF5E8,
        );

      case 'New':
        return const Color(
          0xFFF0EFFF,
        );

      default:
        return const Color(
          0xFFF2F2F6,
        );
    }
  }

  Color _statusColor(
      String status,
      ) {
    switch (status) {
      case 'Scheduled':
        return const Color(
          0xFF3D9158,
        );

      case 'Planning':
        return const Color(
          0xFFB97820,
        );

      case 'New':
        return primary;

      default:
        return mutedText;
    }
  }

  // ============================================================
  // TIME
  // ============================================================

  String _formatListTime(
      DateTime dateTime,
      ) {
    final DateTime now =
    DateTime.now();

    final DateTime today =
    DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime messageDate =
    DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    final int difference =
        today
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

    if (difference >= 0 &&
        difference < 7) {
      return _weekdayName(
        dateTime.weekday,
      );
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

    if (dateTime.year ==
        now.year) {
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    }

    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatClockTime(
      DateTime dateTime,
      ) {
    int hour =
        dateTime.hour;

    final int minute =
        dateTime.minute;

    final String period =
    hour >= 12
        ? 'PM'
        : 'AM';

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
    const List<String> weekdays =
    <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return weekdays[
    weekday - 1
    ];
  }
}