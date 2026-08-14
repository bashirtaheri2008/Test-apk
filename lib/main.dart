import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_list_screen.dart';

void main() {
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
        fontFamily: 'Vazirmatn',
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
        fontFamily: 'Vazirmatn',
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
  bool _loading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('logged_in') ?? false;
    setState(() {
      _isLoggedIn = loggedIn;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SplashScreen();
    if (_isLoggedIn) return const ChatListScreen();
    return const AuthScreen();
  }
}
