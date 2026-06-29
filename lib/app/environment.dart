enum AppEnvironment { development, staging, production, demo }

// Controls which backend implementation is active.
// V1 uses Firebase. V2 will flip useApiBackend = true and replace
// service_locator.dart registrations to point at ApiRepository implementations.
class Environment {
  Environment._();

  static AppEnvironment _current = AppEnvironment.demo;

  static AppEnvironment get current => _current;

  static bool get isDemo => _current == AppEnvironment.demo;
  static bool get isProduction => _current == AppEnvironment.production;
  static bool get isDevelopment => _current == AppEnvironment.development;

  static void configure(AppEnvironment env) => _current = env;

  // Toggle to switch between Firebase (V1) and REST API (V2 souverain)
  static bool get useFirebase => true;
  static bool get useApiBackend => false;

  // Region identifiers
  static const region = 'guadeloupe';
  static const platformName = 'SafePoint Souverain Guadeloupe';
}
