class AppConfig {
  AppConfig._();

  // These values are public client configuration. Supabase security must be
  // enforced with RLS; never place a service-role key in the mobile app.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hiphoykwtkjlcsuduqvf.supabase.co',
  );

  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_qn4K7XxgsMsuvRmzXWjz4Q_ta0A0y0R',
  );

  static bool get isValid =>
      supabaseUrl.startsWith('https://') && supabasePublishableKey.isNotEmpty;
}
