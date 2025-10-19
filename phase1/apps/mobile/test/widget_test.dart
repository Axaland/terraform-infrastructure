import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xxx_mobile/core/config/app_config.dart';
import 'package:xxx_mobile/features/auth/application/auth_notifier.dart';
import 'package:xxx_mobile/features/auth/model/auth_session.dart';
import 'package:xxx_mobile/features/auth/presentation/auth_gate.dart';
import 'package:xxx_mobile/features/onboarding/presentation/onboarding_page.dart';

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._session);

  final AuthSession _session;

  @override
  Future<AuthSession> build() async => _session;

  @override
  Future<void> login({
    required String provider,
    required String idToken,
    required String deviceId,
  }) async {}

  @override
  Future<void> logout() async {}
}

void main() {
  final stubConfig = AppConfig(
    apiBaseUrl: 'http://localhost:3000',
    featureFlags: const {
      'ff.onboarding.v1': true,
      'ff.catalog.v1': false,
    },
    oidcSharedSecret: 'test-secret',
  );

  testWidgets('Onboarding mostra il primo messaggio', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(() => _StubAuthNotifier(const AuthSession.anonymous())),
        ],
        child: const MaterialApp(home: OnboardingPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Benvenuto in XXX'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('AuthGate mostra i pulsanti di login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(() => _StubAuthNotifier(const AuthSession.anonymous())),
          appConfigProvider.overrideWithValue(stubConfig),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Accedi al tuo profilo'), findsOneWidget);
    expect(find.text('Continua con Google'), findsOneWidget);
    expect(find.text('Continua con Apple'), findsOneWidget);
  });
}
