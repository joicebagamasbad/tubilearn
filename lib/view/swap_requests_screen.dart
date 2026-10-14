import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/swap_requests_controller.dart';
import '../model/swap_request.dart';
import '../model/user.dart';
import '../theme/app_theme.dart';
import 'widgets/swap_request_card.dart';

class SwapRequestsScreen extends StatefulWidget {
  const SwapRequestsScreen({
    super.key,
  });

  @override
  State<SwapRequestsScreen> createState() =>
      _SwapRequestsScreenState();
}

class _SwapRequestsScreenState
    extends State<SwapRequestsScreen>
    with WidgetsBindingObserver {
  final SwapRequestsController _controller =
  SwapRequestsController();

  String _selectedFilter = 'All';

  bool _isLoading = true;
  String? _loadError;

  Timer? _sessionBoundaryTimer;

  final Set<String> _processingRequestIds =
  <String>{};

  List<ManagedSwapRequest> _requests =
  <ManagedSwapRequest>[];

  DateTime? _nextSessionBoundary;

  static const List<String> _filters =
  <String>[
    'All',
    'Pending',
    'Accepted',
    'Scheduled',
    'Completed',
    'Declined',
    'Cancelled',
  ];

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

    WidgetsBinding.instance.addObserver(
      this,
    );

    _loadRequests();
  }

  @override
  void dispose() {
    _sessionBoundaryTimer?.cancel();

    WidgetsBinding.instance.removeObserver(
      this,
    );

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    _refreshSnapshot();
  }

  // ============================================================
  // LOAD / SNAPSHOT
  // ============================================================

  Future<void> _loadRequests() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final SwapRequestsSnapshot snapshot =
      await _controller.loadRequests();

      if (!mounted) {
        return;
      }

      _applySnapshot(
        snapshot,
        notify: false,
      );

      setState(() {
        _isLoading = false;
        _loadError = null;
      });

      _scheduleSessionBoundaryRefresh();
    } on SwapRequestsControllerException catch (error) {
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

  Future<void> _refreshSnapshot() async {
    if (_isLoading || _hasPendingAction) {
      return;
    }

    try {
      final SwapRequestsSnapshot snapshot =
      await _controller.refreshFromRemote();

      if (!mounted) {
        return;
      }

      _applySnapshot(
        snapshot,
      );

      _scheduleSessionBoundaryRefresh();
    } on SwapRequestsControllerException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    }
  }

  void _applySnapshot(
      SwapRequestsSnapshot snapshot, {
        bool notify = true,
      }) {
    void apply() {
      _requests = snapshot.requests;
      _nextSessionBoundary =
          snapshot.nextSessionBoundary;
    }

    if (notify && mounted) {
      setState(
        apply,
      );
    } else {
      apply();
    }
  }

  // ============================================================
  // SESSION TIME REFRESH
  // ============================================================

  void _scheduleSessionBoundaryRefresh() {
    _sessionBoundaryTimer?.cancel();
    _sessionBoundaryTimer = null;

    if (!mounted ||
        _isLoading ||
        _loadError != null) {
      return;
    }

    final DateTime? boundary =
        _nextSessionBoundary;

    if (boundary == null) {
      return;
    }

    final DateTime now =
    DateTime.now();

    if (!boundary.isAfter(
      now,
    )) {
      setState(() {});
      return;
    }

    final Duration delay =
        boundary.difference(
          now,
        ) +
            const Duration(
              milliseconds: 250,
            );

    _sessionBoundaryTimer = Timer(
      delay,
          () async {
        if (!mounted) {
          return;
        }

        setState(() {});

        await _refreshSnapshot();
      },
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<ManagedSwapRequest> get _filteredRequests =>
      _controller.filterRequests(
        requests: _requests,
        filter: _selectedFilter,
      );

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return PopScope(
      canPop: !_hasPendingAction,
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
          elevation: 0,
          leading: IconButton(
            tooltip: 'Back',
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
              size: 20,
              color:
              _hasPendingAction
                  ? _mutedColor
                  : _textColor,
            ),
          ),
          title: Text(
            'My Swap Requests',
            style: TextStyle(
              fontSize: 19,
              fontWeight:
              FontWeight.w800,
              color: _textColor,
            ),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: _buildBody(),
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

    final List<ManagedSwapRequest>
    requests =
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
          child: _buildIntroCard(),
        ),

        _buildFilters(),

        const SizedBox(
          height: 12,
        ),

        Expanded(
          child:
          requests.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
            onRefresh:
            _refreshSnapshot,
            child:
            ListView.separated(
              physics:
              const AlwaysScrollableScrollPhysics(),
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
                height: 12,
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
        ),
      ],
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: _borderColor,
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
                    fontSize: 17,
                    fontWeight:
                    FontWeight.w800,
                    color: _textColor,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  'Track incoming and outgoing skill requests.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: _mutedColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Image.asset(
            'assets/images/mascot/tubi_checking.png',
            width: 68,
            height: 68,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 20,
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
          width: 8,
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
            label: Text(
              filter,
            ),
            selected: selected,
            onSelected:
            _hasPendingAction
                ? null
                : (_) {
              setState(() {
                _selectedFilter =
                    filter;
              });
            },
            labelStyle: TextStyle(
              fontSize: 12,
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
            side: BorderSide(
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
            showCheckmark: false,
          );
        },
      ),
    );
  }

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget _buildRequestCard(
      ManagedSwapRequest managed,
      ) {
    final SwapRequest request =
        managed.request;

    final bool isProcessing =
    _processingRequestIds.contains(
      request.id,
    );

    return SwapRequestCard(
      managedRequest: managed,
      isProcessing: isProcessing,
      canAccept:
      _safeActionCheck(
            () =>
            _controller.canAccept(
              request,
            ),
      ),
      canDecline:
      _safeActionCheck(
            () =>
            _controller.canDecline(
              request,
            ),
      ),
      canCancel:
      _safeActionCheck(
            () =>
            _controller.canCancel(
              request,
            ),
      ),
      canEditSchedule:
      _safeActionCheck(
            () =>
            _controller
                .canEditSchedule(
              request,
            ),
      ),
      canSchedule:
      _safeActionCheck(
            () =>
            _controller.canSchedule(
              request,
            ),
      ),
      canComplete:
      _safeActionCheck(
            () =>
            _controller.canComplete(
              request,
            ),
      ),
      canReview:
      _safeActionCheck(
            () =>
            _controller.canReview(
              managed,
            ),
      ),
      canRemoveFromHistory:
      _safeActionCheck(
            () =>
            _controller
                .canRemoveFromHistory(
              request,
            ),
      ),
      onAccept: () {
        _confirmAccept(
          request,
        );
      },
      onDecline: () {
        _confirmDecline(
          request,
        );
      },
      onCancel: () {
        _confirmCancel(
          request,
        );
      },
      onEditSchedule: () {
        _editSchedule(
          request,
          managed.otherUser,
        );
      },
      onConfirmSchedule: () {
        _confirmSchedule(
          request,
        );
      },
      onComplete: () {
        _confirmComplete(
          request,
        );
      },
      onReview: () {
        _openReviewDialog(
          request,
        );
      },
      onRemoveFromHistory: () {
        _confirmRemoveFromHistory(
          request,
        );
      },
    );
  }

  bool _safeActionCheck(
      bool Function() check,
      ) {
    try {
      return check();
    } on SwapRequestsControllerException {
      return false;
    }
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
            width: 28,
            height: 28,
            child:
            CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _primaryColor,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            'Loading swap requests...',
            style: TextStyle(
              fontSize: 12.5,
              color: _mutedColor,
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
              size: 42,
              color: _mutedColor,
            ),
            const SizedBox(
              height: 14,
            ),
            Text(
              'Could not load requests',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.w800,
                color: _textColor,
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
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: _mutedColor,
              ),
            ),
            const SizedBox(
              height: 18,
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

  Widget _buildEmptyState() {
    final bool filtered =
        _selectedFilter != 'All';

    return RefreshIndicator(
      onRefresh:
      _refreshSnapshot,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(
          30,
        ),
        children: [
          const SizedBox(
            height: 70,
          ),
          Image.asset(
            'assets/images/mascot/tubi_confused.png',
            width: 100,
            height: 100,
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            filtered
                ? 'No $_selectedFilter requests'
                : 'No swap requests yet',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w800,
              color: _textColor,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            filtered
                ? 'Try another filter to see your other requests.'
                : 'Incoming and sent skill-swap requests will appear here when available.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: _mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACCEPT
  // ============================================================

  Future<void> _confirmAccept(
      SwapRequest request,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context: context,
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

    if (confirmed != true) {
      return;
    }

    await _performAction(
      requestId: request.id,
      action: () =>
          _controller.acceptRequest(
            request.id,
          ),
      successMessage:
      'Swap request accepted.',
    );
  }

  // ============================================================
  // DECLINE
  // ============================================================

  Future<void> _confirmDecline(
      SwapRequest request,
      ) async {
    if (_isProcessing(
      request.id,
    )) {
      return;
    }

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          _surfaceColor,
          title: Text(
            'Decline request?',
            style: TextStyle(
              fontWeight:
              FontWeight.w800,
              color: _textColor,
            ),
          ),
          content: Text(
            'This will decline the pending swap request. '
                'The request will move to Declined and can no longer be accepted.',
            style: TextStyle(
              color: _mutedColor,
              height: 1.4,
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
              ElevatedButton
                  .styleFrom(
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

    if (confirmed != true ||
        !mounted) {
      return;
    }

    await _performAction(
      requestId: request.id,
      action: () =>
          _controller.declineRequest(
            request.id,
          ),
      successMessage:
      'Swap request declined.',
    );
  }

  // ============================================================
  // CANCEL
  // ============================================================

  Future<void> _confirmCancel(
      SwapRequest request,
      ) async {
    if (_isProcessing(
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
      context: context,
      barrierDismissible: false,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          _surfaceColor,
          title: Text(
            scheduled
                ? 'Cancel scheduled session?'
                : 'Cancel request?',
            style: TextStyle(
              fontWeight:
              FontWeight.w800,
              color: _textColor,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: _mutedColor,
              height: 1.4,
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
              ElevatedButton
                  .styleFrom(
                backgroundColor:
                AppTheme.error,
                foregroundColor:
                Colors.white,
              ),
              child: Text(
                scheduled
                    ? 'CANCEL SESSION'
                    : 'CANCEL REQUEST',
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

    await _performAction(
      requestId: request.id,
      action: () =>
          _controller.cancelRequest(
            request.id,
          ),
      successMessage:
      scheduled
          ? 'Scheduled session cancelled.'
          : 'Swap request cancelled.',
    );
  }

  // ============================================================
  // CONFIRM SCHEDULE
  // ============================================================

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
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          title:
          const Text(
            'Confirm session schedule',
          ),
          content: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Text(
                _formatDateTime(
                  request.proposedAt,
                ),
                style: TextStyle(
                  fontWeight:
                  FontWeight.w700,
                  color: _textColor,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                request.mode,
                style: TextStyle(
                  color: _textColor,
                ),
              ),
              if (request
                  .meetingDetails
                  ?.trim()
                  .isNotEmpty ==
                  true) ...[
                const SizedBox(
                  height: 4,
                ),
                Text(
                  request
                      .meetingDetails!
                      .trim(),
                  style: TextStyle(
                    color:
                    _mutedColor,
                  ),
                ),
              ],
              const SizedBox(
                height: 16,
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
                  BorderRadius
                      .circular(
                    10,
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Icon(
                      Icons
                          .event_busy_outlined,
                      size: 17,
                      color:
                      _primaryColor,
                    ),
                    const SizedBox(
                      width: 7,
                    ),
                    Expanded(
                      child: Text(
                        'This will reserve a 1-hour session slot. TubiLearn will check both participants before confirming. If either person already has an overlapping confirmed session, this schedule will not be saved.',
                        style:
                        TextStyle(
                          fontSize:
                          11.5,
                          height: 1.4,
                          color:
                          _textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      requestId: request.id,
      action: () =>
          _controller.confirmSchedule(
            request.id,
          ),
      successMessage:
      'Session scheduled successfully.',
    );
  }

  // ============================================================
  // COMPLETE
  // ============================================================

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
      requestId: request.id,
      action: () =>
          _controller.completeRequest(
            request.id,
          ),
      successMessage:
      'Swap marked as completed.',
    );
  }

  // ============================================================
  // REMOVE HISTORY
  // ============================================================

  Future<void> _confirmRemoveFromHistory(
      SwapRequest request,
      ) async {
    if (_isProcessing(
      request.id,
    )) {
      return;
    }

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          _surfaceColor,
          title: Text(
            'Remove from history?',
            style: TextStyle(
              fontWeight:
              FontWeight.w800,
              color: _textColor,
            ),
          ),
          content: Text(
            'This only removes the terminal swap from your local history view. '
                'It does not cancel, complete, or change the result of the swap.',
            style: TextStyle(
              color: _mutedColor,
              height: 1.4,
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
              ElevatedButton
                  .styleFrom(
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

    if (confirmed != true ||
        !mounted) {
      return;
    }

    await _performAction(
      requestId: request.id,
      action: () =>
          _controller.removeFromHistory(
            request.id,
          ),
      successMessage:
      'Swap removed from your history.',
    );
  }

  // ============================================================
  // REVIEW
  // ============================================================

  Future<void> _openReviewDialog(
      SwapRequest request,
      ) async {
    if (_isProcessing(
      request.id,
    )) {
      return;
    }

    final _ReviewDialogResult? result =
    await showDialog<_ReviewDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (
          BuildContext dialogContext,
          ) {
        return _ReviewDialogContent(
          surfaceColor: _surfaceColor,
          textColor: _textColor,
          primaryColor: _primaryColor,
          mutedColor: _mutedColor,
        );
      },
    );

    if (result == null) {
      return;
    }

    await _performAction(
      requestId: request.id,
      action: () =>
          _controller.submitReview(
            requestId: request.id,
            rating: result.rating,
            comment: result.comment,
          ),
      successMessage:
      'Review submitted. Thank you!',
    );
  }

  // ============================================================
  // EDIT / RESCHEDULE
  // ============================================================

  Future<void> _editSchedule(
      SwapRequest request,
      User? otherUser,
      ) async {
    if (_isProcessing(
      request.id,
    )) {
      return;
    }

    late final List<String>
    supportedModes;

    try {
      supportedModes =
          _controller
              .supportedModesFor(
            request,
          );
    } on SwapRequestsControllerException catch (error) {
      _showMessage(
        error.message,
      );
      return;
    }

    final DateTime initialDate =
    DateTime(
      request.proposedAt.year,
      request.proposedAt.month,
      request.proposedAt.day,
    );

    final TimeOfDay initialTime =
    TimeOfDay(
      hour:
      request.proposedAt.hour,
      minute:
      request.proposedAt.minute,
    );

    final bool
    previousModeStillSupported =
    supportedModes.contains(
      request.mode,
    );

    final String initialMode =
    previousModeStillSupported
        ? request.mode
        : supportedModes.first;

    final String initialDetailsText =
    previousModeStillSupported
        ? request.meetingDetails ??
        ''
        : '';

    final _EditScheduleResult? result =
    await showDialog<_EditScheduleResult>(
      context: context,
      barrierDismissible: false,
      builder: (
          BuildContext dialogContext,
          ) {
        return _EditScheduleDialogContent(
          title:
          request.status ==
              SwapRequestStatus
                  .scheduled
              ? 'Reschedule session'
              : 'Edit schedule',
          otherUser: otherUser,
          initialDate: initialDate,
          initialTime: initialTime,
          initialMode: initialMode,
          initialDetailsText:
          initialDetailsText,
          supportedModes:
          supportedModes,
          surfaceColor: _surfaceColor,
          textColor: _textColor,
          primaryColor: _primaryColor,
          mutedColor: _mutedColor,
          softPrimaryColor:
          _softPrimaryColor,
          formatDate: _formatDateOnly,
          showMessage: _showMessage,
        );
      },
    );

    if (result == null) {
      return;
    }

    final DateTime proposedAt =
    DateTime(
      result.selectedDate.year,
      result.selectedDate.month,
      result.selectedDate.day,
      result.selectedTime.hour,
      result.selectedTime.minute,
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
      requestId: request.id,
      action: () =>
          _controller.updateSchedule(
            requestId: request.id,
            proposedAt: proposedAt,
            mode: result.selectedMode,
            meetingDetails:
            result.meetingDetails,
          ),
      successMessage:
      request.status ==
          SwapRequestStatus
              .scheduled
          ? 'Session rescheduled. Please confirm the new schedule.'
          : 'Schedule updated.',
    );
  }

  // ============================================================
  // ACTION EXECUTION
  // ============================================================

  bool _isProcessing(
      String requestId,
      ) {
    return _processingRequestIds.contains(
      requestId,
    );
  }

  Future<void> _performAction({
    required String requestId,
    required Future<SwapRequestsSnapshot>
    Function()
    action,
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
      final SwapRequestsSnapshot snapshot =
      await action();

      if (!mounted) {
        return;
      }

      _applySnapshot(
        snapshot,
      );

      _scheduleSessionBoundaryRefresh();

      _showMessage(
        successMessage,
      );
    } on SwapRequestsControllerException catch (error) {
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

  // ============================================================
  // MESSAGE
  // ============================================================

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
        content: Text(
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

    return '${months[value.month - 1]} '
        '${value.day}, ${value.year}';
  }

  String _formatDateTime(
      DateTime value,
      ) {
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

// ============================================================
// REVIEW DIALOG
// ============================================================

/// Result of the review dialog: the chosen rating and trimmed comment on
/// submit, or null (via Navigator.pop with no result) on cancel.
class _ReviewDialogResult {
  final int rating;
  final String comment;

  const _ReviewDialogResult({
    required this.rating,
    required this.comment,
  });
}

/// Owns the review dialog's rating/comment state in its own State, so the
/// comment TextEditingController is disposed only after this widget is
/// actually unmounted (i.e. after the dialog route's exit animation
/// finishes) rather than right after showDialog's Future resolves.
///
/// Colors are passed in from the screen rather than read from
/// Theme.of(context), since the screen computes its own dark-mode-aware
/// colors independently of the ambient Theme.
class _ReviewDialogContent extends StatefulWidget {
  final Color surfaceColor;
  final Color textColor;
  final Color primaryColor;
  final Color mutedColor;

  const _ReviewDialogContent({
    required this.surfaceColor,
    required this.textColor,
    required this.primaryColor,
    required this.mutedColor,
  });

  @override
  State<_ReviewDialogContent> createState() => _ReviewDialogContentState();
}

class _ReviewDialogContentState extends State<_ReviewDialogContent> {
  late final TextEditingController _commentController;
  int _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.surfaceColor,
      title: Text(
        'Rate your swap partner',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: widget.textColor,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How was your completed skill swap?',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: widget.mutedColor,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(5, (int index) {
                final int starValue = index + 1;
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedRating = starValue;
                    });
                  },
                  icon: Icon(
                    starValue <= _selectedRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 34,
                    color: starValue <= _selectedRating
                        ? const Color(0xFFF2A65A)
                        : widget.mutedColor,
                  ),
                );
              }),
            ),
            if (_selectedRating > 0) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '$_selectedRating out of 5',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.primaryColor,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'Comment (optional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: widget.textColor,
              ),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: _commentController,
              maxLength: 500,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share what went well about the swap...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, null);
          },
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _selectedRating <= 0
              ? null
              : () {
                  Navigator.pop(
                    context,
                    _ReviewDialogResult(
                      rating: _selectedRating,
                      comment: _commentController.text.trim(),
                    ),
                  );
                },
          child: const Text('SUBMIT REVIEW'),
        ),
      ],
    );
  }
}

// ============================================================
// EDIT SCHEDULE DIALOG
// ============================================================

/// Result of the edit-schedule dialog: the chosen date/time/mode and
/// trimmed meeting details on save, or null (via Navigator.pop with no
/// result) on cancel.
class _EditScheduleResult {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final String selectedMode;
  final String meetingDetails;

  const _EditScheduleResult({
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedMode,
    required this.meetingDetails,
  });
}

/// Owns the edit-schedule dialog's date/time/mode/details state in its
/// own State, so the meeting-details TextEditingController is disposed
/// only after this widget is actually unmounted (i.e. after the dialog
/// route's exit animation finishes) rather than right after showDialog's
/// Future resolves.
///
/// Colors and the date-formatting/message helpers are passed in from the
/// screen rather than read from Theme.of(context)/called directly, since
/// the screen computes its own dark-mode-aware colors independently of
/// the ambient Theme and owns the SnackBar-showing helper.
class _EditScheduleDialogContent extends StatefulWidget {
  final String title;
  final User? otherUser;
  final DateTime initialDate;
  final TimeOfDay initialTime;
  final String initialMode;
  final String initialDetailsText;
  final List<String> supportedModes;
  final Color surfaceColor;
  final Color textColor;
  final Color primaryColor;
  final Color mutedColor;
  final Color softPrimaryColor;
  final String Function(DateTime) formatDate;
  final void Function(String) showMessage;

  const _EditScheduleDialogContent({
    required this.title,
    required this.otherUser,
    required this.initialDate,
    required this.initialTime,
    required this.initialMode,
    required this.initialDetailsText,
    required this.supportedModes,
    required this.surfaceColor,
    required this.textColor,
    required this.primaryColor,
    required this.mutedColor,
    required this.softPrimaryColor,
    required this.formatDate,
    required this.showMessage,
  });

  @override
  State<_EditScheduleDialogContent> createState() =>
      _EditScheduleDialogContentState();
}

class _EditScheduleDialogContentState
    extends State<_EditScheduleDialogContent> {
  late final TextEditingController _detailsController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedMode;

  @override
  void initState() {
    super.initState();
    _detailsController = TextEditingController(
      text: widget.initialDetailsText,
    );
    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;
    _selectedMode = widget.initialMode;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Widget _buildOtherPartyPreferencesCard() {
    final User? otherUser = widget.otherUser;

    if (otherUser == null) {
      return const SizedBox.shrink();
    }

    final String availability = otherUser.availability.trim();
    final String preferredMode = otherUser.preferredMode.trim();

    final bool showAvailability =
        availability.isNotEmpty && availability != 'Not set';
    final bool showMode =
        preferredMode.isNotEmpty && preferredMode != 'Not set';

    if (!showAvailability && !showMode) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.softPrimaryColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.primaryColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 16,
              color: widget.primaryColor,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${otherUser.name} prefers',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (showAvailability)
                    Text(
                      'Availability: $availability',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: widget.mutedColor,
                      ),
                    ),
                  if (showMode)
                    Text(
                      'Mode: $preferredMode',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: widget.mutedColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.surfaceColor,
      title: Text(
        widget.title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: widget.textColor,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOtherPartyPreferencesCard(),
            Text(
              'Choose a new date, time, mode, and meeting details.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: widget.mutedColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final DateTime? result = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate.isBefore(DateTime.now())
                            ? DateTime.now()
                            : _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                      );

                      if (result == null) {
                        return;
                      }

                      setState(() {
                        _selectedDate = result;
                      });
                    },
                    icon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                    ),
                    label: Text(widget.formatDate(_selectedDate)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final TimeOfDay? result = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );

                      if (result == null) {
                        return;
                      }

                      setState(() {
                        _selectedTime = result;
                      });
                    },
                    icon: const Icon(
                      Icons.schedule_rounded,
                      size: 18,
                    ),
                    label: Text(_selectedTime.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Session mode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: widget.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Only modes supported by both skills can be selected.',
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: widget.mutedColor,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: widget.supportedModes.contains('Online')
                        ? 1
                        : 0.48,
                    child: ChoiceChip(
                      label: const Text('Online'),
                      selected: _selectedMode == 'Online',
                      showCheckmark: false,
                      onSelected: widget.supportedModes.contains('Online')
                          ? (_) {
                              if (_selectedMode == 'Online') {
                                return;
                              }

                              setState(() {
                                _selectedMode = 'Online';
                                _detailsController.clear();
                              });
                            }
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Opacity(
                    opacity: widget.supportedModes.contains('In-person')
                        ? 1
                        : 0.48,
                    child: ChoiceChip(
                      label: const Text('In-person'),
                      selected: _selectedMode == 'In-person',
                      showCheckmark: false,
                      onSelected: widget.supportedModes.contains('In-person')
                          ? (_) {
                              if (_selectedMode == 'In-person') {
                                return;
                              }

                              setState(() {
                                _selectedMode = 'In-person';
                                _detailsController.clear();
                              });
                            }
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _selectedMode == 'Online' ? 'Online platform' : 'Meeting area',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: widget.textColor,
              ),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: _detailsController,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: _selectedMode == 'Online'
                    ? 'Example: Google Meet or Messenger'
                    : 'Example: DCT campus or public café',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.softPrimaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: widget.primaryColor,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Confirmed sessions reserve a 1-hour slot. When this schedule is confirmed, TubiLearn checks both participants for overlapping confirmed sessions.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: widget.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, null);
          },
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            final String details = _detailsController.text.trim();

            if (details.isEmpty) {
              widget.showMessage(
                _selectedMode == 'Online'
                    ? 'Please enter an online platform.'
                    : 'Please enter a meeting area.',
              );
              return;
            }

            Navigator.pop(
              context,
              _EditScheduleResult(
                selectedDate: _selectedDate,
                selectedTime: _selectedTime,
                selectedMode: _selectedMode,
                meetingDetails: details,
              ),
            );
          },
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}
