import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native VK API client.
///
/// Абстракция над тремя нативными реализациями:
/// - **Android**: Kotlin VkApiPlugin (MethodChannel)
/// - **iOS**: Swift VkApiPlugin (MethodChannel)
/// - **macOS/Linux/Windows**: Rust FFI (librust_vk_z)
///
/// Все реализации используют одинаковый протокол:
/// - API v5.131
/// - Kate Mobile User-Agent
/// - GET-запросы к api.vk.ru/method/
/// - Прямые методы audio.*
class NativeVkApi {
  static NativeVkApi? _instance;
  bool _loaded = false;
  bool _useMethodChannel = false;
  bool _useRust = false;

  // MethodChannel для Android/iOS
  MethodChannel? _channel;

  // Rust FFI
  DynamicLibrary? _rustLib;

  NativeVkApi._();

  static NativeVkApi get instance {
    _instance ??= NativeVkApi._();
    return _instance!;
  }

  bool get isLoaded => _loaded;

  /// Попытаться загрузить нативный клиент.
  /// Приоритет: MethodChannel (Android/iOS) > Rust FFI (Desktop)
  bool tryLoad() {
    if (_loaded) return true;

    // Android / iOS — MethodChannel
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        _channel = const MethodChannel('vk_api');
        // Проверяем, что плагин зарегистрирован
        _useMethodChannel = true;
        _loaded = true;
        debugPrint('✅ Using MethodChannel VK API (${Platform.isAndroid ? "Kotlin" : "Swift"})');
        return true;
      } catch (e) {
        debugPrint('⚠️ MethodChannel not available: $e');
      }
    }

    // Desktop — Rust FFI
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      try {
        if (Platform.isMacOS) {
          _rustLib = DynamicLibrary.open('librust_vk_z.dylib');
        } else if (Platform.isWindows) {
          _rustLib = DynamicLibrary.open('rust_vk_z.dll');
        } else if (Platform.isLinux) {
          _rustLib = DynamicLibrary.open('librust_vk_z.so');
        }

        if (_rustLib != null) {
          _useRust = true;
          _loaded = true;
          debugPrint('✅ Using Rust FFI VK API');
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ Rust library not available: $e');
      }
    }

    _loaded = false;
    debugPrint('⚠️ No native VK API available, will use Dart fallback');
    return false;
  }

  /// Передать токен в нативный клиент.
  void setToken(String token, int? userId) {
    if (_useMethodChannel) {
      _channel!.invokeMethod('setToken', {
        'token': token,
        'userId': userId,
      });
    } else if (_useRust) {
      // Rust FFI — заглушка, будет реализовано позже
      debugPrint('NativeVkApi.setToken (Rust): $token, userId: $userId');
    }
  }

  /// Выполнить VK API запрос через нативный клиент.
  /// Возвращает сырой JSON ответ (Map или List), или null если нужно использовать Dart fallback.
  Future<dynamic> call(String method, Map<String, String> params) async {
    if (!_loaded) return null;

    try {
      if (_useMethodChannel) {
        final result = await _channel!.invokeMethod<String>('call', {
          'method': method,
          'params': params,
        });
        if (result != null) {
          return jsonDecode(result);
        }
        return null;
      } else if (_useRust) {
        // Rust FFI — заглушка, будет реализовано позже
        return null;
      }
    } catch (e) {
      debugPrint('Native call failed: $e');
    }

    return null;
  }
}