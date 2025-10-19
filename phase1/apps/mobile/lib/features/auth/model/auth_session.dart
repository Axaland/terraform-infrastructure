sealed class AuthSession {
  const AuthSession();

  bool get isAuthenticated => this is AuthenticatedSession;

  const factory AuthSession.anonymous() = AnonymousSession;

  const factory AuthSession.authenticated({
    required String accessToken,
    required DateTime accessTokenExpiresAt,
    required String refreshToken,
    required String userId,
    required String nickname,
    String? country,
    String? language,
    String status,
  }) = AuthenticatedSession;
}

class AnonymousSession extends AuthSession {
  const AnonymousSession() : super();
}

class AuthenticatedSession extends AuthSession {
  const AuthenticatedSession({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.userId,
    required this.nickname,
    this.country,
    this.language,
    this.status = 'active',
  }) : super();

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final String userId;
  final String nickname;
  final String? country;
  final String? language;
  final String status;

  AuthenticatedSession copyWith({
    String? accessToken,
    DateTime? accessTokenExpiresAt,
    String? refreshToken,
    String? userId,
    String? nickname,
    String? country,
    String? language,
    String? status,
  }) {
    return AuthenticatedSession(
      accessToken: accessToken ?? this.accessToken,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      country: country ?? this.country,
      language: language ?? this.language,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'accessTokenExpiresAt': accessTokenExpiresAt.toIso8601String(),
        'refreshToken': refreshToken,
        'userId': userId,
        'nickname': nickname,
        'country': country,
        'language': language,
        'status': status,
      };

  factory AuthenticatedSession.fromJson(Map<String, dynamic> json) => AuthenticatedSession(
        accessToken: json['accessToken'] as String,
        accessTokenExpiresAt: DateTime.parse(json['accessTokenExpiresAt'] as String),
        refreshToken: json['refreshToken'] as String,
        userId: json['userId'] as String,
        nickname: json['nickname'] as String? ?? '',
        country: json['country'] as String?,
        language: json['language'] as String?,
        status: json['status'] as String? ?? 'active',
      );
}
