class VkConfig {
  // VK App ID от VK Kate API (рабочий, не заблокирован)
  static const int appId = 2685278;

  // VK API version - используем 8.x как в VK Android App (5.x блокирует audio.* методы)
  static const String apiVersion = '8.154';

  // VK OAuth URL (используем vk.ru, т.к. vk.com заблокирован)
  static const String authUrl = 'https://oauth.vk.ru/authorize';

  // VK API base URL (используем vk.ru, т.к. vk.com заблокирован)
  static const String apiBaseUrl = 'https://api.vk.ru/method';

  // OAuth redirect URL
  static const String redirectUri = 'https://oauth.vk.ru/blank.html';

  // User-Agent как в VK Android App (необходим для обхода блокировок audio.* методов)
  static const String userAgent = 'VKAndroidApp/8.154-99999 (Android 12; SDK 32; arm64-v8a; Pixel 6; ru; 2960x1440)';

  // Дополнительные заголовки как в VK Android App
  static const Map<String, String> extraHeaders = {
    'User-Agent': 'VKAndroidApp/8.154-99999 (Android 12; SDK 32; arm64-v8a; Pixel 6; ru; 2960x1440)',
    'Referer': 'https://id.vk.ru/',
    'Origin': 'https://id.vk.ru',
  };

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