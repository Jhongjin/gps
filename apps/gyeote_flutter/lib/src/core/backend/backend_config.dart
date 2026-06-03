class BackendConfig {
  const BackendConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.inviteBaseUrl,
  });

  factory BackendConfig.fromEnvironment() {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    const legacyAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const inviteBaseUrl = String.fromEnvironment('INVITE_BASE_URL', defaultValue: 'https://gyeote.app/invite');

    return BackendConfig(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabasePublishableKey.isNotEmpty ? supabasePublishableKey : legacyAnonKey,
      inviteBaseUrl: inviteBaseUrl,
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String inviteBaseUrl;

  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
