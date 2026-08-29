class Message {
  final String id;
  final String text;

  // Stable identity of the sender.
  //
  // Nullable only for legacy messages where the sender
  // cannot be identified safely.
  final String? senderUserId;

  final DateTime sentAt;

  Message({
    required this.id,
    required this.text,
    required this.senderUserId,
    required this.sentAt,
  });

  bool isSentBy(
      String userId,
      ) {
    final String cleanUserId =
    userId.trim();

    if (cleanUserId.isEmpty ||
        senderUserId == null) {
      return false;
    }

    return senderUserId == cleanUserId;
  }

  bool get hasStableSender =>
      senderUserId != null &&
          senderUserId!.trim().isNotEmpty;
}