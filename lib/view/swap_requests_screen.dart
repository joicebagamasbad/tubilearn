import 'dart:io';

import 'package:flutter/material.dart';

import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/swap_request.dart';
import '../model/user.dart';

import '../services/current_user_service.dart';
import '../services/review_service.dart';
import '../services/swap_service.dart';

import '../theme/app_theme.dart';

class SwapRequestsScreen extends StatefulWidget {
  const SwapRequestsScreen({
    super.key,
  });

  @override
  State<SwapRequestsScreen> createState() =>
      _SwapRequestsScreenState();
}

class _SwapRequestsScreenState
    extends State<SwapRequestsScreen> {
  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  final ExploreRepository _exploreRepository =
      ExploreRepository.instance;

  final SwapService _swapService =
      SwapService.instance;

  final ReviewService _reviewService =
      ReviewService.instance;

  String _selectedFilter = 'All';

  bool _isLoading = true;

  String? _loadError;

  final Set<String> _processingRequestIds =
  <String>{};

  final Map<String, bool> _reviewedRequests =
  <String, bool>{};

  final List<String> _filters = const [
    'All',
    'Pending',
    'Accepted',
    'Scheduled',
    'Completed',
    'Declined',
    'Cancelled',
  ];

  String get _currentUserId =>
      _currentUserService.userId;

  bool get _hasPendingAction =>
      _processingRequestIds.isNotEmpty;

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

  @override
  void initState() {
    super.initState();

    _loadRequests();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadRequests() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      await _exploreRepository.initialize();

      await _swapService.initialize();

      await _loadReviewStatuses();

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = null;
      });
    } on SwapServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.message;
      });
    } on ReviewServiceException catch (error) {
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
        'Swap requests could not be loaded. Please try again.';
      });
    }
  }

  Future<void> _loadReviewStatuses() async {
    final List<SwapRequest> completedRequests =
    _swapService.requests
        .where(
          (
          SwapRequest request,
          ) =>
      request.status ==
          SwapRequestStatus.completed &&
          request.hasStableIdentity &&
          request.involvesUser(
            _currentUserId,
          ),
    )
        .toList();

    final Map<String, bool> loaded =
    <String, bool>{};

    for (final SwapRequest request
    in completedRequests) {
      loaded[request.id] =
      await _reviewService.hasReviewedSwap(
        request.id,
      );
    }

    _reviewedRequests
      ..clear()
      ..addAll(
        loaded,
      );
  }

  // ============================================================
  // FILTERED REQUESTS
  // ============================================================

  List<SwapRequest> get _filteredRequests {
    final List<SwapRequest> requests =
    _swapService.requests
        .where(
          (
          SwapRequest request,
          ) =>
          request.involvesUser(
            _currentUserId,
          ),
    )
        .toList();

    requests.sort(
          (
          SwapRequest first,
          SwapRequest second,
          ) =>
          second.updatedAt.compareTo(
            first.updatedAt,
          ),
    );

    if (_selectedFilter == 'All') {
      return requests;
    }

    return requests.where(
          (
          SwapRequest request,
          ) {
        switch (_selectedFilter) {
          case 'Pending':
            return request.status ==
                SwapRequestStatus.pending;

          case 'Accepted':
            return request.status ==
                SwapRequestStatus.accepted;

          case 'Scheduled':
            return request.status ==
                SwapRequestStatus.scheduled;

          case 'Completed':
            return request.status ==
                SwapRequestStatus.completed;

          case 'Declined':
            return request.status ==
                SwapRequestStatus.declined;

          case 'Cancelled':
            return request.status ==
                SwapRequestStatus.cancelled;

          default:
            return true;
        }
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
    return PopScope(
      canPop:
      !_hasPendingAction,
      child: Scaffold(
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
          leading: IconButton(
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
            icon: Icon(
              Icons
                  .arrow_back_ios_new_rounded,
              size:
              20,
              color:
              _hasPendingAction
                  ? _mutedColor
                  : _textColor,
            ),
          ),
          title: Text(
            'My Swap Requests',
            style:
            TextStyle(
              fontSize:
              19,
              fontWeight:
              FontWeight.w800,
              color:
              _textColor,
            ),
          ),
          centerTitle:
          false,
        ),
        body: SafeArea(
          child:
          _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_loadError != null) {
      return _buildErrorState();
    }

    final List<SwapRequest> requests =
        _filteredRequests;

    return Column(
      children: [
        Padding(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            12,
          ),
          child: Container(
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
                20,
              ),
              border:
              Border.all(
                color:
                _borderColor,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage your swaps',
                        style:
                        TextStyle(
                          fontSize:
                          17,
                          fontWeight:
                          FontWeight.w800,
                          color:
                          _textColor,
                        ),
                      ),
                      const SizedBox(
                        height:
                        5,
                      ),
                      Text(
                        'Track incoming and outgoing skill requests.',
                        style:
                        TextStyle(
                          fontSize:
                          12.5,
                          height:
                          1.4,
                          color:
                          _mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width:
                  12,
                ),
                Image.asset(
                  'assets/images/mascot/tubi_checking.png',
                  width:
                  68,
                  height:
                  68,
                  fit:
                  BoxFit.contain,
                ),
              ],
            ),
          ),
        ),

        SizedBox(
          height:
          42,
          child: ListView.separated(
            padding:
            const EdgeInsets.symmetric(
              horizontal:
              20,
            ),
            scrollDirection:
            Axis.horizontal,
            itemCount:
            _filters.length,
            separatorBuilder: (
                _,
                _,
                ) =>
            const SizedBox(
              width:
              8,
            ),
            itemBuilder: (
                BuildContext context,
                int index,
                ) {
              final String filter =
              _filters[index];

              final bool selected =
                  filter ==
                      _selectedFilter;

              return ChoiceChip(
                label:
                Text(
                  filter,
                ),
                selected:
                selected,
                onSelected:
                _hasPendingAction
                    ? null
                    : (_) {
                  setState(() {
                    _selectedFilter =
                        filter;
                  });
                },
                labelStyle:
                TextStyle(
                  fontSize:
                  12,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  selected
                      ? (_isDarkMode
                      ? const Color(
                    0xFF092E31,
                  )
                      : Colors.white)
                      : _textColor,
                ),
                selectedColor:
                _primaryColor,
                backgroundColor:
                _surfaceColor,
                disabledColor:
                _surfaceVariantColor,
                side:
                BorderSide(
                  color:
                  selected
                      ? _primaryColor
                      : _borderColor,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                showCheckmark:
                false,
              );
            },
          ),
        ),

        const SizedBox(
          height:
          12,
        ),

        Expanded(
          child:
          requests.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
            padding:
            const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              28,
            ),
            itemCount:
            requests.length,
            separatorBuilder: (
                _,
                _,
                ) =>
            const SizedBox(
              height:
              12,
            ),
            itemBuilder: (
                BuildContext context,
                int index,
                ) {
              return _buildRequestCard(
                requests[index],
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATES
  // ============================================================

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          SizedBox(
            width:
            28,
            height:
            28,
            child:
            CircularProgressIndicator(
              strokeWidth:
              2.5,
              color:
              _primaryColor,
            ),
          ),
          const SizedBox(
            height:
            14,
          ),
          Text(
            'Loading swap requests...',
            style:
            TextStyle(
              fontSize:
              12.5,
              color:
              _mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons
                  .error_outline_rounded,
              size:
              42,
              color:
              _mutedColor,
            ),
            const SizedBox(
              height:
              14,
            ),
            Text(
              'Could not load requests',
              style:
              TextStyle(
                fontSize:
                17,
                fontWeight:
                FontWeight.w800,
                color:
                _textColor,
              ),
            ),
            const SizedBox(
              height:
              7,
            ),
            Text(
              _loadError ??
                  'Something went wrong.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                fontSize:
                12.5,
                height:
                1.4,
                color:
                _mutedColor,
              ),
            ),
            const SizedBox(
              height:
              18,
            ),
            ElevatedButton(
              onPressed:
              _loadRequests,
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

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget _buildRequestCard(
      SwapRequest request,
      ) {
    final SwapRequestDirection direction =
    request.directionFor(
      _currentUserId,
    );

    final bool isIncoming =
        direction ==
            SwapRequestDirection.incoming;

    final bool isOutgoing =
        direction ==
            SwapRequestDirection.outgoing;

    final bool isProcessing =
    _processingRequestIds.contains(
      request.id,
    );

    final User? otherUser =
    _findOtherParticipant(
      request,
      direction,
    );

    final String displayInitials =
        otherUser?.initials ??
            (isIncoming
                ? '?'
                : request.providerInitials);

    final String displayName =
        otherUser?.name ??
            (isIncoming
                ? 'Incoming skill request'
                : request.providerName);

    final String displayCity =
        otherUser?.city ??
            (isIncoming
                ? 'Sender profile unavailable'
                : request.providerCity);

    return Container(
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
          20,
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
          Row(
            children: [
              _buildDirectionBadge(
                direction,
              ),
              const Spacer(),
              if (isProcessing)
                Padding(
                  padding:
                  const EdgeInsets.only(
                    right:
                    10,
                  ),
                  child: SizedBox(
                    width:
                    16,
                    height:
                    16,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                      color:
                      _primaryColor,
                    ),
                  ),
                ),
              _buildStatusBadge(
                request.status,
              ),
            ],
          ),

          const SizedBox(
            height:
            14,
          ),

          Row(
            children: [
              _buildUserAvatar(
                user:
                otherUser,
                initials:
                displayInitials,
                size:
                46,
              ),

              const SizedBox(
                width:
                12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines:
                      1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      TextStyle(
                        fontSize:
                        15,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        _textColor,
                      ),
                    ),
                    const SizedBox(
                      height:
                      3,
                    ),
                    Text(
                      displayCity,
                      maxLines:
                      1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      TextStyle(
                        fontSize:
                        12,
                        color:
                        _mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
            16,
          ),

          Container(
            width:
            double.infinity,
            padding:
            const EdgeInsets.all(
              13,
            ),
            decoration:
            BoxDecoration(
              color:
              _surfaceVariantColor,
              borderRadius:
              BorderRadius.circular(
                14,
              ),
              border:
              Border.all(
                color:
                _borderColor,
              ),
            ),
            child: Column(
              children: [
                _buildSkillRow(
                  icon:
                  Icons.school_outlined,
                  label:
                  'Learn',
                  value:
                  request.skillToLearn,
                ),
                const SizedBox(
                  height:
                  9,
                ),
                _buildSkillRow(
                  icon:
                  Icons.handshake_outlined,
                  label:
                  'Offer',
                  value:
                  request.skillToOffer,
                ),
              ],
            ),
          ),

          const SizedBox(
            height:
            14,
          ),

          _buildDetailRow(
            Icons.calendar_today_outlined,
            _formatDateTime(
              request.proposedAt,
            ),
          ),

          const SizedBox(
            height:
            8,
          ),

          _buildDetailRow(
            request.mode ==
                'Online'
                ? Icons.videocam_outlined
                : Icons.location_on_outlined,
            request.mode,
          ),

          if (request.meetingDetails != null &&
              request.meetingDetails!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(
              height:
              8,
            ),
            _buildDetailRow(
              Icons.info_outline,
              request.meetingDetails!,
            ),
          ],

          if (request.status ==
              SwapRequestStatus.accepted) ...[
            const SizedBox(
              height:
              10,
            ),
            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets.all(
                10,
              ),
              decoration:
              BoxDecoration(
                color:
                _softPrimaryColor,
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
              ),
              child: Text(
                'Schedule is awaiting confirmation.',
                style:
                TextStyle(
                  fontSize:
                  11.5,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  _primaryColor,
                ),
              ),
            ),
          ],

          if (request.status ==
              SwapRequestStatus.scheduled &&
              DateTime.now().isBefore(
                request.proposedAt,
              )) ...[
            const SizedBox(
              height:
              10,
            ),
            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets.all(
                10,
              ),
              decoration:
              BoxDecoration(
                color:
                _softPrimaryColor,
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons
                        .schedule_rounded,
                    size:
                    17,
                    color:
                    _primaryColor,
                  ),
                  const SizedBox(
                    width:
                    7,
                  ),
                  Expanded(
                    child: Text(
                      'This session is still upcoming.',
                      style:
                      TextStyle(
                        fontSize:
                        11.5,
                        fontWeight:
                        FontWeight.w600,
                        color:
                        _primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (request.status ==
              SwapRequestStatus.completed &&
              _reviewedRequests[
              request.id] ==
                  true) ...[
            const SizedBox(
              height:
              10,
            ),
            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets.all(
                10,
              ),
              decoration:
              BoxDecoration(
                color:
                _softPrimaryColor,
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size:
                    18,
                    color:
                    _primaryColor,
                  ),
                  const SizedBox(
                    width:
                    7,
                  ),
                  Expanded(
                    child: Text(
                      'You reviewed this swap partner.',
                      style:
                      TextStyle(
                        fontSize:
                        11.5,
                        fontWeight:
                        FontWeight.w600,
                        color:
                        _primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (request.note != null &&
              request.note!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(
              height:
              12,
            ),
            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets.all(
                12,
              ),
              decoration:
              BoxDecoration(
                color:
                _softPrimaryColor,
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
              child: Text(
                request.note!,
                style:
                TextStyle(
                  fontSize:
                  12.5,
                  height:
                  1.4,
                  color:
                  _textColor,
                ),
              ),
            ),
          ],

          if (_hasAvailableAction(
            request,
          )) ...[
            const SizedBox(
              height:
              16,
            ),
            _buildActions(
              request:
              request,
              isIncoming:
              isIncoming,
              isOutgoing:
              isOutgoing,
              isProcessing:
              isProcessing,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // OTHER PARTICIPANT
  // ============================================================

  User? _findOtherParticipant(
      SwapRequest request,
      SwapRequestDirection direction,
      ) {
    String? userId;

    if (direction ==
        SwapRequestDirection.incoming) {
      userId =
          request.requesterUserId;
    } else if (direction ==
        SwapRequestDirection.outgoing) {
      userId =
          request.providerUserId;
    }

    final String cleanUserId =
        userId?.trim() ??
            '';

    if (cleanUserId.isEmpty) {
      return null;
    }

    return _exploreRepository.findUserById(
      cleanUserId,
    );
  }

  Widget _buildUserAvatar({
    required User? user,
    required String initials,
    required double size,
  }) {
    final String? path =
    user
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
        width:
        size,
        height:
        size,
        child:
        hasImage
            ? Image.file(
          File(
            path,
          ),
          width:
          size,
          height:
          size,
          fit:
          BoxFit.cover,
          errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
              ) {
            return _buildInitialAvatar(
              initials,
              size:
              size,
            );
          },
        )
            : _buildInitialAvatar(
          initials,
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
      width:
      size,
      height:
      size,
      color:
      _softPrimaryColor,
      alignment:
      Alignment.center,
      child: Text(
        initials,
        style:
        TextStyle(
          fontSize:
          14,
          fontWeight:
          FontWeight.w800,
          color:
          _primaryColor,
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
  // ACTION AVAILABILITY
  // ============================================================

  bool _hasAvailableAction(
      SwapRequest request,
      ) {
    return request.canAccept(
      _currentUserId,
    ) ||
        request.canDecline(
          _currentUserId,
        ) ||
        request.canCancel(
          _currentUserId,
        ) ||
        request.canEditSchedule(
          _currentUserId,
        ) ||
        request.canReschedule(
          _currentUserId,
        ) ||
        request.canSchedule(
          _currentUserId,
        ) ||
        request.canComplete(
          _currentUserId,
        ) ||
        _canReview(
          request,
        ) ||
        _canRemoveFromHistory(
          request,
        );
  }

  bool _canReview(
      SwapRequest request,
      ) {
    return request.status ==
        SwapRequestStatus.completed &&
        request.hasStableIdentity &&
        request.involvesUser(
          _currentUserId,
        ) &&
        _reviewedRequests[
        request.id] !=
            true;
  }

  bool _canRemoveFromHistory(
      SwapRequest request,
      ) {
    return request.hasStableIdentity &&
        request.status.isTerminal &&
        request.involvesUser(
          _currentUserId,
        );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActions({
    required SwapRequest request,
    required bool isIncoming,
    required bool isOutgoing,
    required bool isProcessing,
  }) {
    final bool blocked =
        isProcessing;

    if (isIncoming &&
        request.canRespond(
          _currentUserId,
        )) {
      return Row(
        children: [
          Expanded(
            child:
            OutlinedButton(
              onPressed:
              blocked
                  ? null
                  : () {
                _confirmDecline(
                  request,
                );
              },
              child:
              const Text(
                'DECLINE',
              ),
            ),
          ),
          const SizedBox(
            width:
            10,
          ),
          Expanded(
            child:
            ElevatedButton(
              onPressed:
              blocked
                  ? null
                  : () {
                _confirmAccept(
                  request,
                );
              },
              child:
              const Text(
                'ACCEPT',
              ),
            ),
          ),
        ],
      );
    }

    if (request.status ==
        SwapRequestStatus.accepted) {
      return Column(
        children: [
          SizedBox(
            width:
            double.infinity,
            child:
            OutlinedButton.icon(
              onPressed:
              blocked
                  ? null
                  : () {
                _editSchedule(
                  request,
                );
              },
              icon:
              const Icon(
                Icons
                    .edit_calendar_outlined,
                size:
                18,
              ),
              label:
              const Text(
                'EDIT SCHEDULE',
              ),
            ),
          ),
          const SizedBox(
            height:
            9,
          ),
          SizedBox(
            width:
            double.infinity,
            child:
            ElevatedButton.icon(
              onPressed:
              blocked
                  ? null
                  : () {
                _confirmSchedule(
                  request,
                );
              },
              icon:
              const Icon(
                Icons
                    .event_available_outlined,
                size:
                18,
              ),
              label:
              const Text(
                'CONFIRM SCHEDULE',
              ),
            ),
          ),
          if (request.canCancel(
            _currentUserId,
          )) ...[
            const SizedBox(
              height:
              9,
            ),
            _buildCancelButton(
              request,
              blocked:
              blocked,
            ),
          ],
        ],
      );
    }

    if (request.status ==
        SwapRequestStatus.scheduled) {
      final bool sessionTimeReached =
      !DateTime.now().isBefore(
        request.proposedAt,
      );

      return Column(
        children: [
          SizedBox(
            width:
            double.infinity,
            child:
            OutlinedButton.icon(
              onPressed:
              blocked
                  ? null
                  : () {
                _editSchedule(
                  request,
                );
              },
              icon:
              const Icon(
                Icons.update_rounded,
                size:
                18,
              ),
              label:
              const Text(
                'RESCHEDULE',
              ),
            ),
          ),

          const SizedBox(
            height:
            9,
          ),

          SizedBox(
            width:
            double.infinity,
            child:
            ElevatedButton(
              onPressed:
              blocked ||
                  !sessionTimeReached
                  ? null
                  : () {
                _confirmComplete(
                  request,
                );
              },
              child:
              Text(
                sessionTimeReached
                    ? 'MARK AS COMPLETED'
                    : 'SESSION UPCOMING',
              ),
            ),
          ),

          if (request.canCancel(
            _currentUserId,
          )) ...[
            const SizedBox(
              height:
              9,
            ),
            _buildCancelButton(
              request,
              blocked:
              blocked,
            ),
          ],
        ],
      );
    }

    if (request.status ==
        SwapRequestStatus.completed) {
      return Column(
        children: [
          if (_canReview(
            request,
          ))
            SizedBox(
              width:
              double.infinity,
              child:
              ElevatedButton.icon(
                onPressed:
                blocked
                    ? null
                    : () {
                  _openReviewDialog(
                    request,
                  );
                },
                icon:
                const Icon(
                  Icons
                      .star_outline_rounded,
                  size:
                  19,
                ),
                label:
                const Text(
                  'RATE SWAP PARTNER',
                ),
              ),
            ),

          if (_canReview(
            request,
          ) &&
              _canRemoveFromHistory(
                request,
              ))
            const SizedBox(
              height:
              9,
            ),

          if (_canRemoveFromHistory(
            request,
          ))
            SizedBox(
              width:
              double.infinity,
              child:
              OutlinedButton.icon(
                onPressed:
                blocked
                    ? null
                    : () {
                  _confirmRemoveFromHistory(
                    request,
                  );
                },
                icon:
                const Icon(
                  Icons.archive_outlined,
                  size:
                  18,
                ),
                label:
                const Text(
                  'REMOVE FROM HISTORY',
                ),
              ),
            ),
        ],
      );
    }

    if (request.canCancel(
      _currentUserId,
    )) {
      return _buildCancelButton(
        request,
        blocked:
        blocked,
      );
    }

    if (_canRemoveFromHistory(
      request,
    )) {
      return SizedBox(
        width:
        double.infinity,
        child:
        OutlinedButton.icon(
          onPressed:
          blocked
              ? null
              : () {
            _confirmRemoveFromHistory(
              request,
            );
          },
          icon:
          const Icon(
            Icons.archive_outlined,
            size:
            18,
          ),
          label:
          const Text(
            'REMOVE FROM HISTORY',
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCancelButton(
      SwapRequest request, {
        required bool blocked,
      }) {
    return SizedBox(
      width:
      double.infinity,
      child:
      OutlinedButton(
        onPressed:
        blocked
            ? null
            : () {
          _confirmCancel(
            request,
          );
        },
        child:
        const Text(
          'CANCEL REQUEST',
        ),
      ),
    );
  }

  // ============================================================
  // REVIEW
  // ============================================================

  Future<void> _openReviewDialog(
      SwapRequest request,
      ) async {
    if (_processingRequestIds.contains(
      request.id,
    )) {
      return;
    }

    int selectedRating =
    0;

    final TextEditingController
    commentController =
    TextEditingController();

    final bool? shouldSubmit =
    await showDialog<bool>(
      context:
      context,
      barrierDismissible:
      false,
      builder: (
          BuildContext dialogContext,
          ) {
        return StatefulBuilder(
          builder: (
              BuildContext context,
              StateSetter setDialogState,
              ) {
            return AlertDialog(
              backgroundColor:
              _surfaceColor,
              title:
              Text(
                'Rate your swap partner',
                style:
                TextStyle(
                  fontWeight:
                  FontWeight.w800,
                  color:
                  _textColor,
                ),
              ),
              content:
              SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How was your completed skill swap?',
                      style:
                      TextStyle(
                        fontSize:
                        13,
                        height:
                        1.4,
                        color:
                        _mutedColor,
                      ),
                    ),
                    const SizedBox(
                      height:
                      18,
                    ),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children:
                      List<Widget>.generate(
                        5,
                            (
                            int index,
                            ) {
                          final int starValue =
                              index + 1;

                          return IconButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedRating =
                                    starValue;
                              });
                            },
                            icon:
                            Icon(
                              starValue <=
                                  selectedRating
                                  ? Icons.star_rounded
                                  : Icons
                                  .star_outline_rounded,
                              size:
                              34,
                              color:
                              starValue <=
                                  selectedRating
                                  ? const Color(
                                0xFFF2A65A,
                              )
                                  : _mutedColor,
                            ),
                          );
                        },
                      ),
                    ),
                    if (selectedRating >
                        0) ...[
                      const SizedBox(
                        height:
                        4,
                      ),
                      Center(
                        child: Text(
                          '$selectedRating out of 5',
                          style:
                          TextStyle(
                            fontSize:
                            12,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            _primaryColor,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(
                      height:
                      18,
                    ),
                    Text(
                      'Comment (optional)',
                      style:
                      TextStyle(
                        fontSize:
                        12,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        _textColor,
                      ),
                    ),
                    const SizedBox(
                      height:
                      7,
                    ),
                    TextField(
                      controller:
                      commentController,
                      maxLength:
                      500,
                      maxLines:
                      4,
                      decoration:
                      const InputDecoration(
                        hintText:
                        'Share what went well about the swap...',
                      ),
                    ),
                  ],
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
                  child:
                  const Text(
                    'CANCEL',
                  ),
                ),
                ElevatedButton(
                  onPressed:
                  selectedRating <=
                      0
                      ? null
                      : () {
                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  child:
                  const Text(
                    'SUBMIT REVIEW',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSubmit !=
        true) {
      commentController.dispose();
      return;
    }

    final String comment =
    commentController.text.trim();

    commentController.dispose();

    final String requestId =
        request.id;

    if (_processingRequestIds.contains(
      requestId,
    )) {
      return;
    }

    setState(() {
      _processingRequestIds.add(
        requestId,
      );
    });

    try {
      await _reviewService.submitReview(
        swapRequestId:
        requestId,
        rating:
        selectedRating,
        comment:
        comment,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reviewedRequests[
        requestId] = true;
      });

      _showMessage(
        'Review submitted. Thank you!',
      );
    } on ReviewServiceException catch (error) {
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
        'Review could not be submitted.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRequestIds.remove(
            requestId,
          );
        });
      }
    }
  }

  // ============================================================
  // EDIT SCHEDULE
  // ============================================================

  Future<void> _editSchedule(
      SwapRequest request,
      ) async {
    if (_processingRequestIds.contains(
      request.id,
    )) {
      return;
    }

    DateTime selectedDate =
    DateTime(
      request.proposedAt.year,
      request.proposedAt.month,
      request.proposedAt.day,
    );

    TimeOfDay selectedTime =
    TimeOfDay(
      hour:
      request.proposedAt.hour,
      minute:
      request.proposedAt.minute,
    );

    if (!request.hasStableIdentity) {
      _showMessage(
        'This swap does not have enough skill information to edit its session mode.',
      );
      return;
    }

    final Skill? skillToLearn =
    _exploreRepository.findSkillById(
      request.skillToLearnId!,
    );

    final Skill? skillToOffer =
    _exploreRepository.findSkillById(
      request.skillToOfferId!,
    );

    if (skillToLearn == null ||
        skillToOffer == null) {
      _showMessage(
        'One of the skills in this swap is no longer available.',
      );
      return;
    }

    final List<String> supportedModes =
    <String>[
      if (skillToLearn.supportsSessionMode(
        'Online',
      ) &&
          skillToOffer.supportsSessionMode(
            'Online',
          ))
        'Online',
      if (skillToLearn.supportsSessionMode(
        'In-person',
      ) &&
          skillToOffer.supportsSessionMode(
            'In-person',
          ))
        'In-person',
    ];

    if (supportedModes.isEmpty) {
      _showMessage(
        'These two skills do not share a compatible session mode.',
      );
      return;
    }

    final bool previousModeStillSupported =
    supportedModes.contains(
      request.mode,
    );

    String selectedMode =
    previousModeStillSupported
        ? request.mode
        : supportedModes.first;

    final TextEditingController
    detailsController =
    TextEditingController(
      text:
      previousModeStillSupported
          ? request.meetingDetails ??
          ''
          : '',
    );

    final bool? shouldSave =
    await showDialog<bool>(
      context:
      context,
      barrierDismissible:
      false,
      builder: (
          BuildContext dialogContext,
          ) {
        return StatefulBuilder(
          builder: (
              BuildContext context,
              StateSetter setDialogState,
              ) {
            return AlertDialog(
              backgroundColor:
              _surfaceColor,
              title:
              Text(
                request.status ==
                    SwapRequestStatus
                        .scheduled
                    ? 'Reschedule session'
                    : 'Edit schedule',
                style:
                TextStyle(
                  fontWeight:
                  FontWeight.w800,
                  color:
                  _textColor,
                ),
              ),
              content:
              SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    if (request.status ==
                        SwapRequestStatus
                            .scheduled) ...[
                      Container(
                        width:
                        double.infinity,
                        padding:
                        const EdgeInsets.all(
                          11,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          _softPrimaryColor,
                          borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                        ),
                        child:
                        Text(
                          'Changing a scheduled session will require schedule confirmation again.',
                          style:
                          TextStyle(
                            fontSize:
                            12,
                            height:
                            1.4,
                            color:
                            _textColor,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height:
                        16,
                      ),
                    ],

                    Text(
                      'Date',
                      style:
                      TextStyle(
                        fontSize:
                        12,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        _textColor,
                      ),
                    ),

                    const SizedBox(
                      height:
                      7,
                    ),

                    SizedBox(
                      width:
                      double.infinity,
                      child:
                      OutlinedButton.icon(
                        onPressed:
                            () async {
                          final DateTime now =
                          DateTime.now();

                          final DateTime today =
                          DateTime(
                            now.year,
                            now.month,
                            now.day,
                          );

                          DateTime initialDate =
                              selectedDate;

                          if (initialDate.isBefore(
                            today,
                          )) {
                            initialDate =
                                today;
                          }

                          final DateTime? result =
                          await showDatePicker(
                            context:
                            dialogContext,
                            initialDate:
                            initialDate,
                            firstDate:
                            today,
                            lastDate:
                            today.add(
                              const Duration(
                                days:
                                180,
                              ),
                            ),
                          );

                          if (result ==
                              null) {
                            return;
                          }

                          setDialogState(() {
                            selectedDate =
                                result;
                          });
                        },
                        icon:
                        const Icon(
                          Icons
                              .calendar_today_outlined,
                          size:
                          17,
                        ),
                        label:
                        Text(
                          _formatDateOnly(
                            selectedDate,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height:
                      14,
                    ),

                    Text(
                      'Time',
                      style:
                      TextStyle(
                        fontSize:
                        12,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        _textColor,
                      ),
                    ),

                    const SizedBox(
                      height:
                      7,
                    ),

                    SizedBox(
                      width:
                      double.infinity,
                      child:
                      OutlinedButton.icon(
                        onPressed:
                            () async {
                          final TimeOfDay? result =
                          await showTimePicker(
                            context:
                            dialogContext,
                            initialTime:
                            selectedTime,
                          );

                          if (result ==
                              null) {
                            return;
                          }

                          setDialogState(() {
                            selectedTime =
                                result;
                          });
                        },
                        icon:
                        const Icon(
                          Icons
                              .schedule_rounded,
                          size:
                          18,
                        ),
                        label:
                        Text(
                          selectedTime.format(
                            context,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height:
                      14,
                    ),

                    Text(
                      'Session mode',
                      style:
                      TextStyle(
                        fontSize:
                        12,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        _textColor,
                      ),
                    ),

                    const SizedBox(
                      height:
                      8,
                    ),

                    Text(
                      'Only modes supported by both skills can be selected.',
                      style:
                      TextStyle(
                        fontSize:
                        11,
                        height:
                        1.35,
                        color:
                        _mutedColor,
                      ),
                    ),

                    const SizedBox(
                      height:
                      9,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child:
                          Opacity(
                            opacity:
                            supportedModes.contains(
                              'Online',
                            )
                                ? 1
                                : 0.48,
                            child:
                            ChoiceChip(
                              label:
                              const Text(
                                'Online',
                              ),
                              selected:
                              selectedMode ==
                                  'Online',
                              showCheckmark:
                              false,
                              onSelected:
                              supportedModes.contains(
                                'Online',
                              )
                                  ? (_) {
                                if (selectedMode ==
                                    'Online') {
                                  return;
                                }

                                setDialogState(() {
                                  selectedMode =
                                  'Online';

                                  detailsController.clear();
                                });
                              }
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width:
                          8,
                        ),
                        Expanded(
                          child:
                          Opacity(
                            opacity:
                            supportedModes.contains(
                              'In-person',
                            )
                                ? 1
                                : 0.48,
                            child:
                            ChoiceChip(
                              label:
                              const Text(
                                'In-person',
                              ),
                              selected:
                              selectedMode ==
                                  'In-person',
                              showCheckmark:
                              false,
                              onSelected:
                              supportedModes.contains(
                                'In-person',
                              )
                                  ? (_) {
                                if (selectedMode ==
                                    'In-person') {
                                  return;
                                }

                                setDialogState(() {
                                  selectedMode =
                                  'In-person';

                                  detailsController.clear();
                                });
                              }
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height:
                      14,
                    ),

                    Text(
                      selectedMode ==
                          'Online'
                          ? 'Online platform'
                          : 'Meeting area',
                      style:
                      TextStyle(
                        fontSize:
                        12,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        _textColor,
                      ),
                    ),

                    const SizedBox(
                      height:
                      7,
                    ),

                    TextField(
                      controller:
                      detailsController,
                      maxLength:
                      150,
                      decoration:
                      InputDecoration(
                        hintText:
                        selectedMode ==
                            'Online'
                            ? 'Example: Google Meet or Messenger'
                            : 'Example: DCT campus or public café',
                      ),
                    ),
                  ],
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
                  child:
                  const Text(
                    'CANCEL',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final String details =
                    detailsController
                        .text
                        .trim();

                    if (details.isEmpty) {
                      _showMessage(
                        selectedMode ==
                            'Online'
                            ? 'Please enter an online platform.'
                            : 'Please enter a meeting area.',
                      );

                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  child:
                  const Text(
                    'SAVE',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave !=
        true) {
      detailsController.dispose();
      return;
    }

    final String meetingDetails =
    detailsController.text.trim();

    detailsController.dispose();

    final DateTime proposedAt =
    DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (!proposedAt.isAfter(
      DateTime.now(),
    )) {
      _showMessage(
        'Please choose a future date and time.',
      );

      return;
    }

    await _performAction(
      requestId:
      request.id,
      action: () =>
          _swapService.updateSchedule(
            requestId:
            request.id,
            actorUserId:
            _currentUserId,
            proposedAt:
            proposedAt,
            mode:
            selectedMode,
            meetingDetails:
            meetingDetails,
          ),
      successMessage:
      request.status ==
          SwapRequestStatus.scheduled
          ? 'Session rescheduled. Please confirm the new schedule.'
          : 'Schedule updated.',
    );
  }

  // ============================================================
  // BADGES
  // ============================================================

  Widget _buildDirectionBadge(
      SwapRequestDirection direction,
      ) {
    final bool incoming =
        direction ==
            SwapRequestDirection.incoming;

    final bool outgoing =
        direction ==
            SwapRequestDirection.outgoing;

    final String text =
    incoming
        ? 'Incoming'
        : outgoing
        ? 'Outgoing'
        : 'Unrelated';

    final IconData icon =
    incoming
        ? Icons.call_received_rounded
        : outgoing
        ? Icons.call_made_rounded
        : Icons.help_outline_rounded;

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        10,
        vertical:
        6,
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
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            size:
            13,
            color:
            _primaryColor,
          ),
          const SizedBox(
            width:
            5,
          ),
          Text(
            text,
            style:
            TextStyle(
              fontSize:
              10.5,
              fontWeight:
              FontWeight.w800,
              color:
              _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
      SwapRequestStatus status,
      ) {
    late final Color color;

    switch (status) {
      case SwapRequestStatus.pending:
        color =
        _isDarkMode
            ? const Color(
          0xFFFFB74D,
        )
            : Colors.orange;

      case SwapRequestStatus.accepted:
        color =
        _isDarkMode
            ? const Color(
          0xFF81C784,
        )
            : AppTheme.success;

      case SwapRequestStatus.declined:
        color =
            AppTheme.error;

      case SwapRequestStatus.scheduled:
        color =
        _isDarkMode
            ? const Color(
          0xFF64B5F6,
        )
            : Colors.blue;

      case SwapRequestStatus.completed:
        color =
        _isDarkMode
            ? const Color(
          0xFF80CBC4,
        )
            : Colors.teal;

      case SwapRequestStatus.cancelled:
        color =
            _mutedColor;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        10,
        vertical:
        6,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withValues(
          alpha:
          _isDarkMode
              ? 0.16
              : 0.10,
        ),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        status.label,
        style:
        TextStyle(
          fontSize:
          10.5,
          fontWeight:
          FontWeight.w800,
          color:
          color,
        ),
      ),
    );
  }

  // ============================================================
  // DETAILS
  // ============================================================

  Widget _buildSkillRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size:
          17,
          color:
          _primaryColor,
        ),
        const SizedBox(
          width:
          9,
        ),
        SizedBox(
          width:
          46,
          child: Text(
            '$label:',
            style:
            TextStyle(
              fontSize:
              11.5,
              color:
              _mutedColor,
            ),
          ),
        ),
        Expanded(
          child:
          Text(
            value,
            style:
            TextStyle(
              fontSize:
              12.5,
              fontWeight:
              FontWeight.w700,
              color:
              _textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
      IconData icon,
      String text,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size:
          16,
          color:
          _mutedColor,
        ),
        const SizedBox(
          width:
          8,
        ),
        Expanded(
          child:
          Text(
            text,
            style:
            TextStyle(
              fontSize:
              12,
              height:
              1.35,
              color:
              _mutedColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final bool filtered =
        _selectedFilter !=
            'All';

    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/mascot/tubi_confused.png',
              width:
              100,
              height:
              100,
            ),
            const SizedBox(
              height:
              14,
            ),
            Text(
              filtered
                  ? 'No $_selectedFilter requests'
                  : 'No swap requests yet',
              style:
              TextStyle(
                fontSize:
                17,
                fontWeight:
                FontWeight.w800,
                color:
                _textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REQUEST ACTIONS
  // ============================================================

  Future<void> _confirmAccept(
      SwapRequest request,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context:
      context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          title:
          const Text(
            'Accept request?',
          ),
          content:
          const Text(
            'Accepting means you agree to continue with this skill swap.',
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
                'Back',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
              const Text(
                'Accept',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed !=
        true) {
      return;
    }

    await _performAction(
      requestId:
      request.id,
      action: () =>
          _swapService.acceptRequest(
            requestId:
            request.id,
            actorUserId:
            _currentUserId,
          ),
      successMessage:
      'Swap request accepted.',
    );
  }

  Future<void> _confirmDecline(
      SwapRequest request,
      ) async {
    if (_processingRequestIds.contains(
      request.id,
    )) {
      return;
    }

    final bool? confirmed =
    await showDialog<bool>(
      context:
      context,
      barrierDismissible:
      false,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          _surfaceColor,
          title:
          Text(
            'Decline request?',
            style:
            TextStyle(
              fontWeight:
              FontWeight.w800,
              color:
              _textColor,
            ),
          ),
          content:
          Text(
            'This will decline the pending swap request. '
                'The request will move to Declined and can no longer be accepted.',
            style:
            TextStyle(
              color:
              _mutedColor,
              height:
              1.4,
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
              child:
              const Text(
                'KEEP REQUEST',
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
              ),
              child:
              const Text(
                'DECLINE',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed !=
        true) {
      return;
    }

    if (!mounted) {
      return;
    }

    await _performAction(
      requestId:
      request.id,
      action: () =>
          _swapService.declineRequest(
            requestId:
            request.id,
            actorUserId:
            _currentUserId,
          ),
      successMessage:
      'Swap request declined.',
    );
  }

  Future<void> _confirmCancel(
      SwapRequest request,
      ) async {
    if (_processingRequestIds.contains(
      request.id,
    )) {
      return;
    }

    final bool scheduled =
        request.status ==
            SwapRequestStatus.scheduled;

    final bool accepted =
        request.status ==
            SwapRequestStatus.accepted;

    final String message;

    if (scheduled) {
      message =
      'This session is already scheduled for '
          '${_formatDateTime(request.proposedAt)}. '
          'Cancelling will end this swap and remove it from your active sessions.';
    } else if (accepted) {
      message =
      'This swap has already been accepted. '
          'Cancelling will end the request before the schedule is completed.';
    } else {
      message =
      'This will cancel your pending swap request. '
          'The other participant will no longer be able to accept it.';
    }

    final bool? confirmed =
    await showDialog<bool>(
      context:
      context,
      barrierDismissible:
      false,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          _surfaceColor,
          title:
          Text(
            scheduled
                ? 'Cancel scheduled session?'
                : 'Cancel request?',
            style:
            TextStyle(
              fontWeight:
              FontWeight.w800,
              color:
              _textColor,
            ),
          ),
          content:
          Text(
            message,
            style:
            TextStyle(
              color:
              _mutedColor,
              height:
              1.4,
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
              child:
              const Text(
                'KEEP IT',
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
              ),
              child:
              Text(
                scheduled
                    ? 'CANCEL SESSION'
                    : 'CANCEL REQUEST',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed !=
        true) {
      return;
    }

    if (!mounted) {
      return;
    }

    await _performAction(
      requestId:
      request.id,
      action: () =>
          _swapService.cancelRequest(
            requestId:
            request.id,
            actorUserId:
            _currentUserId,
          ),
      successMessage:
      scheduled
          ? 'Scheduled session cancelled.'
          : 'Swap request cancelled.',
    );
  }

  Future<void> _confirmSchedule(
      SwapRequest request,
      ) async {
    if (!request.proposedAt.isAfter(
      DateTime.now(),
    )) {
      _showMessage(
        'The proposed schedule has already passed. Edit the schedule first.',
      );
      return;
    }

    final bool? confirmed =
    await showDialog<bool>(
      context:
      context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          title:
          const Text(
            'Confirm session schedule',
          ),
          content:
          Text(
            '${_formatDateTime(request.proposedAt)}\n\n'
                '${request.mode}\n'
                '${request.meetingDetails ?? ''}',
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
                'Back',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
              const Text(
                'Confirm schedule',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed !=
        true) {
      return;
    }

    await _performAction(
      requestId:
      request.id,
      action: () =>
          _swapService.scheduleRequest(
            requestId:
            request.id,
            actorUserId:
            _currentUserId,
          ),
      successMessage:
      'Session scheduled successfully.',
    );
  }

  Future<void> _confirmComplete(
      SwapRequest request,
      ) async {
    if (DateTime.now().isBefore(
      request.proposedAt,
    )) {
      _showMessage(
        'This session is still upcoming.',
      );
      return;
    }

    await _performAction(
      requestId:
      request.id,
      action: () =>
          _swapService.completeRequest(
            requestId:
            request.id,
            actorUserId:
            _currentUserId,
          ),
      successMessage:
      'Swap marked as completed.',
    );

    if (!mounted) {
      return;
    }

    _reviewedRequests[
    request.id] = false;
  }

  Future<void> _confirmRemoveFromHistory(
      SwapRequest request,
      ) async {
    if (_processingRequestIds.contains(
      request.id,
    )) {
      return;
    }

    final bool? confirmed =
    await showDialog<bool>(
      context:
      context,
      barrierDismissible:
      false,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          _surfaceColor,
          title:
          Text(
            'Remove from history?',
            style:
            TextStyle(
              fontWeight:
              FontWeight.w800,
              color:
              _textColor,
            ),
          ),
          content:
          Text(
            'This only removes the terminal swap from your local history view. '
                'It does not cancel, complete, or change the result of the swap.',
            style:
            TextStyle(
              color:
              _mutedColor,
              height:
              1.4,
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
              child:
              const Text(
                'KEEP IN HISTORY',
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
              ),
              child:
              const Text(
                'REMOVE',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed !=
        true) {
      return;
    }

    if (!mounted) {
      return;
    }

    await _performAction(
      requestId:
      request.id,
      action: () =>
          _swapService.deleteRequest(
            requestId:
            request.id,
            actorUserId:
            _currentUserId,
          ),
      successMessage:
      'Swap removed from your history.',
    );
  }

  Future<void> _performAction({
    required String requestId,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    final String cleanRequestId =
    requestId.trim();

    if (cleanRequestId.isEmpty ||
        _processingRequestIds.contains(
          cleanRequestId,
        )) {
      return;
    }

    setState(() {
      _processingRequestIds.add(
        cleanRequestId,
      );
    });

    try {
      await action();

      if (!mounted) {
        return;
      }

      setState(() {});

      _showMessage(
        successMessage,
      );
    } on SwapServiceException catch (error) {
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
        'Something went wrong.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRequestIds.remove(
            cleanRequestId,
          );
        });
      }
    }
  }

  void _showMessage(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger =
    ScaffoldMessenger.of(
      context,
    );

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content:
        Text(
          message,
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT
  // ============================================================

  String _formatDateOnly(
      DateTime value,
      ) {
    const List<String> months =
    [
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

    return '${months[value.month - 1]} '
        '${value.day}, ${value.year}';
  }

  String _formatDateTime(
      DateTime value,
      ) {
    const List<String> months =
    [
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

    final int hour =
        value.hour;

    final int displayHour =
    hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    final String minute =
    value.minute
        .toString()
        .padLeft(
      2,
      '0',
    );

    final String period =
    hour >= 12
        ? 'PM'
        : 'AM';

    return '${months[value.month - 1]} '
        '${value.day}, ${value.year} • '
        '$displayHour:$minute $period';
  }
}