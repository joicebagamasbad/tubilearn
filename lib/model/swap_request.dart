enum SwapRequestStatus {
  pending,
  accepted,
  declined,
  scheduled,
  completed,
  cancelled,
}

// ============================================================
// REQUEST DIRECTION
// ============================================================

enum SwapRequestDirection {
  outgoing,
  incoming,
  unrelated,
}

extension SwapRequestDirectionExtension
on SwapRequestDirection {
  String get label {
    switch (this) {
      case SwapRequestDirection.outgoing:
        return 'Outgoing';

      case SwapRequestDirection.incoming:
        return 'Incoming';

      case SwapRequestDirection.unrelated:
        return 'Unrelated';
    }
  }
}

// ============================================================
// STATUS
// ============================================================

extension SwapRequestStatusExtension
on SwapRequestStatus {
  String get databaseValue => name;

  String get label {
    switch (this) {
      case SwapRequestStatus.pending:
        return 'Pending';

      case SwapRequestStatus.accepted:
        return 'Accepted';

      case SwapRequestStatus.declined:
        return 'Declined';

      case SwapRequestStatus.scheduled:
        return 'Scheduled';

      case SwapRequestStatus.completed:
        return 'Completed';

      case SwapRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive {
    switch (this) {
      case SwapRequestStatus.pending:
      case SwapRequestStatus.accepted:
      case SwapRequestStatus.scheduled:
        return true;

      case SwapRequestStatus.declined:
      case SwapRequestStatus.completed:
      case SwapRequestStatus.cancelled:
        return false;
    }
  }

  bool get isTerminal => !isActive;

  bool get canBeCancelled {
    return this == SwapRequestStatus.pending ||
        this == SwapRequestStatus.accepted ||
        this == SwapRequestStatus.scheduled;
  }

  bool canTransitionTo(
      SwapRequestStatus next,
      ) {
    switch (this) {
      case SwapRequestStatus.pending:
        return next ==
            SwapRequestStatus.accepted ||
            next ==
                SwapRequestStatus.declined ||
            next ==
                SwapRequestStatus.cancelled;

      case SwapRequestStatus.accepted:
        return next ==
            SwapRequestStatus.scheduled ||
            next ==
                SwapRequestStatus.cancelled;

      case SwapRequestStatus.scheduled:
        return next ==
            SwapRequestStatus.completed ||
            next ==
                SwapRequestStatus.cancelled;

      case SwapRequestStatus.declined:
      case SwapRequestStatus.completed:
      case SwapRequestStatus.cancelled:
        return false;
    }
  }

  static SwapRequestStatus fromDatabase(
      String value,
      ) {
    final String cleanValue =
    value.trim();

    for (final status
    in SwapRequestStatus.values) {
      if (status.name == cleanValue) {
        return status;
      }
    }

    throw FormatException(
      'Invalid swap request status: $value',
    );
  }
}

// ============================================================
// SWAP REQUEST
// ============================================================

class SwapRequest {
  final String id;

  final String? requesterUserId;
  final String? providerUserId;

  final String? skillToLearnId;
  final String? skillToOfferId;

  final String providerName;
  final String providerInitials;
  final String providerCity;

  final String skillToLearn;
  final String skillToOffer;

  final DateTime proposedAt;

  final String mode;

  final String? meetingDetails;
  final String? note;

  SwapRequestStatus status;

  final DateTime createdAt;

  DateTime updatedAt;

  SwapRequest({
    required this.id,

    this.requesterUserId,
    this.providerUserId,
    this.skillToLearnId,
    this.skillToOfferId,

    required this.providerName,
    required this.providerInitials,
    required this.providerCity,

    required this.skillToLearn,
    required this.skillToOffer,

    required this.proposedAt,

    required this.mode,

    this.meetingDetails,
    this.note,

    required this.status,

    required this.createdAt,
    required this.updatedAt,
  });

  // ==========================================================
  // STABLE IDENTITY
  // ==========================================================

  bool get hasStableIdentity {
    return _hasValue(
      requesterUserId,
    ) &&
        _hasValue(
          providerUserId,
        ) &&
        _hasValue(
          skillToLearnId,
        ) &&
        _hasValue(
          skillToOfferId,
        );
  }

  bool get hasRequesterIdentity {
    return _hasValue(
      requesterUserId,
    );
  }

  bool get hasProviderIdentity {
    return _hasValue(
      providerUserId,
    );
  }

  bool get hasSkillIdentity {
    return _hasValue(
      skillToLearnId,
    ) &&
        _hasValue(
          skillToOfferId,
        );
  }

  // ==========================================================
  // USER RELATIONSHIP
  // ==========================================================

  bool isRequester(
      String userId,
      ) {
    final String normalizedUserId =
    userId.trim();

    if (normalizedUserId.isEmpty) {
      return false;
    }

    return requesterUserId ==
        normalizedUserId;
  }

  bool isProvider(
      String userId,
      ) {
    final String normalizedUserId =
    userId.trim();

    if (normalizedUserId.isEmpty) {
      return false;
    }

    return providerUserId ==
        normalizedUserId;
  }

  bool involvesUser(
      String userId,
      ) {
    return isRequester(userId) ||
        isProvider(userId);
  }

  // ==========================================================
  // DIRECTION
  // ==========================================================

  SwapRequestDirection directionFor(
      String userId,
      ) {
    if (isRequester(userId)) {
      return SwapRequestDirection.outgoing;
    }

    if (isProvider(userId)) {
      return SwapRequestDirection.incoming;
    }

    return SwapRequestDirection.unrelated;
  }

  bool isOutgoingFor(
      String userId,
      ) {
    return directionFor(userId) ==
        SwapRequestDirection.outgoing;
  }

  bool isIncomingFor(
      String userId,
      ) {
    return directionFor(userId) ==
        SwapRequestDirection.incoming;
  }

  // ==========================================================
  // PERMISSIONS
  // ==========================================================

  bool canCancel(
      String userId,
      ) {
    return isRequester(userId) &&
        status.canBeCancelled;
  }

  bool canAccept(
      String userId,
      ) {
    return isProvider(userId) &&
        status ==
            SwapRequestStatus.pending;
  }

  bool canDecline(
      String userId,
      ) {
    return isProvider(userId) &&
        status ==
            SwapRequestStatus.pending;
  }

  bool canRespond(
      String userId,
      ) {
    return canAccept(userId) ||
        canDecline(userId);
  }

  // ----------------------------------------------------------
  // Scheduling
  //
  // For the current local product rule, either participant may
  // confirm an accepted swap as scheduled.
  // ----------------------------------------------------------

  bool canSchedule(
      String userId,
      ) {
    return involvesUser(userId) &&
        status ==
            SwapRequestStatus.accepted;
  }

  // ----------------------------------------------------------
  // Completion
  //
  // Either participant may mark a scheduled swap completed.
  //
  // This keeps the existing behavior but moves the permission
  // rule into the domain model instead of duplicating it inside
  // SwapService.
  // ----------------------------------------------------------

  bool canComplete(
      String userId,
      ) {
    return involvesUser(userId) &&
        status ==
            SwapRequestStatus.scheduled;
  }

  // ==========================================================
  // SECURITY / ACCESS
  // ==========================================================

  bool canViewAsParticipant(
      String userId,
      ) {
    return involvesUser(userId);
  }

  bool canModify(
      String userId,
      ) {
    return canCancel(userId) ||
        canAccept(userId) ||
        canDecline(userId) ||
        canSchedule(userId) ||
        canComplete(userId);
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  static bool _hasValue(
      String? value,
      ) {
    return value != null &&
        value.trim().isNotEmpty;
  }
}