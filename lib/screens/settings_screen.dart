import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import 'log_viewer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _wifiOnlyDownload = false;
  bool _cellularDataPlayback = true;
  bool _highQualityAudio = false;
  int _downloadedCount = 0;
  String _cacheSize = '0 MB';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  void _loadSettings() {
    final provider = context.read<MusicProvider>();
    setState(() {
      _downloadedCount = provider.downloadedTracks.length;
    });
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/downloads');
      if (await downloadDir.exists()) {
        int totalSize = 0;
        await for (final entity in downloadDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
        if (mounted) {
          setState(() {
            _cacheSize = _formatBytes(totalSize);
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cacheSize = '0 MB';
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Очистить кэш', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Это удалит временные файлы. Скачанные треки не будут затронуты.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Очистить', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _cacheSize = '0 MB';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Кэш очищен')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // ============================================
              // USER PROFILE SECTION
              // ============================================
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue[800],
                      child: const Icon(Icons.person, color: Colors.white, size: 34),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Мой профиль',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${provider.tracks.length} треков · ${provider.playlists.length} плейлистов',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[600], size: 22),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ============================================
              // AUDIO QUALITY SECTION
              // ============================================
              _SectionLabel(title: 'КАЧЕСТВО ЗВУКА'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _SettingsSwitchTile(
                      icon: Icons.high_quality,
                      title: 'Высокое качество',
                      subtitle: 'Использовать больше трафика',
                      value: _highQualityAudio,
                      onChanged: (val) => setState(() => _highQualityAudio = val),
                    ),
                    _SettingsDivider(),
                    _SettingsSwitchTile(
                      icon: Icons.signal_cellular_alt,
                      title: 'Мобильный интернет',
                      subtitle: 'Воспроизведение через сотовые данные',
                      value: _cellularDataPlayback,
                      onChanged: (val) => setState(() => _cellularDataPlayback = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ============================================
              // DOWNLOADS SECTION
              // ============================================
              _SectionLabel(title: 'ЗАГРУЗКИ'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _SettingsSwitchTile(
                      icon: Icons.wifi,
                      title: 'Только Wi-Fi',
                      subtitle: 'Не использовать мобильные данные',
                      value: _wifiOnlyDownload,
                      onChanged: (val) => setState(() => _wifiOnlyDownload = val),
                    ),
                    _SettingsDivider(),
                    _SettingsActionTile(
                      icon: Icons.download_outlined,
                      title: 'Скачанные треки',
                      trailing: Text(
                        '$_downloadedCount',
                        style: TextStyle(color: Colors.grey[500], fontSize: 15),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ============================================
              // STORAGE SECTION
              // ============================================
              _SectionLabel(title: 'ПАМЯТЬ'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _SettingsActionTile(
                      icon: Icons.delete_outline,
                      title: 'Очистить кэш',
                      subtitle: _cacheSize,
                      onTap: _clearCache,
                    ),
                    _SettingsDivider(),
                    _SettingsActionTile(
                      icon: Icons.storage_outlined,
                      title: 'Управление загрузками',
                      subtitle: '$_downloadedCount треков',
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ============================================
              // ABOUT SECTION
              // ============================================
              _SectionLabel(title: 'О ПРИЛОЖЕНИИ'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _SettingsInfoTile(
                      icon: Icons.info_outline,
                      title: 'Версия',
                      trailing: '1.0.0',
                    ),
                    _SettingsDivider(),
                    _SettingsActionTile(
                      icon: Icons.description_outlined,
                      title: 'Лицензии',
                      onTap: () {
                        showLicensePage(
                          context: context,
                          applicationName: 'VK Z',
                          applicationVersion: '1.0.0',
                        );
                      },
                    ),
                    _SettingsDivider(),
                    _SettingsActionTile(
                      icon: Icons.bug_report_outlined,
                      title: 'Логи',
                      subtitle: 'Просмотр отладочных логов',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LogViewerScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ============================================
              // LOGOUT BUTTON
              // ============================================
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red[400], size: 24),
                  title: Text(
                    'Выйти',
                    style: TextStyle(
                      color: Colors.red[400],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey[700], size: 20),
                  onTap: () {
                    showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        title: const Text('Выйти', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'Вы уверены, что хотите выйти?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ).then((confirm) {
                      if (confirm == true && mounted) {
                        provider.logout();
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                      }
                    });
                  },
                ),
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

// ============================================
// SECTION LABEL
// ============================================
class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ============================================
// SETTINGS SWITCH TILE
// ============================================
class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[400], size: 24),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              )
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.blue,
          activeTrackColor: Colors.blue.withValues(alpha: 0.4),
          inactiveThumbColor: Colors.grey[600],
          inactiveTrackColor: Colors.grey[800],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}

// ============================================
// SETTINGS ACTION TILE
// ============================================
class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[400], size: 24),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              )
            : null,
        trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}

// ============================================
// SETTINGS INFO TILE (no tap)
// ============================================
class _SettingsInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailing;

  const _SettingsInfoTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[400], size: 24),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        trailing: Text(
          trailing,
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}

// ============================================
// SETTINGS DIVIDER
// ============================================
class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: Colors.grey[850],
        thickness: 0.5,
      ),
    );
  }
}