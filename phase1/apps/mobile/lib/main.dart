import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'core/telemetry/telemetry.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_notifier.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/onboarding/presentation/onboarding_page.dart';
import 'features/profile/presentation/profile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final telemetry = TelemetryClient();
  final config = await AppConfig.load();
  final packageInfo = await PackageInfo.fromPlatform();
  final prefs = await SharedPreferences.getInstance();

  FlutterError.onError = (details) {
    telemetry.recordError(details.exception, stack: details.stack);
  };

  telemetry.recordEvent('app_launch', {
    'version': packageInfo.version,
  });

  runApp(
    ProviderScope(
      overrides: [
        telemetryProvider.overrideWithValue(telemetry),
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const _ShellApp(),
    ),
  );
}

class _ShellApp extends ConsumerWidget {
  const _ShellApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthGate(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
      redirect: (context, state) {
        final session = ref.read(authSessionProvider);
        if (session.isLoading) {
          return null;
        }
        if (session.hasError) {
          return state.matchedLocation == '/auth' ? null : '/auth';
        }
        final value = session.value;
        final isAuthenticated = value != null && value.isAuthenticated;
        final location = state.matchedLocation;

        if (!isAuthenticated) {
          if (location == '/auth' || location == '/onboarding') {
            return null;
          }
          return '/onboarding';
        }

        if (location == '/auth' || location == '/onboarding') {
          return '/profile';
        }

        return null;
      },
    );

    return MaterialApp.router(
      title: 'XXX App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      locale: const Locale('en'),
      supportedLocales: const [
        Locale('en'),
        Locale('it'),
      ],
    );
  }
}
