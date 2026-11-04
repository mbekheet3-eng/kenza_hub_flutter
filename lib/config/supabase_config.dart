/// Public client configuration for the Kenza Hub V2 Supabase project.
///
/// The URL and publishable key are designed for use in client applications.
/// Never place a service_role key or Supabase secret key in this file.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://klkcroynomxuajggqqqx.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_tKDfwczxGzGn44JNVLqI6Q_WewP1YYy',
  );
}
