class BackendConfig {
  const BackendConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.inviteBaseUrl,
    this.privacyPolicyUrl = defaultPrivacyPolicyUrl,
  });

  /// 스토어 등록 양식과 앱 안의 링크가 같은 주소여야 한다. 실제로 열리는 페이지가
  /// 있어야 하고, 그 내용은 docs/privacy-policy.md 다.
  static const String defaultPrivacyPolicyUrl = 'https://gyeote.app/privacy';

  factory BackendConfig.fromEnvironment() {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    const legacyAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const inviteBaseUrl = String.fromEnvironment('INVITE_BASE_URL', defaultValue: 'https://gyeote.app/invite');
    const privacyPolicyUrl =
        String.fromEnvironment('PRIVACY_POLICY_URL', defaultValue: defaultPrivacyPolicyUrl);

    return BackendConfig(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabasePublishableKey.isNotEmpty ? supabasePublishableKey : legacyAnonKey,
      inviteBaseUrl: inviteBaseUrl,
      privacyPolicyUrl: privacyPolicyUrl,
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String inviteBaseUrl;
  final String privacyPolicyUrl;

  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
