sealed class AuthSession {
  const AuthSession();

  bool get isAuthenticated => this is AuthenticatedSession;

  const factory AuthSession.anonymous() = AnonymousSession;

  const factory AuthSession.authenticated({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String nickname,
  }) = AuthenticatedSession;
}

class AnonymousSession extends AuthSession {
  const AnonymousSession() : super();
}

class AuthenticatedSession extends AuthSession {
  const AuthenticatedSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.nickname,
  }) : super();

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String nickname;
}
