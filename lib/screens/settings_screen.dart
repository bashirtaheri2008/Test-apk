import 'package:flutter/material.dart';
import '../services/prefs_service.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = PrefsService.themeMode == 'dark';
  bool _notifications = true;
  bool _readReceipts = true;
  bool _lastSeen = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: ListView(
          children: [
            ListTile(
              leading: CircleAvatar(radius: 28, backgroundColor: theme.colorScheme.primary,
                child: Text(PrefsService.name.isNotEmpty ? PrefsService.name[0] : '؟', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22))),
              title: Text(PrefsService.name.isNotEmpty ? PrefsService.name : 'کاربر هم‌گب', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(PrefsService.bio.isNotEmpty ? PrefsService.bio : 'بیوگرافی تنظیم نشده'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
            const Divider(),
            _sectionTitle(theme, 'حریم خصوصی'),
            SwitchListTile(
              secondary: const Icon(Icons.visibility_outlined),
              title: const Text('رسید خوانده‌شدن'),
              value: _readReceipts, onChanged: (v) => setState(() => _readReceipts = v),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.access_time),
              title: const Text('آخرین بازدید'),
              value: _lastSeen, onChanged: (v) => setState(() => _lastSeen = v),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('مسدود شده‌ها'), trailing: const Icon(Icons.chevron_left),
              onTap: () {},
            ),
            const Divider(),
            _sectionTitle(theme, 'اعلان‌ها'),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('اعلان‌ها'),
              value: _notifications, onChanged: (v) => setState(() => _notifications = v),
            ),
            const Divider(),
            _sectionTitle(theme, 'نمایش'),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('حالت تاریک'),
              value: _darkMode, onChanged: (v) { setState(() => _darkMode = v); PrefsService.themeMode = v ? 'dark' : 'light'; },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('اندازه متن'), trailing: const Icon(Icons.chevron_left), onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper_outlined),
              title: const Text('پس‌زمینه گفتگو'), trailing: const Icon(Icons.chevron_left), onTap: () {},
            ),
            const Divider(),
            _sectionTitle(theme, 'ذخیره'),
            ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: const Text('مدیریت ذخیره‌سازی'), trailing: const Icon(Icons.chevron_left), onTap: () {},
            ),
            const Divider(),
            _sectionTitle(theme, 'درباره'),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('راهنما'), trailing: const Icon(Icons.chevron_left), onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('درباره هم‌گب'),
              subtitle: const Text('نسخه ۴.۰ (Flutter)'), trailing: const Icon(Icons.chevron_left), onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)));
  }
}
