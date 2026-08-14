import 'package:flutter/material.dart';
import 'chat_list_screen.dart';
import 'status_screen.dart';
import 'calls_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _pageController = PageController();

  final _titles = ['هم‌گب', 'وضعیت', 'تماس‌ها', 'تنظیمات'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_currentIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'profile', child: Text('پروفایل')),
                const PopupMenuItem(value: 'settings', child: Text('تنظیمات')),
                const PopupMenuItem(value: 'logout', child: Text('خروج')),
              ],
              onSelected: (val) {
                if (val == 'profile') Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                if (val == 'settings') Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          children: const [
            ChatListScreen(),
            StatusScreen(),
            CallsScreen(),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) {
            _pageController.jumpToPage(i);
            setState(() => _currentIndex = i);
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.chat), label: 'گفتگوها', selectedIcon: Icon(Icons.chat)),
            NavigationDestination(icon: Icon(Icons.camera_alt_outlined), label: 'وضعیت', selectedIcon: Icon(Icons.camera_alt)),
            NavigationDestination(icon: Icon(Icons.call_outlined), label: 'تماس‌ها', selectedIcon: Icon(Icons.call)),
            NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'تنظیمات', selectedIcon: Icon(Icons.settings)),
          ],
        ),
      ),
    );
  }
}
