import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/conversation.dart';
import '../model/message.dart';
import '../services/chat_service.dart';
import '../services/current_user_service.dart';
import '../theme/app_theme.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;

  const ConversationScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState
    extends State<ConversationScreen> {
  static const Color primary =
      AppTheme.primary;

  static const int _maxMessageLength =
  2000;

  final TextEditingController _messageController =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  bool _isLoading = true;
  bool _isSending = false;
  bool _isDeleting = false;

  String? _loadError;

  bool get _hasPendingAction =>
      _isSending || _isDeleting;

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

  Color get _contextBackground =>
      primary.withValues(
        alpha:
        _isDarkMode
            ? 0.14
            : 0.08,
      );

  Color get _contextBorder =>
      primary.withValues(
        alpha:
        _isDarkMode
            ? 0.28
            : 0.16,
      );

  @override
  void initState() {
    super.initState();

    _initializeConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializeConversation() async {
    try {
      await ChatService.instance.initialize();

      if (!mounted) {
        return;
      }

      final Conversation? conversation =
      _findConversation();

      if (conversation == null) {
        setState(() {
          _isLoading = false;
          _loadError =
          'This conversation is no longer available.';
        });

        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = null;
      });

      WidgetsBinding.instance
          .addPostFrameCallback(
            (_) {
          if (!mounted) {
            return;
          }

          _scrollToBottom(
            animate: false,
          );
        },
      );
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
        'Conversation could not be loaded. Please try again.';
      });
    }
  }

  Conversation? _findConversation() {
    return ChatService.instance.findConversation(
      widget.conversationId,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor:
        Theme.of(context)
            .scaffoldBackgroundColor,
        body: const SafeArea(
          child: Center(
            child:
            CircularProgressIndicator(
              color: primary,
            ),
          ),
        ),
      );
    }

    final Conversation? conversation =
    _findConversation();

    if (_loadError != null ||
        conversation == null) {
      return _buildUnavailableScreen();
    }

    return PopScope(
      canPop: !_hasPendingAction,
      child: Scaffold(
        backgroundColor:
        Theme.of(context)
            .scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(
                conversation,
              ),

              _buildContextBar(
                conversation.skillWanted,
                conversation.skillOffered,
              ),

              Expanded(
                child:
                conversation
                    .messages
                    .isEmpty
                    ? _buildNoMessages()
                    : _buildMessageList(
                  conversation,
                ),
              ),

              _buildComposer(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // UNAVAILABLE
  // ============================================================

  Widget _buildUnavailableScreen() {
    return Scaffold(
      backgroundColor:
      Theme.of(context)
          .scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 62,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                color: _surfaceColor,
                border: Border(
                  bottom: BorderSide(
                    color: _borderColor,
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
                        'Conversation',
                        style: TextStyle(
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

                  const SizedBox(
                    width: 48,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: Padding(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 36,
                  ),
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      Icon(
                        Icons
                            .chat_bubble_outline_rounded,
                        size: 52,
                        color:
                        _mutedColor,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      Text(
                        'Conversation unavailable',
                        style: TextStyle(
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
                            'This conversation may have been deleted.',
                        textAlign:
                        TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color:
                          _mutedColor,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                          );
                        },
                        child:
                        const Text(
                          'BACK TO MESSAGES',
                        ),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildTopBar(
      Conversation conversation,
      ) {
    return Container(
      height: 66,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: _borderColor,
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
            icon:
            const Icon(
              Icons
                  .arrow_back_ios_new_rounded,
              size: 18,
              color: primary,
            ),
          ),

          Container(
            width: 42,
            height: 42,
            decoration:
            const BoxDecoration(
              color:
              Color(
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
                fontSize: 11,
                fontWeight:
                FontWeight.w800,
                color:
                Colors.white,
              ),
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.userName,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    _textColor,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  'Skill swap conversation',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                    _mutedColor,
                  ),
                ),
              ],
            ),
          ),

          if (_isDeleting)
            const Padding(
              padding:
              EdgeInsets.only(
                right: 14,
              ),
              child: SizedBox(
                width: 18,
                height: 18,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primary,
                ),
              ),
            )
          else
            IconButton(
              onPressed:
              _hasPendingAction
                  ? null
                  : () {
                _showConversationMenu(
                  conversation,
                );
              },
              icon:
              Icon(
                Icons
                    .more_vert_rounded,
                size: 20,
                color:
                _mutedColor,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTEXT BAR
  // ============================================================

  Widget _buildContextBar(
      String wanted,
      String offered,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color:
        _contextBackground,
        border: Border(
          bottom: BorderSide(
            color:
            _contextBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons
                .swap_horiz_rounded,
            color: primary,
            size: 19,
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Skill swap discussion',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                    _mutedColor,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  '$wanted ↔ $offered',
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    _textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE LIST
  // ============================================================

  Widget _buildMessageList(
      Conversation conversation,
      ) {
    return ListView.builder(
      controller:
      _scrollController,
      physics:
      const BouncingScrollPhysics(),
      padding:
      const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        18,
      ),
      itemCount:
      conversation.messages.length,
      itemBuilder:
          (
          BuildContext context,
          int index,
          ) {
        final Message message =
        conversation.messages[index];

        final bool isMe =
        message.isSentBy(
          _currentUserService.userId,
        );

        final bool showDateSeparator =
            index == 0 ||
                !_isSameDay(
                  conversation
                      .messages[index - 1]
                      .sentAt,
                  message.sentAt,
                );

        return Column(
          children: [
            if (showDateSeparator)
              _buildDateSeparator(
                message.sentAt,
              ),

            Align(
              alignment:
              isMe
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                constraints:
                const BoxConstraints(
                  maxWidth: 290,
                ),
                margin:
                const EdgeInsets.only(
                  bottom: 11,
                ),
                padding:
                const EdgeInsets.fromLTRB(
                  14,
                  11,
                  14,
                  9,
                ),
                decoration:
                BoxDecoration(
                  color:
                  isMe
                      ? primary
                      : _surfaceColor,
                  borderRadius:
                  BorderRadius.only(
                    topLeft:
                    const Radius.circular(
                      16,
                    ),
                    topRight:
                    const Radius.circular(
                      16,
                    ),
                    bottomLeft:
                    Radius.circular(
                      isMe
                          ? 16
                          : 4,
                    ),
                    bottomRight:
                    Radius.circular(
                      isMe
                          ? 4
                          : 16,
                    ),
                  ),
                  border:
                  isMe
                      ? null
                      : Border.all(
                    color:
                    _borderColor,
                  ),
                  boxShadow:
                  isMe
                      ? null
                      : [
                    BoxShadow(
                      color:
                      Colors.black
                          .withValues(
                        alpha:
                        _isDarkMode
                            ? 0.08
                            : 0.02,
                      ),
                      blurRadius:
                      8,
                      offset:
                      const Offset(
                        0,
                        2,
                      ),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                  isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color:
                        isMe
                            ? Colors.white
                            : _textColor,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        Text(
                          _formatMessageTime(
                            message.sentAt,
                          ),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight:
                            FontWeight.w500,
                            color:
                            isMe
                                ? Colors.white70
                                : _mutedColor,
                          ),
                        ),

                        if (isMe) ...[
                          const SizedBox(
                            width: 4,
                          ),
                          const Icon(
                            Icons.done_rounded,
                            size: 12,
                            color:
                            Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DATE SEPARATOR
  // ============================================================

  Widget _buildDateSeparator(
      DateTime date,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        top: 4,
        bottom: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color:
              _borderColor,
            ),
          ),

          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            child: Text(
              _formatDateSeparator(
                date,
              ),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight:
                FontWeight.w600,
                color:
                _mutedColor,
              ),
            ),
          ),

          Expanded(
            child: Divider(
              color:
              _borderColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildNoMessages() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 40,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/mascot/tubi_typing.png',
              width: 100,
              height: 100,
              fit:
              BoxFit.contain,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              'Start the conversation',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.w800,
                color:
                _textColor,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              'Introduce yourself, ask about the skill, and discuss what you can offer in exchange.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 12,
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
  // COMPOSER
  // ============================================================

  Widget _buildComposer() {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        12,
        9,
        12,
        10,
      ),
      decoration: BoxDecoration(
        color:
        _surfaceColor,
        border: Border(
          top: BorderSide(
            color:
            _borderColor,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller:
              _messageController,
              enabled:
              !_hasPendingAction,
              minLines: 1,
              maxLines: 4,
              maxLength:
              _maxMessageLength,
              maxLengthEnforcement:
              MaxLengthEnforcement
                  .enforced,
              textCapitalization:
              TextCapitalization
                  .sentences,
              textInputAction:
              TextInputAction.newline,
              style: TextStyle(
                fontSize: 14,
                color:
                _textColor,
              ),
              decoration:
              InputDecoration(
                hintText:
                _isDeleting
                    ? 'Deleting conversation...'
                    : _isSending
                    ? 'Sending...'
                    : 'Type a message...',
                hintStyle:
                TextStyle(
                  fontSize: 13,
                  color:
                  _mutedColor,
                ),
                counterText:
                '',
                filled:
                true,
                fillColor:
                _surfaceVariantColor,
                contentPadding:
                const EdgeInsets.symmetric(
                  horizontal:
                  14,
                  vertical:
                  11,
                ),
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                  borderSide:
                  BorderSide.none,
                ),
                enabledBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    18,
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
                    18,
                  ),
                  borderSide:
                  const BorderSide(
                    color:
                    primary,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Container(
            width: 44,
            height: 44,
            decoration:
            BoxDecoration(
              color:
              _hasPendingAction
                  ? primary.withValues(
                alpha: 0.55,
              )
                  : primary,
              shape:
              BoxShape.circle,
            ),
            child: IconButton(
              onPressed:
              _hasPendingAction
                  ? null
                  : _sendMessage,
              icon:
              _isSending
                  ? const SizedBox(
                width: 17,
                height: 17,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                  Colors.white,
                ),
              )
                  : const Icon(
                Icons
                    .send_rounded,
                color:
                Colors.white,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEND
  // ============================================================

  Future<void> _sendMessage() async {
    if (_hasPendingAction) {
      return;
    }

    final String text =
    _messageController.text
        .trim();

    if (text.isEmpty) {
      return;
    }

    if (text.length >
        _maxMessageLength) {
      _showSnackBar(
        'Message must be $_maxMessageLength characters or fewer.',
      );

      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await ChatService.instance.sendMessage(
        conversationId:
        widget.conversationId,
        text:
        text,
      );

      if (!mounted) {
        return;
      }

      _messageController.clear();

      setState(() {});

      WidgetsBinding.instance
          .addPostFrameCallback(
            (_) {
          if (!mounted) {
            return;
          }

          _scrollToBottom(
            animate: true,
          );
        },
      );
    } on ChatServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {});

      _showSnackBar(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {});

      _showSnackBar(
        'Message could not be sent. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // ============================================================
  // MENU
  // ============================================================

  Future<void> _showConversationMenu(
      Conversation conversation,
      ) async {
    if (_hasPendingAction) {
      return;
    }

    final String? action =
    await showModalBottomSheet<String>(
      context:
      context,
      backgroundColor:
      _surfaceColor,
      showDragHandle:
      true,
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
                        .delete_outline_rounded,
                    color:
                    Colors.redAccent,
                  ),
                  title:
                  const Text(
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
          title: Text(
            'Delete conversation?',
            style: TextStyle(
              fontWeight:
              FontWeight.w800,
              color:
              _textColor,
            ),
          ),
          content: Text(
            'This will permanently delete your conversation with ${conversation.userName} and all saved messages in this thread.',
            style: TextStyle(
              color:
              _mutedColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color:
                  _mutedColor,
                ),
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

    if (!mounted ||
        confirmed != true) {
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

    FocusScope.of(
      context,
    ).unfocus();

    setState(() {
      _isDeleting = true;
    });

    try {
      await ChatService.instance
          .deleteConversation(
        conversation.id,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
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
          _isDeleting = false;
        });
      }
    }
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom({
    required bool animate,
  }) {
    if (!_scrollController.hasClients) {
      return;
    }

    final double target =
        _scrollController
            .position
            .maxScrollExtent;

    if (animate) {
      _scrollController.animateTo(
        target,
        duration:
        const Duration(
          milliseconds:
          220,
        ),
        curve:
        Curves.easeOut,
      );

      return;
    }

    _scrollController.jumpTo(
      target,
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
  // DATE / TIME
  // ============================================================

  bool _isSameDay(
      DateTime first,
      DateTime second,
      ) {
    return first.year ==
        second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
  }

  String _formatMessageTime(
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

  String _formatDateSeparator(
      DateTime date,
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
      date.year,
      date.month,
      date.day,
    );

    final int difference =
        today
            .difference(
          messageDate,
        )
            .inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    const List<String> months =
    <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    if (date.year ==
        now.year) {
      return '${months[date.month - 1]} ${date.day}';
    }

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}