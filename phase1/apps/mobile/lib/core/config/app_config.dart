import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  AppConfig({
    required this.apiBaseUrl,
    required this.featureFlags,
  });

  final String apiBaseUrl;
  final Map<String, bool> featureFlags;

  static Future<AppConfig> load() async {
    try {
      final raw = await rootBundle.loadString('assets/config/remote_config.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final flags = (json['featureFlags'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as bool),
      );
      return AppConfig(
        apiBaseUrl: json['apiBaseUrl'] as String,
        featureFlags: flags,
      );
    } catch (e) {
      // Fallback to cloud URL
      return AppConfig(
        apiBaseUrl: 'http://dev-alb-1851605074.eu-west-1.elb.amazonaws.com',
        featureFlags: {
          'ff.onboarding.v1': true,
          'ff.catalog.v1': false,
          'ff.leaderboard.v1': false,
          'ff.wallet.readonly': false,
        },
      );
    }
  }

  bool isFlagEnabled(String flag) => featureFlags[flag] ?? false;
}

final appConfigProvider = Provider<AppConfig>((ref) => throw UnimplementedError());
