import 'dart:math';

class VkConfig {
  // VK App ID от Kate Mobile — имеет доступ к audio API
  static const int appId = 2685278;

  // VK API version — используем 5.131 как в Python-скрипте
  // На этой версии audio.* методы работают с Kate Mobile токеном
  static const String apiVersion = '5.131';

  // VK OAuth URL
  static const String authUrl = 'https://oauth.vk.ru/authorize';

  // VK API base URL
  static const String apiBaseUrl = 'https://api.vk.ru/method';

  // OAuth redirect URL
  static const String redirectUri = 'https://oauth.vk.ru/blank.html';

  // User-Agent как в Kate Mobile (Python-скрипт)
  static const String userAgent =
      'KateMobileAndroid/56 lite-460 (Android 4.4.2; SDK 19; x86; unknown Android SDK built for x86; en)';

  // Kate Mobile не требует дополнительных заголовков
  static const Map<String, String> extraHeaders = {
    'User-Agent': userAgent,
    'Accept-Language': 'ru',
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