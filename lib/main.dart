import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'services/prefs_service.dart';
import 'services/local_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefsService.init();
  await LocalStore.init();
  runApp(const HamgapApp());
}

class HamgapApp extends StatefulWidget {
  const HamgapApp({super.key});
  @override
  State<HamgapApp> createState() => _HamgapAppState();
}

class _HamgapAppState extends State<HamgapApp> {
  ThemeMode _getThemeMode() {
    switch (PrefsService.themeMode) {
      case 'dark': return ThemeMode.dark;
      case 'light': return ThemeMode.light;
      default: return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'هم‌گب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00a884), brightness: Brightness.light),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFfafafa),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF00a884), foregroundColor: Colors.white, elevation: 0),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF00a884),
          labelTextStyle: MaterialStateProperty.all(const TextStyle(fontSize: 12)),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00a884), brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0b141a),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF202c33), foregroundColor: Color(0xFFe9edef), elevation: 0),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF202c33),
          indicatorColor: const Color(0xFF00a884),
          labelTextStyle: MaterialStateProperty.all(const TextStyle(fontSize: 12, color: Color(0xFF8696a0))),
        ),
      ),
      themeMode: _getThemeMode(),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (PrefsService.isLoggedIn) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}
