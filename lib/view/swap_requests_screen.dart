import 'package:flutter/material.dart';

import '../model/repositories/explore_repository.dart';
import '../model/swap_request.dart';
import '../model/user.dart';

import '../services/current_user_service.dart';
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

  String _selectedFilter = 'All';

  bool _isLoading = true;

  String? _loadError;

  final Set<String> _processingRequestIds =
  <String>{};

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

  Future<void> _loadRequests() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      await _swapService.initialize();

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

  List<SwapRequest> get _filteredRequests {
    final List<SwapRequest> requests =
    _swapService.requests
        .where(
          (SwapRequest request) =>
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
          (SwapRequest request) {
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
            onPressed:
            _hasPendingAction
                ? null
                : () {
              Navigator.pop(
                context,
              );
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
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
            style: TextStyle(
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
                        style: TextStyle(
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
                        style: TextStyle(
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
            separatorBuilder:
                (
                _,
                _,
                ) =>
            const SizedBox(
              width:
              8,
            ),
            itemBuilder:
                (
                BuildContext context,
                int index,
                ) {
              final String filter =
              _filters[index];

              final bool selected =
                  filter ==
                      _selectedFilter;

              return ChoiceChip(
                label: Text(
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
            separatorBuilder:
                (
                _,
                _,
                ) =>
            const SizedBox(
              height:
              12,
            ),
            itemBuilder:
                (
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
            style: TextStyle(
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
              Icons.error_outline_rounded,
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
              style: TextStyle(
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
              style: TextStyle(
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

    User? requesterUser;

    final String? requesterUserId =
        request.requesterUserId;

    if (isIncoming &&
        requesterUserId != null &&
        requesterUserId
            .trim()
            .isNotEmpty) {
      requesterUser =
          _exploreRepository.findUserById(
            requesterUserId,
          );
    }

    final String displayInitials =
    isIncoming
        ? requesterUser?.initials ??
        '?'
        : request.providerInitials;

    final String displayName =
    isIncoming
        ? requesterUser?.name ??
        'Incoming skill request'
        : request.providerName;

    final String displayCity =
    isIncoming
        ? requesterUser?.city ??
        'Sender profile unavailable'
        : request.providerCity;

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
              CircleAvatar(
                radius:
                23,
                backgroundColor:
                _softPrimaryColor,
                child: Text(
                  displayInitials,
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

          if (request.meetingDetails !=
              null &&
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
        request.canSchedule(
          _currentUserId,
        ) ||
        request.canComplete(
          _currentUserId,
        ) ||
        _canRemoveFromHistory(
          request,
        );
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

    if (request.canSchedule(
      _currentUserId,
    )) {
      return Column(
        children: [
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
                Icons.event_available_outlined,
                size:
                18,
              ),
              label:
              const Text(
                'CONFIRM SCHEDULE',
              ),
            ),
          ),

          if (isOutgoing &&
              request.canCancel(
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

    if (request.canComplete(
      _currentUserId,
    )) {
      return SizedBox(
        width:
        double.infinity,
        child:
        ElevatedButton(
          onPressed:
          blocked
              ? null
              : () {
            _confirmComplete(
              request,
            );
          },
          child:
          const Text(
            'MARK AS COMPLETED',
          ),
        ),
      );
    }

    if (isOutgoing &&
        request.canCancel(
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
          child: Text(
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
          child: Text(
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

  Future<void> _confirmAccept(
      SwapRequest request,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context:
      context,
      builder:
          (
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

    if (confirmed != true) {
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
      'Swap request cancelled.',
    );
  }

  Future<void> _confirmSchedule(
      SwapRequest request,
      ) async {
    if (!request.proposedAt.isAfter(
      DateTime.now(),
    )) {
      _showMessage(
        'The proposed schedule has already passed.',
      );
      return;
    }

    final bool? confirmed =
    await showDialog<bool>(
      context:
      context,
      builder:
          (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          title:
          const Text(
            'Confirm session schedule',
          ),
          content: Text(
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

    if (confirmed != true) {
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
  }

  Future<void> _confirmRemoveFromHistory(
      SwapRequest request,
      ) async {
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

    if (_processingRequestIds.contains(
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

  String _formatDateTime(
      DateTime value,
      ) {
    const List<String> months = [
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