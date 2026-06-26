import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Dart FFI обёртка для Rust VK API клиента.
///
/// Загружает скомпилированную Rust-библиотеку (librust_vk_z.so / librust_vk_z.dylib / rust_vk_z.dll)
/// и вызывает функции VK API через FFI.
///
/// Если библиотека не найдена — использует чистый Dart HttpClient как fallback.
class RustVkApi {
  static RustVkApi? _instance;
  DynamicLibrary? _lib;
  bool _loaded = false;

  RustVkApi._();

  static RustVkApi get instance {
    _instance ??= RustVkApi._();
    return _instance!;
  }

  bool get isLoaded => _loaded;

  /// Попытаться загрузить Rust-библиотеку
  bool tryLoad() {
    if (_loaded) return true;

    try {
      if (Platform.isAndroid) {
        _lib = DynamicLibrary.open('librust_vk_z.so');
      } else if (Platform.isIOS) {
        _lib = DynamicLibrary.process(); // static link on iOS
      } else if (Platform.isMacOS) {
        _lib = DynamicLibrary.open('librust_vk_z.dylib');
      } else if (Platform.isWindows) {
        _lib = DynamicLibrary.open('rust_vk_z.dll');
      } else if (Platform.isLinux) {
        _lib = DynamicLibrary.open('librust_vk_z.so');
      }

      if (_lib != null) {
        _loaded = true;
        debugPrint('✅ Rust VK API library loaded successfully');
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Rust VK API library not available: $e');
    }

    _loaded = false;
    return false;
  }

  /// Передать токен в Rust
  void setToken(String token, int? userId) {
    // Заглушка — будет вызывать Rust FFI когда библиотека собрана
    debugPrint('RustVkApi.setToken: $token, userId: $userId');
  }

  /// Выполнить VK API запрос через Rust.
  /// Возвращает сырой JSON ответ, или null если нужно использовать Dart fallback.
  Future<dynamic> callRust(String method, Map<String, String> params) async {
    if (!_loaded) return null;

    // Здесь будет вызов Rust через FFI
    // Пока заглушка — возвращаем null, чтобы использовать Dart fallback
    return null;
  }
}