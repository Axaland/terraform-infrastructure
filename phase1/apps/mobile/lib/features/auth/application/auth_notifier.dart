import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/profile_repository.dart';
import '../data/auth_repository.dart';
import '../model/auth_session.dart';

final authSessionProvider = AsyncNotifierProvider<AuthNotifier, AuthSession>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthSession> {
  late final AuthRepository _authRepository;
  late final ProfileRepository _profileRepository;

  @override
  FutureOr<AuthSession> build() async {
    _authRepository = ref.read(authRepositoryProvider);
    _profileRepository = ref.read(profileRepositoryProvider);
    final session = await _authRepository.restoreSession();
    if (session == null) {
      return const AuthSession.anonymous();
    }
    final profile = await _profileRepository.fetchProfile(session.accessToken);
    return AuthSession.authenticated(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      userId: profile.id,
      nickname: profile.nickname,
    );
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
      return AuthSession.authenticated(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        userId: profile.id,
        nickname: profile.nickname,
      );
    });
  }

  Future<void> logout() async {
    await _authRepository.clearSession();
    state = const AsyncData(AuthSession.anonymous());
  }
}
