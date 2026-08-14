import 'package:flutter/material.dart';

class CallEntry {
  final String name;
  final String time;
  final bool outgoing;
  final bool video;
  final bool missed;

  const CallEntry({
    required this.name,
    required this.time,
    this.outgoing = false,
    this.video = false,
    this.missed = false,
  });
}

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calls = const [
      CallEntry(name: 'علی احمدی', time: 'امروز ۱۰:۳۰', outgoing: true, video: false),
      CallEntry(name: 'مریم رضایی', time: 'دیروز ۱۴:۲۰', outgoing: false, video: true, missed: true),
      CallEntry(name: 'حسین کریمی', time: '۲ روز پیش', outgoing: true, video: true),
      CallEntry(name: 'فاطمه نوری', time: '۳ روز پیش', outgoing: false, video: false, missed: true),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: ListView.builder(
          itemCount: calls.length,
          itemBuilder: (ctx, i) {
            final call = calls[i];
            return ListTile(
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary,
                child: Text(call.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              ),
              title: Text(call.name, style: TextStyle(fontWeight: FontWeight.bold, color: call.missed ? Colors.red : null)),
              subtitle: Row(
                children: [
                  Icon(call.outgoing ? Icons.call_made : Icons.call_received, size: 16, color: call.missed ? Colors.red : theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(call.time, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              trailing: IconButton(
                icon: Icon(call.video ? Icons.videocam : Icons.call, color: theme.colorScheme.primary),
                onPressed: () {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('تماس به‌زودی!')));
                },
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add_call),
        ),
      ),
    );
  }
}
