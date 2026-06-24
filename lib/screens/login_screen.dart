import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/vk_config.dart';
import '../providers/music_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
            _checkForToken(url);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
            _checkForToken(url);
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(VkConfig.oAuthUrl));
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
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/vk_logo.png',
                      width: 80,
                      height: 80,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.music_note, size: 80, color: Colors.blue),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'VK Z',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      'Загрузка страницы авторизации...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}