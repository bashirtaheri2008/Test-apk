import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _sp {
    if (_prefs == null) {
      throw StateError('Prefs not initialized. Call PrefsService.init() first.');
    }
    return _prefs!;
  }

  static String get uid => _sp.getString('uid') ?? '';
  static set uid(String v) => _sp.setString('uid', v);

  static String get phone => _sp.getString('phone') ?? '';
  static set phone(String v) => _sp.setString('phone', v);

  static String get name => _sp.getString('name') ?? '';
  static set name(String v) => _sp.setString('name', v);

  static String get bio => _sp.getString('bio') ?? '';
  static set bio(String v) => _sp.setString('bio', v);

  static String get photoURL => _sp.getString('photoURL') ?? '';
  static set photoURL(String v) => _sp.setString('photoURL', v);

  static bool get isLoggedIn => _sp.getBool('logged_in') ?? false;
  static set isLoggedIn(bool v) => _sp.setBool('logged_in', v);

  static Future<void> logout() async {
    await _sp?.clear();
    _prefs = null;
  }
}
