import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';

class LocalIdentityProvider {
  LocalIdentityProvider(this._config);

  final AppConfig _config;
  final Random _random = Random.secure();

  Future<String> issueIdToken({
    required String provider,
    required String deviceId,
  }) async {
    final now = DateTime.now().toUtc();
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final payload = <String, dynamic>{
      'iss': 'xxx-mobile-local',
      'aud': 'xxx-bff',
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': now.add(const Duration(minutes: 15)).millisecondsSinceEpoch ~/ 1000,
      'sub': _randomId(),
      'provider': provider,
      'device_id': deviceId,
      'email': '${provider}_user_${_randomInt()}@example.com',
      'nickname': _nicknameFor(provider),
      'country': locale.countryCode ?? 'IT',
      'lang': locale.languageCode,
    };
    return _sign(payload);
  }

  String _randomId() {
    final bytes = List<int>.generate(12, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  int _randomInt() => _random.nextInt(9000) + 1000;

  String _nicknameFor(String provider) {
    final adjectives = ['Swift', 'Brave', 'Nova', 'Solar', 'Lively'];
    final nouns = ['Explorer', 'Pilot', 'Voyager', 'Seeker', 'Guardian'];
    final adjective = adjectives[_random.nextInt(adjectives.length)];
    final noun = nouns[_random.nextInt(nouns.length)];
    return '$adjective $noun';
  }

  String _sign(Map<String, dynamic> payload) {
    final header = {'alg': 'HS256', 'typ': 'JWT'};
    String encode(Map<String, dynamic> value) {
      final encoded = base64UrlEncode(utf8.encode(jsonEncode(value)));
      return encoded.replaceAll('=', '');
    }

    final headerEncoded = encode(header);
    final payloadEncoded = encode(payload);
    final data = '$headerEncoded.$payloadEncoded';
    final hmac = Hmac(sha256, utf8.encode(_config.oidcSharedSecret));
    final signatureBytes = hmac.convert(utf8.encode(data)).bytes;
    final signature = base64UrlEncode(signatureBytes).replaceAll('=', '');
    return '$data.$signature';
  }
}

final localIdentityProvider = Provider<LocalIdentityProvider>((ref) {
  final config = ref.watch(appConfigProvider);
  return LocalIdentityProvider(config);
});
