import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'log_service.dart';
import 'vk_config.dart';

/// Результат валидации аккаунта (auth.validateAccount)
class ValidateAccountResult {
  final bool isPhone;
  final bool isEmail;
  final String flowName; // need_password_and_validation, need_validation, need_passkey_otp
  final List<String> flowNames; // password, passkey, otp
  final String sid;
  final String? verificationMethod; // password, sms, push, callreset, email, passkey
  final bool hasAnotherVerificationMethods;
  final String? externalId;

  ValidateAccountResult({
    required this.isPhone,
    required this.isEmail,
    required this.flowName,
    required this.flowNames,
    required this.sid,
    this.verificationMethod,
    this.hasAnotherVerificationMethods = false,
    this.externalId,
  });

  bool get needsPassword => flowName == 'need_password_and_validation';
  bool get needsValidation => flowName == 'need_validation';
  bool get needsPasskey => flowName == 'need_passkey_otp';
  bool get hasPasswordFlow => flowNames.contains('password');
}

/// Результат OAuth токена
class AuthTokenResult {
  final String accessToken;
  final int userId;
  final int expiresIn;
  final String? refreshToken;

  AuthTokenResult({
    required this.accessToken,
    required this.userId,
    required this.expiresIn,
    this.refreshToken,
  });
}

/// Сервис авторизации через номер телефона (как в Music-M).
///
/// Использует VK OAuth endpoint (https://api.vk.ru/oauth/token)
/// с grant_type=password и параметрами как в VK Android App.
class VkAuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  HttpClient? _httpClient;

  static const String _tokenKey = 'vk_access_token';
  static const String _userIdKey = 'vk_user_id';
  static const String _deviceIdKey = 'vk_device_id';
  static const String _anonTokenKey = 'vk_anon_token';

  VkAuthService() {
    _httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 10);
  }

  String? _deviceId;
  String? _accessToken;
  int? _userId;
  String? _anonymousToken;

  String get deviceId => _deviceId ??= VkConfig.generateDeviceId();
  String? get accessToken => _accessToken;
  int? get userId => _userId;

  /// Получает анонимный токен через OAuth endpoint (как в Music-M VkAndroidAuthorizationBase.AuthAnonymousAsync).
  /// Этот токен нужен для вызова auth.validateAccount без access_token.
  Future<String> getAnonymousToken() async {
    // Пробуем восстановить сохранённый
    if (_anonymousToken != null) return _anonymousToken!;
    final saved = await _secureStorage.read(key: _anonTokenKey);
    if (saved != null && saved.isNotEmpty) {
      _anonymousToken = saved;
      return saved;
    }

    final params = <String, String>{
      'client_id': VkConfig.appId.toString(),
      'api_id': VkConfig.appId.toString(),
      'client_secret': VkConfig.clientSecret,
      'device_id': deviceId,
      'https': 'true',
      'lang': 'ru',
      'v': VkConfig.apiVersion,
    };

    final body = Uri(queryParameters: params).query;
    final primaryUrl = '${VkConfig.oauthBaseUrl}/get_anonym_token';
    final fallbackUrl = '${VkConfig.oauthFallbackBaseUrl}/get_anonym_token';

    LogService.d('Getting anonymous token from $primaryUrl', tag: 'AUTH');

    Map<String, dynamic> data;
    try {
      data = await _postFormUrl(primaryUrl, body);
    } catch (e) {
      LogService.w('Anonymous token request failed on $primaryUrl: $e', tag: 'AUTH');
      if (fallbackUrl != primaryUrl) {
        LogService.d('Retrying anonymous token request on $fallbackUrl', tag: 'AUTH');
        data = await _postFormUrl(fallbackUrl, body);
      } else {
        rethrow;
      }
    }

    if (data.containsKey('error')) {
      final error = data['error'] as Map<String, dynamic>;
      final errorCode = error['error_code'];
      final errorMsg = error['error_msg'] ?? 'Unknown';
      throw Exception('VK Anon Token Error [$errorCode]: $errorMsg');
    }

    final anonToken = data['access_token'] as String?;
    if (anonToken == null || anonToken.isEmpty) {
      throw Exception('No anonymous token in response: ${jsonEncode(data)}');
    }

    _anonymousToken = anonToken;
    await _secureStorage.write(key: _anonTokenKey, value: anonToken);
    LogService.i('Got anonymous token: ${anonToken.substring(0, 10)}...', tag: 'AUTH');
    return anonToken;
  }

  /// Шаг 1: Валидация аккаунта по номеру телефона или email.
  /// Вызывает auth.validateAccount как в Music-M AuthCategory.
  /// Сначала получает анонимный токен и использует его как access_token.
  Future<ValidateAccountResult> validateAccount(String login) async {
    // Сначала получаем анонимный токен (как в Music-M)
    final anonToken = await getAnonymousToken();

    final params = <String, String>{
      'login': login,
      'force_password': 'false',
      'supported_ways': 'push,sms,callreset,reserve_code,codegen,email,passkey',
      'flow_type': 'auth_without_password',
      'api_id': VkConfig.appId.toString(),
      'passkey_supported': 'true',
      'access_token': anonToken, // Используем анонимный токен
    };

    final data = await _oauthPost('auth.validateAccount', params);

    final response = data['response'] as Map<String, dynamic>? ?? data;

    final isPhone = response['is_phone'] == true || response['is_phone'] == 1;
    final isEmail = response['is_email'] == true || response['is_email'] == 1;
    final flowName = response['flow_name'] as String? ?? '';
    final flowNamesRaw = response['flow_names'] as List<dynamic>? ?? [];
    final flowNames = flowNamesRaw.map((e) => e.toString()).toList();
    final sid = response['sid'] as String? ?? '';

    final nextStep = response['next_step'] as Map<String, dynamic>?;
    final verificationMethod = nextStep?['verification_method'] as String?;
    final hasAnother = nextStep?['has_another_verification_methods'] == true;
    final externalId = nextStep?['external_id'] as String?;

    LogService.i(
        'validateAccount: isPhone=$isPhone, flowName=$flowName, sid=$sid, nextStep=$verificationMethod',
        tag: 'AUTH');

    return ValidateAccountResult(
      isPhone: isPhone,
      isEmail: isEmail,
      flowName: flowName,
      flowNames: flowNames,
      sid: sid,
      verificationMethod: verificationMethod,
      hasAnotherVerificationMethods: hasAnother,
      externalId: externalId,
    );
  }

  /// Шаг 2: Авторизация с паролем (или без пароля).
  /// POST на https://api.vk.ru/oauth/token как в Music-M VkAndroidAuthorizationBase.
  Future<AuthTokenResult> authorizeWithPassword({
    required String login,
    required String sid,
    String? password,
    String? code,
    String? validateSession,
    String? validateToken,
    bool withoutPassword = false,
  }) async {
    final params = <String, String>{
      'grant_type': withoutPassword ? 'without_password' : 'password',
      'libverify_support': 'false',
      'sid': sid,
      'scope': 'all',
      'supported_ways': 'push,sms,callreset,reserve_code,codegen,email,passkey',
      'device_id': deviceId,
      'device_os': 'android',
      'api_id': VkConfig.appId.toString(),
      'client_id': VkConfig.appId.toString(),
      'client_secret': VkConfig.clientSecret,
      'https': 'true',
      'lang': 'ru',
      'v': VkConfig.apiVersion,
      'username': login,
      'flow_type': withoutPassword ? 'auth_without_password' : 'tg_flow',
      '2fa_supported': 'true',
      'vk_connect_auth': 'true',
    };

    if (password != null && password.isNotEmpty) {
      params['password'] = password;
    }

    if (code != null && code.isNotEmpty) {
      params['code'] = code;
    }

    if (validateSession != null && validateSession.isNotEmpty) {
      params['validate_session'] = validateSession;
    }

    if (validateToken != null && validateToken.isNotEmpty) {
      params['validate_token'] = validateToken;
    }

    final data = await _oauthPostToken(params);

    final accessToken = data['access_token'] as String?;
    final userId = data['user_id'] as int?;
    final expiresIn = data['expires_in'] as int? ?? 0;
    final refreshToken = data['refresh_token'] as String?;

    if (accessToken == null || accessToken.isEmpty) {
      // Проверяем на need_validation
      if (data['error'] != null) {
        final error = data['error'] as String?;
        final errorDesc = data['error_description'] as String?;
        if (error == 'need_validation') {
          throw VkAuthValidationException(
            validationType: data['validation_type'] as String? ?? 'sms',
            validationSid: data['validation_sid'] as String? ?? sid,
            phoneMask: data['phone_mask'] as String?,
            validationResend: data['validation_resend'] as String?,
            externalId: data['validation_external_id'] as String?,
          );
        }
        throw Exception('VK Auth Error [$error]: $errorDesc');
      }
      throw Exception('No access_token in response');
    }

    _accessToken = accessToken;
    _userId = userId ?? 0;

    // Сохраняем
    await _saveSession();

    LogService.i('Auth success: userId=$userId, token=${accessToken.substring(0, 10)}...', tag: 'AUTH');

    return AuthTokenResult(
      accessToken: accessToken,
      userId: userId ?? 0,
      expiresIn: expiresIn,
      refreshToken: refreshToken,
    );
  }

  /// Шаг 3: Подтверждение кода 2FA.
  /// Отправляет код подтверждения на OAuth endpoint.
  Future<AuthTokenResult> confirmCode({
    required String login,
    required String sid,
    required String code,
    String? password,
    String? validateSession,
    String? validateToken,
  }) async {
    return authorizeWithPassword(
      login: login,
      sid: sid,
      password: password,
      code: code,
      validateSession: validateSession,
      validateToken: validateToken,
    );
  }

  /// Восстановить сессию
  Future<bool> tryRestoreSession() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final userIdStr = await _secureStorage.read(key: _userIdKey);
      final savedDeviceId = await _secureStorage.read(key: _deviceIdKey);
      final savedAnonToken = await _secureStorage.read(key: _anonTokenKey);

      if (savedAnonToken != null && savedAnonToken.isNotEmpty) {
        _anonymousToken = savedAnonToken;
      }

      if (token != null && token.isNotEmpty) {
        _accessToken = token;
        _userId = userIdStr != null ? int.tryParse(userIdStr) : null;
        _deviceId = savedDeviceId ?? VkConfig.generateDeviceId();
        return true;
      }
    } catch (e) {
      LogService.w('Failed to restore auth session: $e', tag: 'AUTH');
    }
    return false;
  }

  Future<void> _saveSession() async {
    try {
      if (_accessToken != null) {
        await _secureStorage.write(key: _tokenKey, value: _accessToken!);
      }
      if (_userId != null) {
        await _secureStorage.write(key: _userIdKey, value: _userId.toString());
      }
      if (_deviceId != null) {
        await _secureStorage.write(key: _deviceIdKey, value: _deviceId!);
      }
    } catch (e) {
      LogService.w('Failed to save auth session: $e', tag: 'AUTH');
    }
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _userId = null;
    _anonymousToken = null;
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userIdKey);
      await _secureStorage.delete(key: _deviceIdKey);
      await _secureStorage.delete(key: _anonTokenKey);
    } catch (e) {
      LogService.w('Failed to clear auth session: $e', tag: 'AUTH');
    }
  }

  /// POST на VK API метод (auth.*) через api.vk.ru/method/
  Future<Map<String, dynamic>> _oauthPost(
      String method, Map<String, String> params,
      {String? baseUrl}) async {
    final apiUrl = baseUrl ?? VkConfig.apiBaseUrl;
    final url = '$apiUrl/$method';
    final body = Uri(queryParameters: params).query;

    final request = await _httpClient!.postUrl(Uri.parse(url));
    for (final entry in VkConfig.headers.entries) {
      request.headers.set(entry.key, entry.value);
    }
    request.headers.set('Content-Length', body.length.toString());
    request.write(body);

    try {
      final data = await _processResponse(request);
      return data;
    } catch (e) {
      if (baseUrl == null &&
          e is Exception &&
          e.toString().contains('Unknown method passed')) {
        final fallbackBaseUrl = VkConfig.apiFallbackBaseUrl;
        if (fallbackBaseUrl != apiUrl) {
          return await _oauthPost(method, params, baseUrl: fallbackBaseUrl);
        }
      }
      rethrow;
    }
  }

  /// POST на OAuth token endpoint (https://api.vk.ru/oauth/token)
  Future<Map<String, dynamic>> _oauthPostToken(
      Map<String, String> params,
      {String? baseUrl}) async {
    final apiUrl = baseUrl ?? VkConfig.oauthBaseUrl;
    final url = '$apiUrl/token';
    final body = Uri(queryParameters: params).query;

    final request = await _httpClient!.postUrl(Uri.parse(url));
    for (final entry in VkConfig.headers.entries) {
      request.headers.set(entry.key, entry.value);
    }
    request.headers.set('Content-Length', body.length.toString());
    request.write(body);

    try {
      final data = await _processResponse(request);
      return data;
    } catch (e) {
      if (baseUrl == null && e is Exception) {
        final fallbackBaseUrl = VkConfig.oauthFallbackBaseUrl;
        if (fallbackBaseUrl != apiUrl) {
          return await _oauthPostToken(params, baseUrl: fallbackBaseUrl);
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _postFormUrl(String url, String body) async {
    final request = await _httpClient!.postUrl(Uri.parse(url));
    for (final entry in VkConfig.headers.entries) {
      request.headers.set(entry.key, entry.value);
    }
    request.headers.set('Content-Length', body.length.toString());
    request.write(body);
    return await _processResponse(request);
  }

  Future<Map<String, dynamic>> _processResponse(HttpClientRequest request) async {
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: $responseBody');
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    return data;
  }
}

/// Исключение: требуется 2FA подтверждение
class VkAuthValidationException implements Exception {
  final String validationType; // sms, push, callreset, email, 2fa_app
  final String validationSid;
  final String? phoneMask;
  final String? validationResend;
  final String? externalId;

  VkAuthValidationException({
    required this.validationType,
    required this.validationSid,
    this.phoneMask,
    this.validationResend,
    this.externalId,
  });

  @override
  String toString() {
    return 'Требуется подтверждение ($validationType): $phoneMask';
  }
}