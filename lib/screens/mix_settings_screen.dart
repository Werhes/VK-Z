import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mix_settings.dart';
import '../providers/music_provider.dart';

/// Экран настройки VK Микса.
///
/// Аналог SettingMix.xaml из Music-M.
/// Позволяет пользователю настроить параметры микса:
/// настроение, жанры, темп и т.д.
class MixSettingsScreen extends StatefulWidget {
  final String mixId;

  const MixSettingsScreen({
    super.key,
    this.mixId = 'common',
  });

  @override
  State<MixSettingsScreen> createState() => _MixSettingsScreenState();
}

class _MixSettingsScreenState extends State<MixSettingsScreen> {
  MixSettings? _settings;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<MusicProvider>().apiService;
      final settings = await api.getStreamMixSettings(widget.mixId);
      if (mounted) {
        setState(() {
          _settings = settings?.settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onOptionToggled(MixCategory category, MixOption option) {
    setState(() {
      option.selected = !option.selected;
    });
  }

  void _resetSettings() {
    setState(() {
      for (final category in _settings?.categories ?? []) {
        for (final option in category.options) {
          option.selected = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Настройки микса'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'Не удалось загрузить настройки',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: _loadSettings,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (_settings == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Настройки недоступны',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final settings = _settings!;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            settings.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // Subtitle
        if (settings.subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              settings.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
              ),
            ),
          ),

        // Categories
        for (int i = 0; i < settings.categories.length; i++) ...[
          _CategoryWidget(
            category: settings.categories[i],
            onOptionToggled: _onOptionToggled,
          ),
          if (i < settings.categories.length - 1)
            const SizedBox(height: 16),
        ],

        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetSettings,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[400],
                  side: BorderSide(color: Colors.grey[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Сбросить', style: TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Применить', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

/// Виджет категории настроек микса.
///
/// Аналог PicturedControl / BTNSControl из Music-M.
/// Отображает заголовок категории и список опций в виде переключателей.
class _CategoryWidget extends StatelessWidget {
  final MixCategory category;
  final void Function(MixCategory category, MixOption option) onOptionToggled;

  const _CategoryWidget({
    required this.category,
    required this.onOptionToggled,
  });

  @override
  Widget build(BuildContext context) {
    final isPictured = category.type == 'pictured_button_horizontal_group';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            category.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // Options
        if (isPictured)
          _buildPicturedOptions()
        else
          _buildSimpleOptions(),
      ],
    );
  }

  Widget _buildSimpleOptions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: category.options.map((option) {
          final isSelected = option.selected;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: FilterChip(
              label: Text(option.title),
              selected: isSelected,
              onSelected: (_) => onOptionToggled(category, option),
              selectedColor: Colors.blue.withValues(alpha: 0.3),
              checkmarkColor: Colors.blue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue : Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              backgroundColor: Colors.grey[850],
              side: BorderSide(
                color: isSelected ? Colors.blue.withValues(alpha: 0.5) : Colors.grey[800]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPicturedOptions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: category.options.map((option) {
          final isSelected = option.selected;
          return GestureDetector(
            onTap: () => onOptionToggled(category, option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.withValues(alpha: 0.2)
                    : Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.blue.withValues(alpha: 0.6)
                      : Colors.grey[800]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon or emoji placeholder
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.withValues(alpha: 0.3)
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getIconForOption(option),
                      color: isSelected ? Colors.blue : Colors.grey[500],
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    option.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.blue : Colors.grey[400],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForOption(MixOption option) {
    final title = option.title.toLowerCase();
    if (title.contains('весел') || title.contains('радост')) return Icons.emoji_emotions;
    if (title.contains('груст') || title.contains('печал')) return Icons.sentiment_dissatisfied;
    if (title.contains('спокой') || title.contains('расслаб')) return Icons.self_improvement;
    if (title.contains('энерги') || title.contains('бодр')) return Icons.bolt;
    if (title.contains('романт')) return Icons.favorite;
    if (title.contains('ноч') || title.contains('вечер')) return Icons.dark_mode;
    if (title.contains('утр') || title.contains('днев')) return Icons.wb_sunny;
    if (title.contains('поп') || title.contains('pop')) return Icons.music_note;
    if (title.contains('рок') || title.contains('rock')) return Icons.music_note;
    if (title.contains('джаз') || title.contains('jazz')) return Icons.piano;
    if (title.contains('класси') || title.contains('classic')) return Icons.music_note;
    if (title.contains('хип') || title.contains('hip') || title.contains('rap') || title.contains('рэп')) return Icons.mic;
    if (title.contains('электро') || title.contains('electronic')) return Icons.electric_bolt;
    if (title.contains('танц') || title.contains('dance')) return Icons.celebration;
    if (title.contains('инди') || title.contains('indie')) return Icons.graphic_eq;
    if (title.contains('рус') || title.contains('russian')) return Icons.language;
    if (title.contains('зарубеж') || title.contains('foreign')) return Icons.public;
    if (title.contains('нов') || title.contains('new')) return Icons.fiber_new;
    if (title.contains('любим') || title.contains('favor') || title.contains('избран')) return Icons.star;
    if (title.contains('тренд') || title.contains('trend')) return Icons.trending_up;
    if (title.contains('хит') || title.contains('hit')) return Icons.whatshot;
    if (title.contains('медлен') || title.contains('slow')) return Icons.slow_motion_video;
    if (title.contains('быстр') || title.contains('fast')) return Icons.fast_forward;
    return Icons.toggle_off;
  }
}