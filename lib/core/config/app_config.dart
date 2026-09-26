class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// RevenueCat Google Play public API key.
  static const revenueCatGoogleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_API_KEY',
    defaultValue: '',
  );

  static const openRouterApiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '',
  );

  static const openRouterImageModel = String.fromEnvironment(
    'OPENROUTER_IMAGE_MODEL',
    defaultValue: 'google/gemini-2.5-flash-image',
  );

  static const storePremiumEntitlement = 'store_premium';
  static const buyerPremiumEntitlement = 'buyer_premium';

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasRevenueCat => revenueCatGoogleApiKey.isNotEmpty;

  static bool get hasOpenRouter => openRouterApiKey.isNotEmpty;
}
