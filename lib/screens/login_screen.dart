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

  @override
  void initState() {
    super.initState();
    _initWebView();
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
              _checkForToken(url);
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
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Не удалось открыть браузер для авторизации.';
          });
        }
      }
    }
  }

  void _checkForToken(String url) {
    if (!url.startsWith(VkConfig.redirectUri)) return;

    final token = VkConfig.extractToken(url);
    final userId = VkConfig.extractUserId(url);

    if (token != null) {
      context.read<MusicProvider>().setToken(token, userId: userId);
      Navigator.of(context).pushReplacementNamed('/home');
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

                // Кнопка входа
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