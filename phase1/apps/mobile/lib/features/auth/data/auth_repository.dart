import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../profile/data/profile_repository.dart';
import '../model/auth_session.dart';

class AuthRepository {
  AuthRepository(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;

  static const _sessionKey = 'auth_session';

  Future<AuthenticatedSession?> restoreSession() async {
    final raw = _prefs.getString(_sessionKey);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return AuthenticatedSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      userId: json['userId'] as String,
      nickname: json['nickname'] as String,
    );
  }

  Future<AuthenticatedSession> login({
    required String provider,
    required String idToken,
    required String deviceId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/login',
      data: {
        'provider': provider,
        'id_token': idToken,
        'device_id': deviceId,
      },
    );

    final data = response.data ?? {};
    final session = AuthenticatedSession(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      userId: (data['user'] as Map<String, dynamic>)['id'] as String,
      nickname: (data['user'] as Map<String, dynamic>)['nickname'] as String? ?? '',
    );
    await _persistSession(session);
    return session;
  }

  Future<void> clearSession() async {
    await _prefs.remove(_sessionKey);
  }

  Future<void> _persistSession(AuthenticatedSession session) async {
    await _prefs.setString(
      _sessionKey,
      jsonEncode({
        'accessToken': session.accessToken,
        'refreshToken': session.refreshToken,
        'userId': session.userId,
        'nickname': session.nickname,
      }),
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.read(appConfigProvider);
  final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthRepository(dio, prefs);
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider deve essere override-ato nel main');
});
