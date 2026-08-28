enum SwapRequestStatus {
  pending,
  accepted,
  declined,
  scheduled,
  completed,
  cancelled,
}

extension SwapRequestStatusExtension on SwapRequestStatus {
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
        return next == SwapRequestStatus.accepted ||
            next == SwapRequestStatus.declined ||
            next == SwapRequestStatus.cancelled;

      case SwapRequestStatus.accepted:
        return next == SwapRequestStatus.scheduled ||
            next == SwapRequestStatus.cancelled;

      case SwapRequestStatus.scheduled:
        return next == SwapRequestStatus.completed ||
            next == SwapRequestStatus.cancelled;

      case SwapRequestStatus.declined:
      case SwapRequestStatus.completed:
      case SwapRequestStatus.cancelled:
        return false;
    }
  }

  static SwapRequestStatus fromDatabase(
      String value,
      ) {
    for (final status
    in SwapRequestStatus.values) {
      if (status.name == value) {
        return status;
      }
    }

    throw FormatException(
      'Invalid swap request status: $value',
    );
  }
}

class SwapRequest {
  final String id;

  // ============================================================
  // STABLE IDENTITY
  //
  // Nullable temporarily so existing database v3 rows can still
  // be loaded before the v4 migration is performed.
  //
  // New requests will later be required by SwapService to provide
  // all four IDs.
  // ============================================================

  final String? requesterUserId;

  final String? providerUserId;

  final String? skillToLearnId;

  final String? skillToOfferId;

  // ============================================================
  // DISPLAY SNAPSHOTS
  //
  // These are NOT the primary identity of the request.
  // They are kept as readable snapshots for the UI and for
  // preserving historical information if a profile changes later.
  // ============================================================

  final String providerName;

  final String providerInitials;

  final String providerCity;

  final String skillToLearn;

  final String skillToOffer;

  // ============================================================
  // REQUEST DETAILS
  // ============================================================

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

  // ============================================================
  // IDENTITY HELPERS
  // ============================================================

  bool get hasStableIdentity {
    return _hasValue(requesterUserId) &&
        _hasValue(providerUserId) &&
        _hasValue(skillToLearnId) &&
        _hasValue(skillToOfferId);
  }

  bool isRequester(
      String userId,
      ) {
    final String normalizedUserId =
    userId.trim();

    return normalizedUserId.isNotEmpty &&
        requesterUserId ==
            normalizedUserId;
  }

  bool isProvider(
      String userId,
      ) {
    final String normalizedUserId =
    userId.trim();

    return normalizedUserId.isNotEmpty &&
        providerUserId ==
            normalizedUserId;
  }

  bool involvesUser(
      String userId,
      ) {
    return isRequester(userId) ||
        isProvider(userId);
  }

  static bool _hasValue(
      String? value,
      ) {
    return value != null &&
        value.trim().isNotEmpty;
  }
}