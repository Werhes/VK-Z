import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/vk_config.dart';
import '../providers/music_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  WebViewController? _controller;
  bool _isLoading = false;
  bool _showWebView = false;
  String? _errorMessage;
  bool _webViewAvailable = true;
  final _tokenUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _tokenUrlController.dispose();
    super.dispose();
  }

  void _initWebView() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
              }
              _checkForToken(url);
            },
            onPageFinished: (url) {
              if (mounted) {
                setState(() => _isLoading = false);
              }
              if (!_checkForToken(url)) {
                _checkForAuthError(url);
              }
            },
            onWebResourceError: (error) {
              debugPrint('WebView error: ${error.description} (code: ${error.errorCode}, type: ${error.errorType})');
              if (error.isForMainFrame == true) {
                if (mounted) {
                  setState(() {
                    _errorMessage = 'Не удалось загрузить страницу авторизации.\n'
                        'Проверьте подключение к интернету.';
                    _isLoading = false;
                  });
                }
              }
            },
          ),
        );
    } catch (e) {
      debugPrint('WebView not available on this platform: $e');
      _webViewAvailable = false;
    }
  }

  Future<void> _startAuth() async {
    if (_webViewAvailable && _controller != null) {
      // Use WebView on mobile platforms
      setState(() {
        _showWebView = true;
        _errorMessage = null;
        _isLoading = true;
      });

      try {
        await _controller!.clearCache();
        await _controller!.clearLocalStorage();
        await _controller!.loadRequest(Uri.parse(VkConfig.oAuthUrl));
      } catch (e) {
        debugPrint('WebView load error: $e');
        if (mounted) {
          setState(() {
            _errorMessage = 'Ошибка загрузки: $e';
            _isLoading = false;
          });
        }
      }
    } else {
      // Use system browser on desktop platforms
      final uri = Uri.parse(VkConfig.oAuthUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          _showManualTokenDialog();
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Не удалось открыть браузер для авторизации.';
          });
        }
      }
    }
  }

  void _showManualTokenDialog() {
    _tokenUrlController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.link, color: Color(0xFF0077FF)),
            SizedBox(width: 8),
            Text('Вставить токен', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '1. Авторизуйся в открывшемся браузере\n'
              '2. Скопируй полный URL из адресной строки\n'
              '   (начинается с https://oauth.vk.ru/blank.html#)\n'
              '3. Вставь его в поле ниже',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenUrlController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Вставьте URL с токеном сюда...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _processManualToken(_tokenUrlController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Готово', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _processManualToken(String input) {
    if (input.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Поле не может быть пустым. Вставьте URL с токеном.';
        });
      }
      return;
    }

    // Try to extract token from the pasted URL
    final token = VkConfig.extractToken(input);
    final userId = VkConfig.extractUserId(input);

    if (token != null) {
      context.read<MusicProvider>().setToken(token, userId: userId);
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Maybe user pasted just the token itself (not the full URL)
      // Check if it looks like a VK token (starts with vk1/ or is alphanumeric)
      if (input.length > 20 && !input.contains(' ')) {
        context.read<MusicProvider>().setToken(input, userId: null);
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Не удалось извлечь токен из введённых данных.\n'
                'Убедитесь, что вы скопировали полный URL из адресной строки.';
          });
        }
      }
    }
  }

  /// Returns true if a token was found and processed.
  bool _checkForToken(String url) {
    if (!url.startsWith(VkConfig.redirectUri)) return false;

    final token = VkConfig.extractToken(url);
    final userId = VkConfig.extractUserId(url);

    if (token != null) {
      context.read<MusicProvider>().setToken(token, userId: userId);
      Navigator.of(context).pushReplacementNamed('/home');
      return true;
    }
    return false;
  }

  void _checkForAuthError(String url) {
    if (url.contains('error=') || url.contains('error_description=')) {
      final uri = Uri.parse(url);
      final error = uri.queryParameters['error'] ?? '';
      final errorDesc = uri.queryParameters['error_description'] ?? '';

      if (error == 'invalid_request' && errorDesc.contains('blocked')) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Приложение VK заблокировано.\n'
                'Создай своё приложение на https://dev.vk.ru/\n'
                'и укажи его ID в lib/services/vk_config.dart';
            _isLoading = false;
          });
        }
      } else if (errorDesc.isNotEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Ошибка авторизации VK: $errorDesc';
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _showWebView ? _buildWebView(theme) : _buildWelcomeScreen(theme),
    );
  }

  Widget _buildWelcomeScreen(ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0A1A),
            Color(0xFF1A1A3E),
            Color(0xFF0A0A1A),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Spacer(flex: 2),

                // Иконка
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0077FF),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0077FF).withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                // VK Z
                Text(
                  'VK Z',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 42,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Слушай музыку из VK',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),

                const Spacer(flex: 1),

                // Кнопка входа через VK
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _startAuth,
                    icon: const Icon(Icons.telegram, color: Colors.white),
                    label: const Text(
                      'Войти через VK',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Кнопка ручного ввода токена
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _showManualTokenDialog,
                    icon: const Icon(Icons.keyboard, color: Colors.white70, size: 20),
                    label: const Text(
                      'Ввести токен вручную',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Войдите в свой аккаунт VK,\nчтобы слушать музыку',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebView(ThemeData theme) {
    return Stack(
      children: [
        // WebView
        if (_controller != null) WebViewWidget(controller: _controller!),

        // Кнопка "Назад" сверху
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              setState(() {
                _showWebView = false;
                _errorMessage = null;
              });
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
            ),
          ),
        ),

        // Ошибка
        if (_errorMessage != null)
          Container(
            color: Colors.black87,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _startAuth,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Повторить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Загрузка
        if (_isLoading && _errorMessage == null)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF0077FF)),
            ),
          ),
      ],
    );
  }
}