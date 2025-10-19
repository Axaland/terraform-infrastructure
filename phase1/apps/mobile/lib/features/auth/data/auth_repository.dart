import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
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
    if (!json.containsKey('accessTokenExpiresAt')) {
      await _prefs.remove(_sessionKey);
      return null;
    }
    return AuthenticatedSession.fromJson(json);
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
    final user = data['user'] as Map<String, dynamic>? ?? {};
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 0;
    final session = AuthenticatedSession(
      accessToken: data['access_token'] as String,
      accessTokenExpiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      refreshToken: data['refresh_token'] as String,
      userId: user['id'] as String? ?? '',
      nickname: user['nickname'] as String? ?? '',
      country: user['country'] as String?,
      language: user['lang'] as String?,
      status: user['status'] as String? ?? 'active',
    );
    await _persistSession(session);
    return session;
  }

  Future<AuthenticatedSession> refresh(AuthenticatedSession current) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/refresh',
      data: {
        'refresh_token': current.refreshToken,
      },
    );
    final data = response.data ?? {};
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 0;
    final updated = current.copyWith(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      accessTokenExpiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
    await _persistSession(updated);
    return updated;
  }

  Future<void> clearSession() async {
    await _prefs.remove(_sessionKey);
  }

  Future<void> saveSession(AuthenticatedSession session) async {
    await _persistSession(session);
  }

  Future<void> _persistSession(AuthenticatedSession session) async {
    await _prefs.setString(
      _sessionKey,
      jsonEncode(session.toJson()),
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
