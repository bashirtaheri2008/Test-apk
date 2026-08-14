import 'package:flutter/material.dart';
import '../services/prefs_service.dart';
import '../widgets/avatar.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: ListView(
          children: [
            // My status
            ListTile(
              leading: Stack(children: [
                Avatar(name: PrefsService.name, photoUrl: PrefsService.photoURL, radius: 28, showRing: true, ringViewed: false),
                Positioned(bottom: 0, right: 0, child: Container(width: 20, height: 20,
                  decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle, border: Border.all(color: theme.scaffoldBackgroundColor, width: 2)),
                  child: const Icon(Icons.add, color: Colors.white, size: 12))),
              ]),
              title: const Text('وضعیت من', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('برای افزودن وضعیت ضربه بزنید'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('افزودن وضعیت به‌زودی!')));
              },
            ),
            const Divider(),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('اخیراً', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary))),
            // Sample statuses
            _statusTile(context, 'علی احمدی', '', '5 دقیقه پیش', false),
            _statusTile(context, 'مریم رضایی', '', '15 دقیقه پیش', false),
            _statusTile(context, 'حسین کریمی', '', '1 ساعت پیش', true),
          ],
        ),
        floatingActionButton: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          FloatingActionButton(mini: true, heroTag: 'text_status',
            onPressed: () {},
            child: const Icon(Icons.edit)),
          const SizedBox(height: 8),
          FloatingActionButton(heroTag: 'camera_status',
            onPressed: () {},
            child: const Icon(Icons.camera_alt)),
        ]),
      ),
    );
  }

  Widget _statusTile(BuildContext ctx, String name, String photo, String time, bool viewed) {
    return ListTile(
      leading: Avatar(name: name, photoUrl: photo, radius: 28, showRing: true, ringViewed: viewed),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(time),
      onTap: () {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('مشاهده وضعیت به‌زودی!')));
      },
    );
  }
}
