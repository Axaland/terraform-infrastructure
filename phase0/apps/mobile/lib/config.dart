class AppConfig {
  const AppConfig._();

  static const String bffBaseUrl = String.fromEnvironment(
    'BFF_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
