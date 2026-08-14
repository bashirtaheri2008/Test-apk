import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/prefs_service.dart';
import '../widgets/avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _phone = '';
  String _bio = '';
  String _photoURL = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _name = PrefsService.name.isNotEmpty ? PrefsService.name : 'کاربر هم‌گب';
      _phone = PrefsService.phone;
      _bio = PrefsService.bio;
      _photoURL = PrefsService.photoURL;
    });
  }

  void _showEdit() {
    final nameCtrl = TextEditingController(text: _name);
    final bioCtrl = TextEditingController(text: _bio);
    showDialog(context: context, builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ویرایش پروفایل'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'نام نمایشی', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: bioCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'بیوگرافی', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          FilledButton(onPressed: () async {
            final name = nameCtrl.text.trim();
            final bio = bioCtrl.text.trim();
            if (name.isEmpty) return;
            PrefsService.name = name;
            PrefsService.bio = bio;
            await ApiService.updateUserProfile(PrefsService.uid, name, bio, PrefsService.photoURL);
            if (mounted) { Navigator.pop(context); _loadProfile(); _snack('پروفایل به‌روز شد'); }
          }, child: const Text('ذخیره')),
        ],
      ),
    ));
  }

  void _logout() async {
    showDialog(context: context, builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('خروج'),
        content: const Text('آیا مطمئن هستید می‌خواهید خارج شوید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async { await PrefsService.logout(); if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false); },
            child: const Text('بله، خروج')),
        ],
      ),
    ));
  }

  void _snack(String msg) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Container(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [theme.colorScheme.primary, theme.colorScheme.tertiary])),
            padding: const EdgeInsets.only(top: 50, bottom: 30),
            child: Column(children: [
              GestureDetector(onTap: () => _snack('تغییر عکس به‌زودی'),
                child: Avatar(name: _name, photoUrl: _photoURL, radius: 55)),
              const SizedBox(height: 16),
              Text(_name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(_phone, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            ]),
          )),
          SliverToBoxAdapter(child: Container(
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _infoCard('نام نمایشی', _name, theme),
              _infoCard('شماره تلفن', _phone, theme),
              _infoCard('بیوگرافی', _bio.isNotEmpty ? _bio : 'تنظیم نشده', theme),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 54,
                child: FilledButton.icon(onPressed: _showEdit, icon: const Icon(Icons.edit),
                  label: const Text('ویرایش پروفایل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, height: 54,
                child: OutlinedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('خروج از حساب', style: TextStyle(fontSize: 16, color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _infoCard(String label, String value, ThemeData theme) {
    return Padding(padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Container(width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
          child: Text(value, style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface))),
      ]));
  }
}
