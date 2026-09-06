class Review {
  final String id;

  final String swapRequestId;

  final String reviewerUserId;
  final String revieweeUserId;

  final int rating;

  final String? comment;

  final DateTime createdAt;

  const Review({
    required this.id,
    required this.swapRequestId,
    required this.reviewerUserId,
    required this.revieweeUserId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  bool get hasValidRating {
    return rating >= 1 &&
        rating <= 5;
  }

  bool get hasValidParticipants {
    return reviewerUserId
        .trim()
        .isNotEmpty &&
        revieweeUserId
            .trim()
            .isNotEmpty &&
        reviewerUserId !=
            revieweeUserId;
  }

  bool get hasValidIdentity {
    return id.trim().isNotEmpty &&
        swapRequestId
            .trim()
            .isNotEmpty &&
        hasValidParticipants;
  }

  bool isWrittenBy(
      String userId,
      ) {
    final String cleanUserId =
    userId.trim();

    return cleanUserId.isNotEmpty &&
        reviewerUserId ==
            cleanUserId;
  }

  bool isAbout(
      String userId,
      ) {
    final String cleanUserId =
    userId.trim();

    return cleanUserId.isNotEmpty &&
        revieweeUserId ==
            cleanUserId;
  }
}