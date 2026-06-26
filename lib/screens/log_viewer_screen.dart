import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/log_service.dart';

/// Экран просмотра логов приложения.
///
/// Показывает все логи, собранные LogService.
/// Можно фильтровать по уровню и искать по тексту.
class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final _logService = LogService.instance;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  LogLevel _filterLevel = LogLevel.debug;
  bool _autoScroll = true;
  bool _showOnlyErrors = false;

  @override
  void initState() {
    super.initState();
    _logService.addListener(_onLogsUpdated);
  }

  @override
  void dispose() {
    _logService.removeListener(_onLogsUpdated);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onLogsUpdated() {
    if (mounted) {
      setState(() {});
      if (_autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  List<LogEntry> _getFilteredLogs() {
    var logs = _logService.getFilteredLogs(
      minLevel: _showOnlyErrors ? LogLevel.error : _filterLevel,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
    return logs;
  }

  @override
  Widget build(BuildContext context) {
    final logs = _getFilteredLogs();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('Логи'),
        backgroundColor: const Color(0xFF1A1A2E),
        centerTitle: true,
        actions: [
          // Кнопка очистки
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            tooltip: 'Очистить логи',
            onPressed: () {
              _logService.clear();
            },
          ),
          // Кнопка автоскролла
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center,
              color: _autoScroll ? Colors.blue : Colors.white54,
            ),
            tooltip: _autoScroll ? 'Автоскролл вкл' : 'Автоскролл выкл',
            onPressed: () {
              setState(() => _autoScroll = !_autoScroll);
            },
          ),
          // Кнопка поделиться
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white70),
            tooltip: 'Поделиться логами',
            onPressed: () => _shareLogs(logs),
          ),
        ],
      ),
      body: Column(
        children: [
          // Панель фильтров
          _buildFilterBar(),
          // Счётчик логов
          _buildLogCounter(logs.length),
          // Список логов
          Expanded(
            child: logs.isEmpty
                ? _buildEmptyState()
                : _buildLogList(logs),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF1A1A2E),
      child: Column(
        children: [
          // Поиск
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Поиск по логам...',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.black26,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 8),
          // Фильтры по уровню
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Все',
                  selected: !_showOnlyErrors && _filterLevel == LogLevel.debug,
                  onTap: () => setState(() {
                    _showOnlyErrors = false;
                    _filterLevel = LogLevel.debug;
                  }),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'INFO+',
                  selected: !_showOnlyErrors && _filterLevel == LogLevel.info,
                  onTap: () => setState(() {
                    _showOnlyErrors = false;
                    _filterLevel = LogLevel.info;
                  }),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'WARN+',
                  selected: !_showOnlyErrors && _filterLevel == LogLevel.warning,
                  onTap: () => setState(() {
                    _showOnlyErrors = false;
                    _filterLevel = LogLevel.warning;
                  }),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: '❌ Ошибки',
                  selected: _showOnlyErrors,
                  onTap: () => setState(() {
                    _showOnlyErrors = true;
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCounter(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.black26,
      child: Text(
        'Всего записей: $count',
        style: TextStyle(color: Colors.grey[600], fontSize: 11),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.article_outlined, size: 64, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(
            'Логов нет',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Выполните действия в приложении,\nчтобы увидеть логи',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(List<LogEntry> logs) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final entry = logs[index];
        return _LogEntryTile(entry: entry);
      },
    );
  }

  void _shareLogs(List<LogEntry> logs) {
    // Копируем логи в буфер обмена
    final text = logs.map((e) {
      final tag = e.tag != null ? ' [${e.tag}]' : '';
      return '[${e.formattedTime}]${e.levelIcon}$tag ${e.message}';
    }).join('\n');

    // Используем Clipboard
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Логи скопированы в буфер обмена'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ============================================
// FILTER CHIP
// ============================================
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.blue.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.blue : Colors.grey[400],
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ============================================
// LOG ENTRY TILE
// ============================================
class _LogEntryTile extends StatelessWidget {
  final LogEntry entry;

  const _LogEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(entry.level);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: entry.level == LogLevel.error
            ? Colors.red.withValues(alpha: 0.05)
            : entry.level == LogLevel.warning
                ? Colors.orange.withValues(alpha: 0.03)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Время
          SizedBox(
            width: 72,
            child: Text(
              entry.formattedTime,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Иконка уровня
          Text(
            entry.levelIcon,
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 4),
          // Тег
          if (entry.tag != null)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                entry.tag!,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          // Сообщение
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontFamily: 'monospace',
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.lightBlue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.redAccent;
    }
  }
}
