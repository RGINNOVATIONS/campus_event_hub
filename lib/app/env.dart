import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place all environment-derived config is read from.
/// Never hard-code a secret here — everything comes from `.env`
/// (see `.env.example`), which is git-ignored.
class Env {
  Env._();

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env is optional in demo mode; fall back to APP_DEMO_MODE=true.
    }
  }

  static String get supabaseUrl => dotenv.maybeGet('SUPABASE_URL') ?? '';
  static String get supabaseAnonKey =>
      dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

  static String get firebaseApiKey => dotenv.maybeGet('FIREBASE_API_KEY') ?? '';
  static String get firebaseAppId => dotenv.maybeGet('FIREBASE_APP_ID') ?? '';
  static String get firebaseSenderId =>
      dotenv.maybeGet('FIREBASE_MESSAGING_SENDER_ID') ?? '';
  static String get firebaseProjectId =>
      dotenv.maybeGet('FIREBASE_PROJECT_ID') ?? '';
  static String get firebaseWebVapidKey =>
      dotenv.maybeGet('FIREBASE_WEB_VAPID_KEY') ?? '';

  /// Demo mode is on by default whenever real Supabase credentials are
  /// absent, and can also be forced via APP_DEMO_MODE regardless of
  /// whether credentials are present (useful for screenshots/testing).
  static bool get isDemoMode {
    final flag = dotenv.maybeGet('APP_DEMO_MODE');
    if (flag != null) return flag.toLowerCase() == 'true';
    return supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;
  }
}
