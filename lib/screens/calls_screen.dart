import 'package:flutter/material.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calls = [
      {'name': 'علی احمدی', 'time': 'امروز ۱۰:۳۰', 'outgoing': true, 'video': false},
      {'name': 'مریم رضایی', 'time': 'دیروز ۱۴:۲۰', 'outgoing': false, 'video': true, 'missed': true},
      {'name': 'حسین کریمی', 'time': '۲ روز پیش', 'outgoing': true, 'video': true},
      {'name': 'فاطمه نوری', 'time': '۳ روز پیش', 'outgoing': false, 'video': false, 'missed': true},
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: ListView.builder(
          itemCount: calls.length,
          itemBuilder: (ctx, i) {
            final call = calls[i];
            final missed = call['missed'] == true;
            final outgoing = call['outgoing'] == true;
            final video = call['video'] == true;
            return ListTile(
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary,
                child: Text(call['name']![0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              ),
              title: Text(call['name']!, style: TextStyle(fontWeight: FontWeight.bold, color: missed ? Colors.red : null)),
              subtitle: Row(children: [
                Icon(outgoing ? Icons.call_made : Icons.call_received, size: 16, color: missed ? Colors.red : theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(call['time']!, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ]),
              trailing: IconButton(
                icon: Icon(video ? Icons.videocam : Icons.call, color: theme.colorScheme.primary),
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
