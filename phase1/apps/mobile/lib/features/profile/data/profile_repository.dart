import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';

class Profile {
  Profile({
    required this.id,
    required this.nickname,
  });

  final String id;
  final String nickname;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        nickname: json['nickname'] as String? ?? '',
      );
}

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<Profile> fetchProfile(String accessToken) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/auth/me',
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
    return Profile.fromJson(response.data ?? {});
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final config = ref.read(appConfigProvider);
  final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));

  dio.interceptors.add(InterceptorsWrapper(
    onError: (error, handler) {
      // ignore: avoid_print
      print('API error: ${error.response?.data ?? error.message}');
      return handler.next(error);
    },
  ));

  return ProfileRepository(dio);
});
