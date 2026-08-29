import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/current_user_service.dart';

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
  _messageController =
  TextEditingController();

  final ScrollController
  _scrollController =
  ScrollController();

  final CurrentUserService
  _currentUserService =
      CurrentUserService.instance;

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback(
          (_) {
        _scrollToBottom();
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final conversation =
    ChatService.instance.conversations
        .firstWhere(
          (conversation) =>
      conversation.id ==
          widget.conversationId,
    );

    return Scaffold(
      backgroundColor:
      background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(
              conversation.userName,
              conversation.initials,
            ),

            _buildContextBar(
              conversation.skillWanted,
              conversation.skillOffered,
            ),

            Expanded(
              child:
              conversation.messages.isEmpty
                  ? _buildNoMessages()
                  : ListView.builder(
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
                conversation
                    .messages
                    .length,
                itemBuilder: (
                    context,
                    index,
                    ) {
                  final message =
                  conversation
                      .messages[index];

                  final bool isMe =
                  message.isSentBy(
                    _currentUserService
                        .userId,
                  );

                  final bool
                  showDateSeparator =
                      index == 0 ||
                          !_isSameDay(
                            conversation
                                .messages[
                            index -
                                1]
                                .sentAt,
                            message
                                .sentAt,
                          );

                  return Column(
                    children: [
                      if (showDateSeparator)
                        _buildDateSeparator(
                          message
                              .sentAt,
                        ),

                      Align(
                        alignment:
                        isMe
                            ? Alignment
                            .centerRight
                            : Alignment
                            .centerLeft,
                        child:
                        Container(
                          constraints:
                          const BoxConstraints(
                            maxWidth:
                            290,
                          ),
                          margin:
                          const EdgeInsets.only(
                            bottom:
                            11,
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
                                : Colors
                                .white,
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
                              border,
                            ),
                          ),
                          child:
                          Column(
                            crossAxisAlignment:
                            isMe
                                ? CrossAxisAlignment
                                .end
                                : CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                message
                                    .text,
                                style:
                                TextStyle(
                                  fontSize:
                                  14,
                                  height:
                                  1.4,
                                  color:
                                  isMe
                                      ? Colors
                                      .white
                                      : darkText,
                                ),
                              ),

                              const SizedBox(
                                height:
                                6,
                              ),

                              Row(
                                mainAxisSize:
                                MainAxisSize
                                    .min,
                                children: [
                                  Text(
                                    _formatMessageTime(
                                      message
                                          .sentAt,
                                    ),
                                    style:
                                    TextStyle(
                                      fontSize:
                                      10.5,
                                      fontWeight:
                                      FontWeight
                                          .w500,
                                      color:
                                      isMe
                                          ? Colors
                                          .white70
                                          : mutedText,
                                    ),
                                  ),

                                  if (isMe) ...[
                                    const SizedBox(
                                      width:
                                      4,
                                    ),
                                    const Icon(
                                      Icons
                                          .done_rounded,
                                      size:
                                      12,
                                      color:
                                      Colors
                                          .white70,
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
              ),
            ),

            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
      String name,
      String initials,
      ) {
    return Container(
      height:
      66,
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        8,
      ),
      decoration:
      const BoxDecoration(
        color:
        Colors.white,
        border:
        Border(
          bottom:
          BorderSide(
            color:
            border,
          ),
        ),
      ),
      child:
      Row(
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
              size:
              18,
              color:
              primary,
            ),
          ),

          Container(
            width:
            42,
            height:
            42,
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
            child:
            Text(
              initials,
              style:
              const TextStyle(
                fontSize:
                11,
                fontWeight:
                FontWeight.w800,
                color:
                Colors.white,
              ),
            ),
          ),

          const SizedBox(
            width:
            10,
          ),

          Expanded(
            child:
            Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style:
                  const TextStyle(
                    fontSize:
                    14.5,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    darkText,
                  ),
                ),

                const SizedBox(
                  height:
                  2,
                ),

                const Text(
                  'Skill swap conversation',
                  style:
                  TextStyle(
                    fontSize:
                    11,
                    color:
                    mutedText,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed:
                () {},
            icon:
            const Icon(
              Icons
                  .more_vert_rounded,
              size:
              20,
              color:
              mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextBar(
      String wanted,
      String offered,
      ) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        16,
        vertical:
        12,
      ),
      decoration:
      const BoxDecoration(
        color:
        Color(
          0xFFF3F1FF,
        ),
        border:
        Border(
          bottom:
          BorderSide(
            color:
            Color(
              0xFFE4E0FF,
            ),
          ),
        ),
      ),
      child:
      Row(
        children: [
          const Icon(
            Icons
                .swap_horiz_rounded,
            color:
            primary,
            size:
            19,
          ),

          const SizedBox(
            width:
            9,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Skill swap discussion',
                  style:
                  TextStyle(
                    fontSize:
                    11,
                    color:
                    mutedText,
                  ),
                ),

                const SizedBox(
                  height:
                  3,
                ),

                Text(
                  '$wanted ↔ $offered',
                  style:
                  const TextStyle(
                    fontSize:
                    12,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(
      DateTime date,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        top:
        4,
        bottom:
        14,
      ),
      child:
      Row(
        children: [
          const Expanded(
            child:
            Divider(
              color:
              border,
            ),
          ),

          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal:
              10,
            ),
            child:
            Text(
              _formatDateSeparator(
                date,
              ),
              style:
              const TextStyle(
                fontSize:
                10.5,
                fontWeight:
                FontWeight.w600,
                color:
                mutedText,
              ),
            ),
          ),

          const Expanded(
            child:
            Divider(
              color:
              border,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMessages() {
    return Center(
      child:
      Padding(
        padding:
        const EdgeInsets.symmetric(
          horizontal:
          40,
        ),
        child:
        Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/mascot/tubi_typing.png',
              width:
              100,
              height:
              100,
              fit:
              BoxFit.contain,
            ),

            const SizedBox(
              height:
              12,
            ),

            const Text(
              'Start the conversation',
              style:
              TextStyle(
                fontSize:
                16,
                fontWeight:
                FontWeight.w800,
                color:
                darkText,
              ),
            ),

            const SizedBox(
              height:
              7,
            ),

            const Text(
              'Introduce yourself, ask about the skill, and discuss what you can offer in exchange.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                fontSize:
                12,
                height:
                1.5,
                color:
                mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        12,
        9,
        12,
        10,
      ),
      decoration:
      const BoxDecoration(
        color:
        Colors.white,
        border:
        Border(
          top:
          BorderSide(
            color:
            border,
          ),
        ),
      ),
      child:
      Row(
        crossAxisAlignment:
        CrossAxisAlignment.end,
        children: [
          Expanded(
            child:
            TextField(
              controller:
              _messageController,
              enabled:
              !_isSending,
              minLines:
              1,
              maxLines:
              4,
              textCapitalization:
              TextCapitalization
                  .sentences,
              style:
              const TextStyle(
                fontSize:
                14,
                color:
                darkText,
              ),
              decoration:
              InputDecoration(
                hintText:
                _isSending
                    ? 'Sending...'
                    : 'Type a message...',
                hintStyle:
                const TextStyle(
                  fontSize:
                  13,
                  color:
                  mutedText,
                ),
                filled:
                true,
                fillColor:
                background,
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
              ),
              onSubmitted:
                  (_) {
                _sendMessage();
              },
            ),
          ),

          const SizedBox(
            width:
            8,
          ),

          Container(
            width:
            44,
            height:
            44,
            decoration:
            BoxDecoration(
              color:
              _isSending
                  ? primary.withValues(
                alpha:
                0.55,
              )
                  : primary,
              shape:
              BoxShape.circle,
            ),
            child:
            IconButton(
              onPressed:
              _isSending
                  ? null
                  : _sendMessage,
              icon:
              _isSending
                  ? const SizedBox(
                width:
                17,
                height:
                17,
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2,
                  color:
                  Colors.white,
                ),
              )
                  : const Icon(
                Icons
                    .send_rounded,
                color:
                Colors.white,
                size:
                19,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_isSending) {
      return;
    }

    final String text =
    _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(
          () {
        _isSending =
        true;
      },
    );

    try {
      await ChatService.instance.sendMessage(
        conversationId:
        widget.conversationId,
        text:
        text,
      );

      _messageController.clear();

      if (!mounted) {
        return;
      }

      setState(
            () {},
      );

      await Future.delayed(
        const Duration(
          milliseconds:
          100,
        ),
      );

      if (!mounted) {
        return;
      }

      _scrollToBottom();
    } on ChatServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(
            () {},
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
          Text(
            error.message,
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(
            () {},
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content:
          Text(
            'Message could not be sent. Please try again.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(
              () {
            _isSending =
            false;
          },
        );
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController
          .position
          .maxScrollExtent,
      duration:
      const Duration(
        milliseconds:
        220,
      ),
      curve:
      Curves.easeOut,
    );
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
    minute.toString().padLeft(
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

    if (date.year ==
        now.year) {
      return '${months[date.month - 1]} ${date.day}';
    }

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

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
}