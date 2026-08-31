enum SwapRequestStatus {
  pending,
  accepted,
  declined,
  scheduled,
  completed,
  cancelled,
}

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
    final String cleanValue =
    value.trim();

    for (final SwapRequestStatus status
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

  bool get hasStableIdentity {
    return hasParticipantIdentity &&
        hasSkillIdentity;
  }

  bool get hasParticipantIdentity {
    return _hasValue(
      requesterUserId,
    ) &&
        _hasValue(
          providerUserId,
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

  bool get hasPartialStableIdentity {
    final int presentValues =
        <String?>[
          requesterUserId,
          providerUserId,
          skillToLearnId,
          skillToOfferId,
        ].where(
              (
              String? value,
              ) =>
              _hasValue(
                value,
              ),
        ).length;

    return presentValues > 0 &&
        presentValues < 4;
  }

  bool get requiresStableIdentityForActions =>
      status.isActive;

  bool get canUseHistoricalSnapshot =>
      status.isTerminal;

  bool get hasStructurallyValidIdentityGroup =>
      !hasPartialStableIdentity;

  bool get hasUsableHistoricalSnapshot {
    return providerName.trim().isNotEmpty &&
        providerInitials.trim().isNotEmpty &&
        providerCity.trim().isNotEmpty &&
        skillToLearn.trim().isNotEmpty &&
        skillToOffer.trim().isNotEmpty;
  }

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
    return isRequester(
      userId,
    ) ||
        isProvider(
          userId,
        );
  }

  SwapRequestDirection directionFor(
      String userId,
      ) {
    if (isRequester(
      userId,
    )) {
      return SwapRequestDirection.outgoing;
    }

    if (isProvider(
      userId,
    )) {
      return SwapRequestDirection.incoming;
    }

    return SwapRequestDirection.unrelated;
  }

  bool isOutgoingFor(
      String userId,
      ) {
    return directionFor(
      userId,
    ) ==
        SwapRequestDirection.outgoing;
  }

  bool isIncomingFor(
      String userId,
      ) {
    return directionFor(
      userId,
    ) ==
        SwapRequestDirection.incoming;
  }

  bool canCancel(
      String userId,
      ) {
    return hasStableIdentity &&
        isRequester(
          userId,
        ) &&
        status.canBeCancelled;
  }

  bool canAccept(
      String userId,
      ) {
    return hasStableIdentity &&
        isProvider(
          userId,
        ) &&
        status ==
            SwapRequestStatus.pending;
  }

  bool canDecline(
      String userId,
      ) {
    return hasStableIdentity &&
        isProvider(
          userId,
        ) &&
        status ==
            SwapRequestStatus.pending;
  }

  bool canRespond(
      String userId,
      ) {
    return canAccept(
      userId,
    ) ||
        canDecline(
          userId,
        );
  }

  bool canSchedule(
      String userId,
      ) {
    return hasStableIdentity &&
        involvesUser(
          userId,
        ) &&
        status ==
            SwapRequestStatus.accepted;
  }

  bool canComplete(
      String userId,
      ) {
    return hasStableIdentity &&
        involvesUser(
          userId,
        ) &&
        status ==
            SwapRequestStatus.scheduled;
  }

  bool canViewAsParticipant(
      String userId,
      ) {
    return involvesUser(
      userId,
    );
  }

  bool canModify(
      String userId,
      ) {
    return canCancel(
      userId,
    ) ||
        canAccept(
          userId,
        ) ||
        canDecline(
          userId,
        ) ||
        canSchedule(
          userId,
        ) ||
        canComplete(
          userId,
        );
  }

  bool get canRemainAsHistory {
    return status.isTerminal &&
        hasUsableHistoricalSnapshot &&
        hasStructurallyValidIdentityGroup;
  }

  bool get isActionableStableRequest {
    return status.isActive &&
        hasStableIdentity &&
        hasStructurallyValidIdentityGroup;
  }

  static bool _hasValue(
      String? value,
      ) {
    return value != null &&
        value.trim().isNotEmpty;
  }
}