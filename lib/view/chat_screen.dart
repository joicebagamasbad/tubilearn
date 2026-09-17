import 'dart:io';

import 'package:flutter/material.dart';

import '../controller/chat_controller.dart';
import '../model/conversation.dart';
import '../model/user.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
  });

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> {
  static const Color primary =
      AppTheme.primary;

  final ChatController _controller =
  ChatController();

  final TextEditingController
  _searchController =
  TextEditingController();

  bool _isLoading = true;
  bool _isSearchVisible = false;

  String? _loadError;

  String? _openingConversationId;
  String? _archivingConversationId;

  List<ManagedConversation> _conversations =
  <ManagedConversation>[];

  bool get _hasPendingAction =>
      _openingConversationId != null ||
          _archivingConversationId != null;

  bool get _isDarkMode =>
      Theme.of(context).brightness ==
          Brightness.dark;

  Color get _surfaceColor =>
      Theme.of(context)
          .colorScheme
          .surface;

  Color get _surfaceVariantColor =>
      Theme.of(context)
          .colorScheme
          .surfaceContainerHighest;

  Color get _textColor =>
      Theme.of(context)
          .colorScheme
          .onSurface;

  Color get _mutedColor =>
      Theme.of(context)
          .colorScheme
          .onSurfaceVariant;

  Color get _borderColor =>
      Theme.of(context)
          .colorScheme
          .outlineVariant;

  // ============================================================
  // LIFECYCLE
  // ============================================================

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
      final ChatListSnapshot snapshot =
      await _controller
          .loadConversations();

      if (!mounted) {
        return;
      }

      setState(() {
        _conversations =
            snapshot.conversations;

        _isLoading = false;
        _loadError = null;
      });
    } on ChatControllerException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError =
            error.message;
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

  Future<void> _refreshConversations() async {
    try {
      final ChatListSnapshot snapshot =
      await _controller
          .refreshConversations();

      if (!mounted) {
        return;
      }

      setState(() {
        _conversations =
            snapshot.conversations;

        _loadError = null;
      });
    } on ChatControllerException catch (error) {
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
        'Messages could not be refreshed. Please try again.',
      );
    }
  }

  // ============================================================
  // FILTERED CONVERSATIONS
  // ============================================================

  List<ManagedConversation>
  _visibleConversations() {
    return _controller
        .filterConversations(
      conversations:
      _conversations,
      query:
      _searchController.text,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final List<ManagedConversation>
    conversations =
    _visibleConversations();

    return Scaffold(
      backgroundColor:
      Theme.of(context)
          .scaffoldBackgroundColor,
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
      List<ManagedConversation>
      conversations,
      ) {
    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(
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

    return RefreshIndicator(
      onRefresh:
      _refreshConversations,
      child: ListView.separated(
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
        itemCount:
        conversations.length,
        separatorBuilder: (
            BuildContext context,
            int index,
            ) {
          return const SizedBox(
            height: 12,
          );
        },
        itemBuilder: (
            BuildContext context,
            int index,
            ) {
          return _buildConversationCard(
            conversations[index],
          );
        },
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
      decoration: BoxDecoration(
        color:
        _surfaceColor,
        border: Border(
          bottom: BorderSide(
            color:
            _borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
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
            const Icon(
              Icons
                  .arrow_back_ios_new_rounded,
              size: 18,
              color: primary,
            ),
          ),

          Expanded(
            child: Center(
              child: Text(
                'Messages',
                style:
                TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight
                      .w800,
                  color:
                  _textColor,
                ),
              ),
            ),
          ),

          IconButton(
            tooltip:
            _isSearchVisible
                ? 'Close search'
                : 'Search conversations',
            onPressed:
            _hasPendingAction
                ? null
                : _toggleSearch,
            icon: Icon(
              _isSearchVisible
                  ? Icons
                  .close_rounded
                  : Icons
                  .search_rounded,
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
      color:
      _surfaceColor,
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
        style: TextStyle(
          color:
          _textColor,
          fontSize: 13,
        ),
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
          TextStyle(
            fontSize: 12,
            color:
            _mutedColor,
          ),
          prefixIcon:
          Icon(
            Icons.search_rounded,
            size: 19,
            color:
            _mutedColor,
          ),
          suffixIcon:
          _searchController
              .text
              .isEmpty
              ? null
              : IconButton(
            tooltip:
            'Clear search',
            onPressed:
                () {
              _searchController
                  .clear();

              setState(
                    () {},
              );
            },
            icon:
            Icon(
              Icons
                  .clear_rounded,
              size: 18,
              color:
              _mutedColor,
            ),
          ),
          filled: true,
          fillColor:
          _surfaceVariantColor,
          contentPadding:
          const EdgeInsets.symmetric(
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
            BorderSide(
              color:
              _borderColor,
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
      ManagedConversation managed,
      ) {
    final Conversation conversation =
        managed.conversation;

    final latestMessage =
    conversation.messages.isEmpty
        ? null
        : conversation
        .messages
        .last;

    final bool isOpening =
        _openingConversationId ==
            conversation.id;

    final bool isArchiving =
        _archivingConversationId ==
            conversation.id;

    final bool isBusy =
        isOpening ||
            isArchiving;

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
          managed,
        );
      },
      child: Container(
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
          boxShadow: [
            BoxShadow(
              color:
              Colors.black
                  .withValues(
                alpha:
                _isDarkMode
                    ? 0.10
                    : 0.025,
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
          CrossAxisAlignment
              .start,
          children: [
            _buildConversationAvatar(
              managed,
              size: 52,
            ),

            const SizedBox(
              width: 12,
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
                          conversation
                              .userName,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          TextStyle(
                            fontSize:
                            13,
                            fontWeight:
                            FontWeight
                                .w800,
                            color:
                            _textColor,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      if (isBusy)
                        const SizedBox(
                          width: 15,
                          height: 15,
                          child:
                          CircularProgressIndicator(
                            strokeWidth:
                            2,
                            color:
                            primary,
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
                          TextStyle(
                            fontSize:
                            8.5,
                            color:
                            _mutedColor,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    conversation.city,
                    maxLines: 1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    TextStyle(
                      fontSize: 8.5,
                      color:
                      _mutedColor,
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
                        color:
                        primary,
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
                            FontWeight
                                .w600,
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
                          TextStyle(
                            fontSize:
                            10,
                            color:
                            _mutedColor,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal:
                          8,
                          vertical:
                          4,
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
                          conversation
                              .status,
                          style:
                          TextStyle(
                            fontSize:
                            7.5,
                            fontWeight:
                            FontWeight
                                .w700,
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
                        tooltip:
                        'Conversation options',
                        visualDensity:
                        VisualDensity
                            .compact,
                        constraints:
                        const BoxConstraints(
                          minWidth:
                          32,
                          minHeight:
                          32,
                        ),
                        padding:
                        EdgeInsets
                            .zero,
                        onPressed:
                        _hasPendingAction
                            ? null
                            : () {
                          _showConversationOptions(
                            managed,
                          );
                        },
                        icon:
                        Icon(
                          Icons
                              .more_vert_rounded,
                          size: 17,
                          color:
                          _mutedColor,
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
  // AVATAR
  // ============================================================

  Widget _buildConversationAvatar(
      ManagedConversation managed, {
        required double size,
      }) {
    final Conversation conversation =
        managed.conversation;

    final User? participant =
        managed.participant;

    final String? path =
    participant
        ?.profileImagePath
        ?.trim();

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
              BuildContext
              context,
              Object error,
              StackTrace?
              stackTrace,
              ) {
            return _buildInitialAvatar(
              participant
                  ?.initials ??
                  conversation
                      .initials,
              size:
              size,
            );
          },
        )
            : _buildInitialAvatar(
          participant
              ?.initials ??
              conversation
                  .initials,
          size:
          size,
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(
      String initials, {
        required double size,
      }) {
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
          size >= 50
              ? 13
              : 12,
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
  // OPEN
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

      try {
        final ChatListSnapshot snapshot =
        await _controller
            .refreshConversations();

        if (!mounted) {
          return;
        }

        setState(() {
          _conversations =
              snapshot
                  .conversations;
        });
      } on ChatControllerException {
        if (!mounted) {
          return;
        }

        try {
          final ChatListSnapshot snapshot =
          _controller
              .currentChatList();

          setState(() {
            _conversations =
                snapshot
                    .conversations;
          });
        } catch (_) {}
      }
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
      ManagedConversation managed,
      ) async {
    if (_hasPendingAction) {
      return;
    }

    final Conversation conversation =
        managed.conversation;

    final String? action =
    await showModalBottomSheet<
        String>(
      context:
      context,
      backgroundColor:
      _surfaceColor,
      showDragHandle:
      true,
      builder: (
          BuildContext
          sheetContext,
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
                    color:
                    primary,
                  ),
                  title:
                  Text(
                    'Open conversation',
                    style:
                    TextStyle(
                      color:
                      _textColor,
                    ),
                  ),
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      'open',
                    );
                  },
                ),

                ListTile(
                  leading:
                  Icon(
                    Icons
                        .archive_outlined,
                    color:
                    _mutedColor,
                  ),
                  title:
                  Text(
                    'Archive conversation',
                    style:
                    TextStyle(
                      color:
                      _textColor,
                    ),
                  ),
                  subtitle:
                  Text(
                    'Remove it from Messages without deleting the saved thread.',
                    style:
                    TextStyle(
                      color:
                      _mutedColor,
                      fontSize:
                      11,
                    ),
                  ),
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      'archive',
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

    if (action == 'archive') {
      await _confirmArchiveConversation(
        managed,
      );
    }
  }

  // ============================================================
  // ARCHIVE
  // ============================================================

  Future<void> _confirmArchiveConversation(
      ManagedConversation managed,
      ) async {
    if (_hasPendingAction) {
      return;
    }

    final Conversation conversation =
        managed.conversation;

    final bool? confirmed =
    await showDialog<bool>(
      context:
      context,
      barrierDismissible:
      false,
      builder: (
          BuildContext
          dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          _surfaceColor,
          title:
          Text(
            'Archive conversation?',
            style:
            TextStyle(
              color:
              _textColor,
              fontWeight:
              FontWeight
                  .w800,
            ),
          ),
          content:
          Text(
            'This will remove your conversation with ${conversation.userName} from Messages. The saved thread is not permanently deleted and can be restored later.',
            style:
            TextStyle(
              color:
              _mutedColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
              Text(
                'CANCEL',
                style:
                TextStyle(
                  color:
                  _mutedColor,
                ),
              ),
            ),

            TextButton.icon(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              icon:
              const Icon(
                Icons
                    .archive_outlined,
                size: 18,
              ),
              label:
              const Text(
                'ARCHIVE',
                style:
                TextStyle(
                  fontWeight:
                  FontWeight
                      .w700,
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

    await _archiveConversation(
      managed,
    );
  }

  Future<void> _archiveConversation(
      ManagedConversation managed,
      ) async {
    if (_hasPendingAction) {
      return;
    }

    final Conversation conversation =
        managed.conversation;

    setState(() {
      _archivingConversationId =
          conversation.id;
    });

    try {
      final ChatListSnapshot snapshot =
      await _controller
          .archiveConversation(
        conversation.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _conversations =
            snapshot.conversations;
      });

      _showSnackBar(
        'Conversation with ${conversation.userName} archived.',
      );
    } on ChatControllerException catch (error) {
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
        'Conversation could not be archived. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _archivingConversationId =
          null;
        });
      }
    }
  }

  // ============================================================
  // ERROR / EMPTY
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
            Icon(
              Icons
                  .error_outline_rounded,
              size: 48,
              color:
              _mutedColor,
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              'Couldn’t load messages',
              style:
              TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight
                    .w800,
                color:
                _textColor,
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
              TextStyle(
                fontSize:
                10.5,
                height: 1.5,
                color:
                _mutedColor,
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
    return RefreshIndicator(
      onRefresh:
      _refreshConversations,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.symmetric(
          horizontal: 36,
        ),
        children: [
          const SizedBox(
            height: 120,
          ),

          Image.asset(
            'assets/images/mascot/tubi_sleeping.png',
            width: 120,
            height: 120,
            fit:
            BoxFit.contain,
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            'No conversations yet',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight
                  .w800,
              color:
              _textColor,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Find someone with a skill you want to learn and start a conversation.',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              fontSize: 10.5,
              height: 1.5,
              color:
              _mutedColor,
            ),
          ),
        ],
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
            Icon(
              Icons
                  .search_off_rounded,
              size: 48,
              color:
              _mutedColor,
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              'No conversations found',
              style:
              TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight
                    .w800,
                color:
                _textColor,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Try searching by name, city, skill, or status.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                fontSize:
                10.5,
                height: 1.5,
                color:
                _mutedColor,
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
          SnackBarBehavior
              .floating,
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
        return _isDarkMode
            ? const Color(
          0xFF3D9158,
        ).withValues(
          alpha: 0.18,
        )
            : const Color(
          0xFFEAF8EE,
        );

      case 'Planning':
        return _isDarkMode
            ? const Color(
          0xFFB97820,
        ).withValues(
          alpha: 0.18,
        )
            : const Color(
          0xFFFFF5E8,
        );

      case 'New':
        return _isDarkMode
            ? primary.withValues(
          alpha: 0.18,
        )
            : const Color(
          0xFFF0EFFF,
        );

      default:
        return _surfaceVariantColor;
    }
  }

  Color _statusColor(
      String status,
      ) {
    switch (status) {
      case 'Scheduled':
        return _isDarkMode
            ? const Color(
          0xFF7EDB9C,
        )
            : const Color(
          0xFF3D9158,
        );

      case 'Planning':
        return _isDarkMode
            ? const Color(
          0xFFFFC36B,
        )
            : const Color(
          0xFFB97820,
        );

      case 'New':
        return _isDarkMode
            ? const Color(
          0xFFB9BAFF,
        )
            : primary;

      default:
        return _mutedColor;
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
    weekday - 1];
  }
}