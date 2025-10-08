import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class TelemetryClient {
  void recordEvent(String name, [Map<String, dynamic>? properties]) {
    log('[telemetry] $name', name: 'telemetry', error: properties);
  }

  void recordError(Object error, {StackTrace? stack}) {
    log('[error] $error', name: 'telemetry', stackTrace: stack);
  }
}

final telemetryProvider = Provider<TelemetryClient>((ref) => TelemetryClient());
