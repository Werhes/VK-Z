import 'dart:math';

class VkConfig {
  // VK App ID от VK Android App (как в Music-M)
  static const int appId = 2274003;

  // VK App Secret (как в Music-M AndroidApiAuthParams)
  static const String clientSecret = 'hHbZxrka2uZ6jB1inYsH';

  // VK API version — используем v8.200 (актуальная версия VK Android App)
  static const String apiVersion = '8.200';

  // VK OAuth URL (используем vk.ru, т.к. vk.com заблокирован)
  static const String authUrl = 'https://oauth.vk.ru/authorize';

  // VK API base URL
  static const String apiBaseUrl = 'https://api.vk.ru/method';
  static const String apiFallbackBaseUrl = 'https://api.vk.com/method';

  // OAuth API base URL
  static const String oauthBaseUrl = 'https://api.vk.ru/oauth';
  static const String oauthFallbackBaseUrl = 'https://api.vk.com/oauth';

  // OAuth redirect URL
  static const String redirectUri = 'https://oauth.vk.ru/blank.html';

  // User-Agent как в VK Android App (актуальная версия)
  static const String userAgent =
      'VKAndroidApp/8.200-99999 (Android 14; SDK 34; arm64-v8a; Pixel 8 Pro; ru; 2992x1440)';

  // Заголовки как в Music-M (RestClientWithUserAgent)
  static Map<String, String> get headers => {
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
        'Accept-Language': 'ru',
        'Content-Type': 'application/x-www-form-urlencoded',
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

  /// Генерирует device_id как в Music-M (рандомный UUID)
  static String generateDeviceId() {
    final random = Random();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    // Форматируем как UUID: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}