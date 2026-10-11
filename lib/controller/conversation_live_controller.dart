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

  static final Set<ConversationLiveController> _active =
      <ConversationLiveController>{};

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
        unawaited(
          _subscription?.cancel().catchError((_) {}),
        );
        _subscription = null;
        _active.remove(this);
      },
      onDone: () {
        unawaited(
          _subscription?.cancel().catchError((_) {}),
        );
        _subscription = null;
        _active.remove(this);
      },
      cancelOnError: false,
    );

    _active.add(this);
  }

  // ============================================================
  // STOP
  // ============================================================

  Future<void> stop() async {
    _active.remove(this);

    final StreamSubscription<int>? subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  // ============================================================
  // STOP ALL
  // ============================================================

  /// Stops every currently-active live conversation listener. Called
  /// before FirebaseAuth sign-out so no open listener observes the
  /// about-to-be-invalidated auth token and raises a permission error.
  static Future<void> stopAll() async {
    final List<ConversationLiveController> controllers =
        _active.toList(growable: false);

    _active.clear();

    await Future.wait<void>(
      controllers.map(
        (ConversationLiveController controller) async {
          try {
            await controller.stop();
          } catch (_) {
            // One controller's failure to stop cleanly must not prevent
            // the others from being stopped.
          }
        },
      ),
    );
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
