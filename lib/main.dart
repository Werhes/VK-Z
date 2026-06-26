import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/music_provider.dart';
import 'services/vk_api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MusicProvider(VkApiService()),
      child: MaterialApp(
        title: 'VK Z',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'VKSansDisplay',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

/// Экран загрузки — проверяет сохранённую сессию и перенаправляет
/// на /home (если есть токен) или на /login (если нет)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final provider = context.read<MusicProvider>();
    final restored = await provider.tryRestoreSession();

    if (!mounted) return;

    if (restored) {
      // Сессия восстановлена — сразу загружаем музыку и идём на home
      // Генерируем device_id если его нет
      if (provider.apiService.deviceId == null) {
        // device_id будет сгенерирован при первом API вызове
      }
      provider.loadUserMusic();
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Нет сохранённой сессии — показываем экран входа
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
