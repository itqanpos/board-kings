import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const _urlOverride = String.fromEnvironment('SUPABASE_URL');
  static const _publishableKeyOverride =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const _legacyAnonKeyOverride =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static const url = _urlOverride.isNotEmpty
      ? _urlOverride
      : 'https://jqxravimzpjqwerothph.supabase.co';
  static const publishableKey = _publishableKeyOverride.isNotEmpty
      ? _publishableKeyOverride
      : _legacyAnonKeyOverride.isNotEmpty
          ? _legacyAnonKeyOverride
          : 'sb_publishable_vUhCzBJGtXzvBd4Xqiopvg_8gJvknrJ';
  static bool _initialized = false;

  static bool get isConfigured =>
      url.startsWith('https://') && publishableKey.isNotEmpty;
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (!isConfigured) return;
    try {
      await Supabase.initialize(url: url, publishableKey: publishableKey);
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }
}
