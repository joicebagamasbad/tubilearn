class CurrentUserService {
  CurrentUserService._();

  static final CurrentUserService instance =
  CurrentUserService._();

  static const String _currentUserId =
      'user_joice_local';

  String get userId => _currentUserId;
}