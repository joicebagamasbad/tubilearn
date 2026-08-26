enum SwapRequestStatus {
  pending,
  accepted,
  declined,
  scheduled,
  completed,
  cancelled,
}

extension SwapRequestStatusExtension on SwapRequestStatus {
  String get databaseValue {
    return name;
  }

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

  static SwapRequestStatus fromDatabase(
      String value,
      ) {
    return SwapRequestStatus.values.firstWhere(
          (status) => status.name == value,
      orElse: () => SwapRequestStatus.pending,
    );
  }
}

class SwapRequest {
  final String id;

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
}