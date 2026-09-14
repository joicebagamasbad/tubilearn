import 'dart:io';

import 'package:flutter/material.dart';

import '../../controller/swap_requests_controller.dart';
import '../../model/swap_request.dart';
import '../../model/user.dart';
import '../../theme/app_theme.dart';

class SwapRequestCard extends StatelessWidget {
  const SwapRequestCard({
    super.key,
    required this.managedRequest,
    required this.isProcessing,
    required this.canAccept,
    required this.canDecline,
    required this.canCancel,
    required this.canEditSchedule,
    required this.canSchedule,
    required this.canComplete,
    required this.canReview,
    required this.canRemoveFromHistory,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
    required this.onEditSchedule,
    required this.onConfirmSchedule,
    required this.onComplete,
    required this.onReview,
    required this.onRemoveFromHistory,
  });

  final ManagedSwapRequest managedRequest;

  final bool isProcessing;

  final bool canAccept;
  final bool canDecline;
  final bool canCancel;
  final bool canEditSchedule;
  final bool canSchedule;
  final bool canComplete;
  final bool canReview;
  final bool canRemoveFromHistory;

  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onCancel;
  final VoidCallback onEditSchedule;
  final VoidCallback onConfirmSchedule;
  final VoidCallback onComplete;
  final VoidCallback onReview;
  final VoidCallback onRemoveFromHistory;

  SwapRequest get _request =>
      managedRequest.request;

  User? get _otherUser =>
      managedRequest.otherUser;

  bool get _isIncoming =>
      managedRequest.isIncoming;

  bool get _isOutgoing =>
      managedRequest.isOutgoing;

  // ============================================================
  // THEME
  // ============================================================

  bool _isDarkMode(
      BuildContext context,
      ) {
    return Theme.of(context).brightness ==
        Brightness.dark;
  }

  Color _primaryColor(
      BuildContext context,
      ) {
    return Theme.of(context)
        .colorScheme
        .primary;
  }

  Color _surfaceColor(
      BuildContext context,
      ) {
    return Theme.of(context)
        .colorScheme
        .surface;
  }

  Color _surfaceVariantColor(
      BuildContext context,
      ) {
    return Theme.of(context)
        .colorScheme
        .surfaceContainerHighest;
  }

  Color _textColor(
      BuildContext context,
      ) {
    return Theme.of(context)
        .colorScheme
        .onSurface;
  }

  Color _mutedColor(
      BuildContext context,
      ) {
    return Theme.of(context)
        .colorScheme
        .onSurfaceVariant;
  }

  Color _borderColor(
      BuildContext context,
      ) {
    return Theme.of(context)
        .colorScheme
        .outlineVariant;
  }

  Color _softPrimaryColor(
      BuildContext context,
      ) {
    if (_isDarkMode(context)) {
      return _primaryColor(
        context,
      ).withValues(
        alpha: 0.16,
      );
    }

    return const Color(
      0xFFE4F0EF,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final User? otherUser =
        _otherUser;

    final String displayInitials =
        otherUser?.initials ??
            (_isIncoming
                ? '?'
                : _request.providerInitials);

    final String displayName =
        otherUser?.name ??
            (_isIncoming
                ? 'Incoming skill request'
                : _request.providerName);

    final String displayCity =
        otherUser?.city ??
            (_isIncoming
                ? 'Sender profile unavailable'
                : _request.providerCity);

    return Container(
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color:
        _surfaceColor(
          context,
        ),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
          _borderColor(
            context,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _buildHeader(
            context,
          ),

          const SizedBox(
            height: 14,
          ),

          _buildParticipant(
            context,
            user: otherUser,
            initials:
            displayInitials,
            name:
            displayName,
            city:
            displayCity,
          ),

          const SizedBox(
            height: 16,
          ),

          _buildSkillSummary(
            context,
          ),

          const SizedBox(
            height: 14,
          ),

          _buildDetailRow(
            context,
            Icons
                .calendar_today_outlined,
            _formatDateTime(
              _request.proposedAt,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          _buildDetailRow(
            context,
            _request.mode ==
                'Online'
                ? Icons
                .videocam_outlined
                : Icons
                .location_on_outlined,
            _request.mode,
          ),

          if (_request.meetingDetails
              ?.trim()
              .isNotEmpty ==
              true) ...[
            const SizedBox(
              height: 8,
            ),

            _buildDetailRow(
              context,
              Icons.info_outline,
              _request
                  .meetingDetails!
                  .trim(),
            ),
          ],

          if (_request.status ==
              SwapRequestStatus
                  .accepted) ...[
            const SizedBox(
              height: 10,
            ),
            _buildInfoPanel(
              context,
              text:
              'Schedule is awaiting confirmation. Confirming checks both participants for overlapping confirmed sessions.',
            ),
          ],

          if (_request.status ==
              SwapRequestStatus
                  .scheduled &&
              DateTime.now()
                  .isBefore(
                _request.proposedAt,
              )) ...[
            const SizedBox(
              height: 10,
            ),
            _buildUpcomingPanel(
              context,
            ),
          ],

          if (_request.status ==
              SwapRequestStatus
                  .completed &&
              managedRequest
                  .hasReviewed) ...[
            const SizedBox(
              height: 10,
            ),
            _buildReviewedPanel(
              context,
            ),
          ],

          if (_request.note
              ?.trim()
              .isNotEmpty ==
              true) ...[
            const SizedBox(
              height: 12,
            ),
            _buildNote(
              context,
            ),
          ],

          if (_hasAvailableAction) ...[
            const SizedBox(
              height: 16,
            ),
            _buildActions(
              context,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
      BuildContext context,
      ) {
    return Row(
      children: [
        _buildDirectionBadge(
          context,
        ),

        const Spacer(),

        if (isProcessing)
          Padding(
            padding:
            const EdgeInsets.only(
              right: 10,
            ),
            child: SizedBox(
              width: 16,
              height: 16,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color:
                _primaryColor(
                  context,
                ),
              ),
            ),
          ),

        _buildStatusBadge(
          context,
        ),
      ],
    );
  }

  // ============================================================
  // PARTICIPANT
  // ============================================================

  Widget _buildParticipant(
      BuildContext context, {
        required User? user,
        required String initials,
        required String name,
        required String city,
      }) {
    return Row(
      children: [
        _buildUserAvatar(
          context,
          user: user,
          initials: initials,
          size: 46,
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
              Text(
                name,
                maxLines: 1,
                overflow:
                TextOverflow
                    .ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight
                      .w800,
                  color:
                  _textColor(
                    context,
                  ),
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                city,
                maxLines: 1,
                overflow:
                TextOverflow
                    .ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color:
                  _mutedColor(
                    context,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildUserAvatar(
      BuildContext context, {
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
          fit: BoxFit.cover,
          errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace?
              stackTrace,
              ) {
            return _buildInitialAvatar(
              initials:
              initials,
              size:
              size,
            );
          },
        )
            : _buildInitialAvatar(
          initials:
          initials,
          size:
          size,
        ),
      ),
    );
  }

  Widget _buildInitialAvatar({
    required String initials,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      color: AppTheme.accent,
      alignment:
      Alignment.center,
      child: Text(
        initials.trim().isEmpty
            ? '?'
            : initials,
        style: TextStyle(
          fontSize: 12,
          fontWeight:
          FontWeight.w800,
          color: Colors.white,
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
  // SKILLS
  // ============================================================

  Widget _buildSkillSummary(
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        13,
      ),
      decoration: BoxDecoration(
        color:
        _surfaceVariantColor(
          context,
        ),
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color:
          _borderColor(
            context,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildSkillRow(
            context,
            icon:
            Icons.school_outlined,
            label:
            'Learn',
            value:
            _request.skillToLearn,
          ),

          const SizedBox(
            height: 9,
          ),

          _buildSkillRow(
            context,
            icon:
            Icons
                .handshake_outlined,
            label:
            'Offer',
            value:
            _request.skillToOffer,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
      }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color:
          _primaryColor(
            context,
          ),
        ),

        const SizedBox(
          width: 9,
        ),

        SizedBox(
          width: 46,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 11.5,
              color:
              _mutedColor(
                context,
              ),
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight:
              FontWeight
                  .w700,
              color:
              _textColor(
                context,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DETAILS
  // ============================================================

  Widget _buildDetailRow(
      BuildContext context,
      IconData icon,
      String text,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color:
          _mutedColor(
            context,
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color:
              _mutedColor(
                context,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INFO PANELS
  // ============================================================

  Widget _buildInfoPanel(
      BuildContext context, {
        required String text,
      }) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        10,
      ),
      decoration: BoxDecoration(
        color:
        _softPrimaryColor(
          context,
        ),
        borderRadius:
        BorderRadius.circular(
          10,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight:
          FontWeight.w600,
          color:
          _primaryColor(
            context,
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingPanel(
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        10,
      ),
      decoration: BoxDecoration(
        color:
        _softPrimaryColor(
          context,
        ),
        borderRadius:
        BorderRadius.circular(
          10,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 17,
            color:
            _primaryColor(
              context,
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          Expanded(
            child: Text(
              'This session is still upcoming.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight:
                FontWeight
                    .w600,
                color:
                _primaryColor(
                  context,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewedPanel(
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        10,
      ),
      decoration: BoxDecoration(
        color:
        _softPrimaryColor(
          context,
        ),
        borderRadius:
        BorderRadius.circular(
          10,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star_rounded,
            size: 18,
            color:
            _primaryColor(
              context,
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          Expanded(
            child: Text(
              'You reviewed this swap partner.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight:
                FontWeight
                    .w600,
                color:
                _primaryColor(
                  context,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTE
  // ============================================================

  Widget _buildNote(
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color:
        _softPrimaryColor(
          context,
        ),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),
      child: Text(
        _request.note!.trim(),
        style: TextStyle(
          fontSize: 12.5,
          height: 1.4,
          color:
          _textColor(
            context,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DIRECTION BADGE
  // ============================================================

  Widget _buildDirectionBadge(
      BuildContext context,
      ) {
    final String text;

    final IconData icon;

    if (_isIncoming) {
      text = 'Incoming';
      icon =
          Icons.call_received_rounded;
    } else if (_isOutgoing) {
      text = 'Outgoing';
      icon =
          Icons.call_made_rounded;
    } else {
      text = 'Unrelated';
      icon =
          Icons.help_outline_rounded;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
        _softPrimaryColor(
          context,
        ),
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
            size: 13,
            color:
            _primaryColor(
              context,
            ),
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight:
              FontWeight
                  .w800,
              color:
              _primaryColor(
                context,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(
      BuildContext context,
      ) {
    final SwapRequestStatus status =
        _request.status;

    late final Color color;

    switch (status) {
      case SwapRequestStatus.pending:
        color =
        _isDarkMode(
          context,
        )
            ? const Color(
          0xFFFFB74D,
        )
            : Colors.orange;

      case SwapRequestStatus.accepted:
        color =
        _isDarkMode(
          context,
        )
            ? const Color(
          0xFF81C784,
        )
            : AppTheme.success;

      case SwapRequestStatus.declined:
        color =
            AppTheme.error;

      case SwapRequestStatus.scheduled:
        color =
        _isDarkMode(
          context,
        )
            ? const Color(
          0xFF64B5F6,
        )
            : Colors.blue;

      case SwapRequestStatus.completed:
        color =
        _isDarkMode(
          context,
        )
            ? const Color(
          0xFF80CBC4,
        )
            : Colors.teal;

      case SwapRequestStatus.cancelled:
        color =
            _mutedColor(
              context,
            );
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha:
          _isDarkMode(
            context,
          )
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
        style: TextStyle(
          fontSize: 10.5,
          fontWeight:
          FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  bool get _hasAvailableAction =>
      canAccept ||
          canDecline ||
          canCancel ||
          canEditSchedule ||
          canSchedule ||
          canComplete ||
          canReview ||
          canRemoveFromHistory;

  Widget _buildActions(
      BuildContext context,
      ) {
    final bool blocked =
        isProcessing;

    if (_isIncoming &&
        canAccept &&
        canDecline) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed:
              blocked
                  ? null
                  : onDecline,
              child:
              const Text(
                'DECLINE',
              ),
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: ElevatedButton(
              onPressed:
              blocked
                  ? null
                  : onAccept,
              child:
              const Text(
                'ACCEPT',
              ),
            ),
          ),
        ],
      );
    }

    if (_request.status ==
        SwapRequestStatus.accepted) {
      return Column(
        children: [
          if (canEditSchedule)
            SizedBox(
              width:
              double.infinity,
              child:
              OutlinedButton.icon(
                onPressed:
                blocked
                    ? null
                    : onEditSchedule,
                icon:
                const Icon(
                  Icons
                      .edit_calendar_outlined,
                  size: 18,
                ),
                label:
                const Text(
                  'EDIT SCHEDULE',
                ),
              ),
            ),

          if (canEditSchedule &&
              canSchedule)
            const SizedBox(
              height: 9,
            ),

          if (canSchedule)
            SizedBox(
              width:
              double.infinity,
              child:
              ElevatedButton.icon(
                onPressed:
                blocked
                    ? null
                    : onConfirmSchedule,
                icon:
                const Icon(
                  Icons
                      .event_available_outlined,
                  size: 18,
                ),
                label:
                const Text(
                  'CONFIRM SCHEDULE',
                ),
              ),
            ),

          if ((canEditSchedule ||
              canSchedule) &&
              canCancel)
            const SizedBox(
              height: 9,
            ),

          if (canCancel)
            _buildCancelButton(
              blocked:
              blocked,
            ),
        ],
      );
    }

    if (_request.status ==
        SwapRequestStatus.scheduled) {
      final bool
      sessionTimeReached =
      !DateTime.now().isBefore(
        _request.proposedAt,
      );

      return Column(
        children: [
          if (canEditSchedule)
            SizedBox(
              width:
              double.infinity,
              child:
              OutlinedButton.icon(
                onPressed:
                blocked
                    ? null
                    : onEditSchedule,
                icon:
                const Icon(
                  Icons.update_rounded,
                  size: 18,
                ),
                label:
                const Text(
                  'RESCHEDULE',
                ),
              ),
            ),

          if (canEditSchedule)
            const SizedBox(
              height: 9,
            ),

          if (canComplete)
            SizedBox(
              width:
              double.infinity,
              child:
              ElevatedButton(
                onPressed:
                blocked ||
                    !sessionTimeReached
                    ? null
                    : onComplete,
                child: Text(
                  sessionTimeReached
                      ? 'MARK AS COMPLETED'
                      : 'SESSION UPCOMING',
                ),
              ),
            ),

          if ((canEditSchedule ||
              canComplete) &&
              canCancel)
            const SizedBox(
              height: 9,
            ),

          if (canCancel)
            _buildCancelButton(
              blocked:
              blocked,
            ),
        ],
      );
    }

    if (_request.status ==
        SwapRequestStatus.completed) {
      return Column(
        children: [
          if (canReview)
            SizedBox(
              width:
              double.infinity,
              child:
              ElevatedButton.icon(
                onPressed:
                blocked
                    ? null
                    : onReview,
                icon:
                const Icon(
                  Icons
                      .star_outline_rounded,
                  size: 19,
                ),
                label:
                const Text(
                  'RATE SWAP PARTNER',
                ),
              ),
            ),

          if (canReview &&
              canRemoveFromHistory)
            const SizedBox(
              height: 9,
            ),

          if (canRemoveFromHistory)
            SizedBox(
              width:
              double.infinity,
              child:
              OutlinedButton.icon(
                onPressed:
                blocked
                    ? null
                    : onRemoveFromHistory,
                icon:
                const Icon(
                  Icons.archive_outlined,
                  size: 18,
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

    if (canCancel) {
      return _buildCancelButton(
        blocked:
        blocked,
      );
    }

    if (canRemoveFromHistory) {
      return SizedBox(
        width: double.infinity,
        child:
        OutlinedButton.icon(
          onPressed:
          blocked
              ? null
              : onRemoveFromHistory,
          icon:
          const Icon(
            Icons.archive_outlined,
            size: 18,
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

  Widget _buildCancelButton({
    required bool blocked,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed:
        blocked
            ? null
            : onCancel,
        child:
        const Text(
          'CANCEL REQUEST',
        ),
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

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