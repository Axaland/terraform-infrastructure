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
    final raw = await rootBundle.loadString('assets/config/remote_config.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final flags = (json['featureFlags'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as bool),
    );
    return AppConfig(
      apiBaseUrl: json['apiBaseUrl'] as String,
      featureFlags: flags,
    );
  }

  bool isFlagEnabled(String flag) => featureFlags[flag] ?? false;
}

final appConfigProvider = Provider<AppConfig>((ref) => throw UnimplementedError());
