import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/vk_auth_service.dart';
import '../services/vk_config.dart';
import '../providers/music_provider.dart';

/// Экран входа с поддержкой:
/// 1. Вход по номеру телефона (как в Music-M)
/// 2. Ввод токена вручную (запасной вариант)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _vkAuth = VkAuthService();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _tokenUrlController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Auth flow state
  String? _login;
  String? _sid;
  bool _needsPassword = false;
  bool _needsCode = false;
  String? _codeLength;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _tokenUrlController.dispose();
    super.dispose();
  }

  Future<void> _validateAccount() async {
    final login = _phoneController.text.trim();
    if (login.isEmpty) {
      setState(() => _errorMessage = 'Введите номер телефона или email');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await _vkAuth.validateAccount(login);
      _login = login;
      _sid = result.sid;

      if (result.needsPassword || result.hasPasswordFlow) {
        setState(() {
          _needsPassword = true;
          _needsCode = false;
          _isLoading = false;
          _successMessage = 'Аккаунт найден. Введите пароль.';
        });
      } else if (result.needsValidation) {
        // Сразу запрашиваем код (без пароля)
        setState(() {
          _needsPassword = false;
          _needsCode = true;
          _isLoading = false;
          _successMessage = 'На ваш телефон отправлен код подтверждения';
        });
      } else {
        setState(() {
          _errorMessage = 'Неизвестный способ авторизации: ${result.flowName}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _authorizeWithPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Введите пароль');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _vkAuth.authorizeWithPassword(
        login: _login!,
        sid: _sid!,
        password: password,
      );
      _onAuthSuccess(result);
    } on VkAuthValidationException catch (e) {
      setState(() {
          _needsCode = true;
          _codeLength = '6';
          _isLoading = false;
          _successMessage = 'Требуется подтверждение. Код отправлен на ${e.phoneMask ?? 'телефон'}.';
        });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Введите код подтверждения');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _vkAuth.confirmCode(
        login: _login!,
        sid: _sid!,
        code: code,
        password: _passwordController.text.trim().isNotEmpty
            ? _passwordController.text.trim()
            : null,
      );
      _onAuthSuccess(result);
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка: $e';
        _isLoading = false;
      });
    }
  }

  void _onAuthSuccess(AuthTokenResult result) {
    final provider = context.read<MusicProvider>();
    provider.setToken(result.accessToken, userId: result.userId);
    provider.loadUserMusic();
    Navigator.of(context).pushReplacementNamed('/home');
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
              '1. Авторизуйся в браузере\n'
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
      setState(() => _errorMessage = 'Поле не может быть пустым.');
      return;
    }

    final token = VkConfig.extractToken(input);
    final userId = VkConfig.extractUserId(input);

    if (token != null) {
      context.read<MusicProvider>().setToken(token, userId: userId);
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (input.length > 20 && !input.contains(' ')) {
      context.read<MusicProvider>().setToken(input, userId: null);
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() => _errorMessage = 'Не удалось извлечь токен.');
    }
  }

  void _resetFlow() {
    setState(() {
      _needsPassword = false;
      _needsCode = false;
      _errorMessage = null;
      _successMessage = null;
      _login = null;
      _sid = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),

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

                  const SizedBox(height: 40),

                  // Сообщение об ошибке
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Сообщение об успехе
                  if (_successMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Поле ввода номера телефона / email
                  if (!_needsPassword && !_needsCode)
                    _buildTextField(
                      controller: _phoneController,
                      hint: 'Номер телефона или email',
                      icon: Icons.phone_android,
                      keyboardType: TextInputType.phone,
                    ),

                  // Поле ввода пароля
                  if (_needsPassword)
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Пароль',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),

                  // Поле ввода кода 2FA
                  if (_needsCode)
                    _buildTextField(
                      controller: _codeController,
                      hint: 'Код подтверждения${_codeLength != null ? ' ($_codeLength цифр)' : ''}',
                      icon: Icons.sms,
                      keyboardType: TextInputType.number,
                    ),

                  const SizedBox(height: 16),

                  // Кнопка действия
                  if (!_needsPassword && !_needsCode)
                    _buildButton(
                      text: 'Продолжить',
                      icon: Icons.arrow_forward,
                      onPressed: _isLoading ? null : _validateAccount,
                    ),

                  if (_needsPassword)
                    _buildButton(
                      text: 'Войти',
                      icon: Icons.login,
                      onPressed: _isLoading ? null : _authorizeWithPassword,
                    ),

                  if (_needsCode)
                    _buildButton(
                      text: 'Подтвердить',
                      icon: Icons.check_circle_outline,
                      onPressed: _isLoading ? null : _confirmCode,
                    ),

                  // Кнопка "Назад" при многошаговой авторизации
                  if (_needsPassword || _needsCode)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton(
                        onPressed: _resetFlow,
                        child: const Text(
                          'Назад',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Разделитель
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.white12)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'или',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ),
                      const Expanded(child: Divider(color: Colors.white12)),
                    ],
                  ),

                  const SizedBox(height: 16),

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

                  const SizedBox(height: 40),

                  // Индикатор загрузки
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: CircularProgressIndicator(color: Color(0xFF0077FF)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
          prefixIcon: Icon(icon, color: Colors.grey[500], size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0077FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}