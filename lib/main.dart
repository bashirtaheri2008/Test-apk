import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_list_screen.dart';
import 'services/prefs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefsService.init();
  runApp(const HamgapApp());
}

class HamgapApp extends StatelessWidget {
  const HamgapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'هم‌گب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0ea5e9),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFf8fafc),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0f172a),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0ea5e9),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0f172a),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1e293b),
          foregroundColor: Color(0xFFf1f5f9),
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const Gatekeeper(),
    );
  }
}

class Gatekeeper extends StatefulWidget {
  const Gatekeeper({super.key});

  @override
  State<Gatekeeper> createState() => _GatekeeperState();
}

class _GatekeeperState extends State<Gatekeeper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLogin());
  }

  void _checkLogin() {
    final loggedIn = PrefsService.isLoggedIn;
    if (!loggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
