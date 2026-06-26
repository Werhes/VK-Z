import 'package:flutter/foundation.dart';

/// Единый сервис для сбора и просмотра логов приложения.
///
/// Заменяет прямой вызов debugPrint, сохраняя все логи в список,
/// который можно просмотреть на экране LogViewerScreen.
class LogService {
  LogService._();

  static final LogService _instance = LogService._();
  static LogService get instance => _instance;

  /// Максимальное количество хранимых логов
  static const int _maxLogs = 5000;

  /// Список логов
  final List<LogEntry> _logs = [];

  /// Слушатели обновлений
  final List<VoidCallback> _listeners = [];

  /// Фильтр по уровню
  LogLevel _minLevel = LogLevel.debug;

  /// Добавить запись в лог
  void log(String message, {LogLevel level = LogLevel.debug, String? tag}) {
    final entry = LogEntry(
      message: message,
      level: level,
      tag: tag,
      timestamp: DateTime.now(),
    );

    _logs.add(entry);

    // Ограничиваем размер
    if (_logs.length > _maxLogs) {
      _logs.removeRange(0, _logs.length - _maxLogs);
    }

    // Также выводим в консоль
    final prefix = _levelPrefix(level);
    final tagStr = tag != null ? '[$tag] ' : '';
    debugPrint('$prefix $tagStr$message');

    // Уведомляем слушателей
    for (final listener in _listeners) {
      try {
        listener();
      } catch (_) {}
    }
  }

  /// Получить все логи
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// Получить отфильтрованные логи
  List<LogEntry> getFilteredLogs({
    LogLevel? minLevel,
    String? searchQuery,
    String? tag,
  }) {
    var result = _logs;

    final level = minLevel ?? _minLevel;
    result = result.where((e) => e.level.index >= level.index).toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result
          .where((e) => e.message.toLowerCase().contains(query))
          .toList();
    }

    if (tag != null && tag.isNotEmpty) {
      result = result.where((e) => e.tag == tag).toList();
    }

    return result;
  }

  /// Очистить логи
  void clear() {
    _logs.clear();
    for (final listener in _listeners) {
      try {
        listener();
      } catch (_) {}
    }
  }

  /// Установить минимальный уровень для фильтра
  void setMinLevel(LogLevel level) {
    _minLevel = level;
    for (final listener in _listeners) {
      try {
        listener();
      } catch (_) {}
    }
  }

  LogLevel get minLevel => _minLevel;

  /// Подписаться на обновления
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Отписаться от обновлений
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  String _levelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG]';
      case LogLevel.info:
        return '[INFO]';
      case LogLevel.warning:
        return '[WARN]';
      case LogLevel.error:
        return '[ERROR]';
    }
  }

  // ==========================================
  // Удобные методы-обёртки
  // ==========================================

  static void d(String message, {String? tag}) {
    instance.log(message, level: LogLevel.debug, tag: tag);
  }

  static void i(String message, {String? tag}) {
    instance.log(message, level: LogLevel.info, tag: tag);
  }

  static void w(String message, {String? tag}) {
    instance.log(message, level: LogLevel.warning, tag: tag);
  }

  static void e(String message, {String? tag}) {
    instance.log(message, level: LogLevel.error, tag: tag);
  }
}

/// Уровень логирования
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Одна запись лога
class LogEntry {
  final String message;
  final LogLevel level;
  final String? tag;
  final DateTime timestamp;

  LogEntry({
    required this.message,
    required this.level,
    this.tag,
    required this.timestamp,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  String get levelIcon {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }
}