import 'package:flutter/foundation.dart';

import '../model/auth_session.dart';
import '../model/repositories/explore_repository.dart';
import '../model/repositories/local_user_repository.dart';
import '../services/chat_service.dart';
import '../services/current_user_service.dart';
import '../services/my_skills_service.dart';
import '../services/profile_service.dart';
import '../services/review_service.dart';
import '../services/swap_service.dart';

class AuthenticatedSessionController {
  final LocalUserRepository _localUsers = LocalUserRepository();
  Future<void> _transition = Future<void>.value();
  String? _preparedUid;

  Future<void> prepare(AuthSession? session) {
    final Future<void> next = _transition.catchError((_) {}).then((_) async {
      final String? uid = session?.uid.trim();
      if (uid == _preparedUid &&
          (uid != null && CurrentUserService.instance.isCurrentUser(uid) ||
              uid == null &&
                  !CurrentUserService
                      .instance
                      .hasAuthenticatedBackendSession)) {
        return;
      }

      await _clearActiveSession();
      if (session == null) return;

      String stage = 'local profile provisioning';
      try {
        await _localUsers.provision(session);
        stage = 'current-user configuration';
        CurrentUserService.instance.configureAuthenticatedUid(session.uid);
        stage = 'cloud profile preparation';
        await ProfileService.instance.prepareCurrentSession();
        stage = 'cloud My Skills preparation';
        await MySkillsService.instance.prepareCurrentSession();
        stage = 'Explore data loading';
        await ExploreRepository.instance.refresh();
        stage = 'chat loading';
        await ChatService.instance.initialize();
        stage = 'swap loading';
        await SwapService.instance.initialize();
        _preparedUid = session.uid.trim();
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            'Session preparation failed during $stage: $error\n$stackTrace',
          );
        }
        await _clearActiveSession();
        rethrow;
      }
    });
    _transition = next;
    return next;
  }

  Future<void> _clearActiveSession() async {
    CurrentUserService.instance.clearSession();
    _preparedUid = null;
    await ReviewService.instance.resetSession();
    await ChatService.instance.resetSession();
    await SwapService.instance.resetSession();
    await ExploreRepository.instance.clearSessionCache();
  }
}
