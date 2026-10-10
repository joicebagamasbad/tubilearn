import 'dart:async';

import '../services/chat_service.dart';

/// Owns the realtime subscription for ONE open conversation screen.
/// Mirrors VideoCallController's `_disposed`-guard dispose pattern: not
/// a ChangeNotifier, since the View drives its own `setState` from the
/// [start] callback rather than listening for change notifications.
class ConversationLiveController {
  ConversationLiveController({ChatService? chatService})
    : _chatService = chatService ?? ChatService.instance;

  final ChatService _chatService;

  StreamSubscription<int>? _subscription;

  bool _disposed = false;

  // ============================================================
  // START
  // ============================================================

  void start({
    required String conversationId,
    required void Function() onUpdated,
  }) {
    if (_disposed) {
      return;
    }

    unawaited(_subscription?.cancel());

    _subscription = _chatService.watchConversation(conversationId).listen(
      (int _) {
        if (_disposed) {
          return;
        }

        onUpdated();
      },
      onError: (Object _) {
        // Swallowed: manual pull-to-refresh remains available in the
        // conversation screen even if the live listener fails.
        _subscription = null;
      },
      onDone: () {
        _subscription = null;
      },
      cancelOnError: false,
    );
  }

  // ============================================================
  // STOP
  // ============================================================

  Future<void> stop() async {
    final StreamSubscription<int>? subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    unawaited(stop());
  }
}
