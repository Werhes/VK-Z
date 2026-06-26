import 'dart:math';

class VkConfig {
  // VK App ID от VK Kate API (рабочий, не заблокирован)
  static const int appId = 2685278;

  // VK API version - используем 8.x как в VK Android App
  static const String apiVersion = '8.154';

  // VK OAuth URL (используем vk.ru, т.к. vk.com заблокирован)
  static const String authUrl = 'https://oauth.vk.ru/authorize';

  // VK API base URL (используем vk.ru)
  static const String apiBaseUrl = 'https://api.vk.ru/method';

  // OAuth redirect URL
  static const String redirectUri = 'https://oauth.vk.ru/blank.html';

  // User-Agent как в VK Android App
  static const String userAgent =
      'VKAndroidApp/8.154-99999 (Android 12; SDK 32; arm64-v8a; Pixel 6; ru; 2960x1440)';

  // Дополнительные заголовки как в VK Android App (из Music-M / VkNet.AudioBypassService)
  static const Map<String, String> extraHeaders = {
    'User-Agent': userAgent,
    'X-VK-Android-Client': 'new',
    'Referer': 'https://id.vk.ru/',
    'Origin': 'https://id.vk.ru',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Site': 'same-site',
    'Sec-Ch-Ua-Platform': '"Android"',
    'Sec-Ch-Ua-Mobile': '?1',
    'Sec-Ch-Ua':
        '"Google Chrome";v="117", "Not;A=Brand";v="8", "Chromium";v="117"',
    'X-Quic': '1',
  };

  // Required permissions for music access
  static const String scope = 'audio,offline';

  // Generate a random device ID (16 hex bytes = 32 chars)
  static String generateDeviceId() {
    final random = Random();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

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