class VkConfig {
  // VK App ID от Kate Mobile (рабочий, не заблокирован)
  static const int appId = 2685278;

  // VK API version — используем v5.131 как в Python-скрипте
  static const String apiVersion = '5.131';

  // VK OAuth URL (используем vk.ru, т.к. vk.com заблокирован)
  static const String authUrl = 'https://oauth.vk.ru/authorize';

  // VK API base URL
  static const String apiBaseUrl = 'https://api.vk.ru/method';

  // OAuth redirect URL
  static const String redirectUri = 'https://oauth.vk.ru/blank.html';

  // User-Agent как в Kate Mobile (рабочий, как в Python-скрипте)
  static const String userAgent =
      'KateMobileAndroid/56 lite-460 (Android 4.4.2; SDK 19; x86; unknown Android SDK built for x86; en)';

  // Required permissions for music access
  static const String scope = 'audio,offline';

  // Build OAuth URL for WebView
  static String get oAuthUrl {
    return '$authUrl'
        '?client_id=$appId'
        '&display=mobile'
        '&redirect_uri=$redirectUri'
        '&scope=$scope'
        '&response_type=token'
        '&v=$apiVersion'
        '&revoke=1';
  }

  // Extract access token from redirect URL
  static String? extractToken(String url) {
    final uri = Uri.parse(url);
    // Try fragment first (hash-based tokens)
    if (uri.fragment.isNotEmpty) {
      final params = Uri.splitQueryString(uri.fragment);
      final token = params['access_token'];
      if (token != null && token.isNotEmpty) return token;
    }
    // Try query parameters
    final token = uri.queryParameters['access_token'];
    if (token != null && token.isNotEmpty) return token;
    return null;
  }

  // Extract user ID from redirect URL
  static int? extractUserId(String url) {
    final uri = Uri.parse(url);
    if (uri.fragment.isNotEmpty) {
      final params = Uri.splitQueryString(uri.fragment);
      final userId = params['user_id'];
      if (userId != null) return int.tryParse(userId);
    }
    final userId = uri.queryParameters['user_id'];
    if (userId != null) return int.tryParse(userId);
    return null;
  }
}