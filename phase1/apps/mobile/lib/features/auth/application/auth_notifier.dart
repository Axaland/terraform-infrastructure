import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/profile_repository.dart';
import '../data/auth_repository.dart';
import '../model/auth_session.dart';
import '../../../core/telemetry/telemetry.dart';

final authSessionProvider = AsyncNotifierProvider<AuthNotifier, AuthSession>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthSession> {
  late final AuthRepository _authRepository;
  late final ProfileRepository _profileRepository;
  late final TelemetryClient _telemetry;

  @override
  FutureOr<AuthSession> build() async {
    _authRepository = ref.read(authRepositoryProvider);
    _profileRepository = ref.read(profileRepositoryProvider);
    _telemetry = ref.read(telemetryProvider);

    final restored = await _authRepository.restoreSession();
    if (restored == null) {
      return const AuthSession.anonymous();
    }

    AuthenticatedSession active = restored;
    final now = DateTime.now();
    if (active.accessTokenExpiresAt.isBefore(now.add(const Duration(seconds: 30)))) {
      try {
        active = await _authRepository.refresh(active);
        _telemetry.recordEvent('auth_token_refreshed');
      } catch (error, stackTrace) {
        _telemetry.recordError(error, stack: stackTrace);
        await _authRepository.clearSession();
        return const AuthSession.anonymous();
      }
    }

    final profile = await _profileRepository.fetchProfile(active.accessToken);
    final enriched = active.copyWith(
      userId: profile.id,
      nickname: profile.nickname,
      country: profile.country,
      language: profile.language,
      status: profile.status,
    );
    await _authRepository.saveSession(enriched);
    return enriched;
  }

  Future<void> login({
    required String provider,
    required String idToken,
    required String deviceId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await _authRepository.login(
        provider: provider,
        idToken: idToken,
        deviceId: deviceId,
      );
      final profile = await _profileRepository.fetchProfile(session.accessToken);
      final enriched = session.copyWith(
        userId: profile.id,
        nickname: profile.nickname,
        country: profile.country,
        language: profile.language,
        status: profile.status,
      );
      await _authRepository.saveSession(enriched);
      _telemetry.recordEvent('auth_login_success', {
        'provider': provider,
        'userId': enriched.userId,
      });
      return enriched;
    });
  }

  Future<void> logout() async {
    await _authRepository.clearSession();
    _telemetry.recordEvent('auth_logout');
    state = const AsyncData(AuthSession.anonymous());
  }
}
