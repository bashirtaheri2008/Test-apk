import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/api_service.dart';
import '../services/prefs_service.dart';
import '../services/local_store.dart';
import '../widgets/avatar.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatItem> _chats = [];
  List<ChatItem> _filtered = [];
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  String _myUid = '';
  String _myName = '';

  @override
  void initState() {
    super.initState();
    _myUid = PrefsService.uid;
    _myName = PrefsService.name;
    _loadChats();
  }

  void _loadChats() {
    final chats = LocalStore.getChatList();
    chats.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.lastTimestamp.compareTo(a.lastTimestamp);
    });
    setState(() {
      _chats = chats;
      _filtered = chats;
    });
  }

  void _filter(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _chats
          : _chats.where((c) => c.partnerName.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  void _newChat() {
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('گفتگوی جدید'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('شماره تلفن مخاطب را وارد کنید', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Text('+93', style: TextStyle(fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '700123456',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                final phone = phoneCtrl.text.trim();
                if (phone.length != 9) {
                  _snack('شماره نامعتبر است');
                  return;
                }
                final partnerId = '93$phone';
                final partnerName = '+93 $phone';
                // Create local chat entry
                LocalStore.updateChatItem(ChatItem(
                  chatId: 'local_$partnerId',
                  partnerId: partnerId,
                  partnerName: partnerName,
                  lastMessage: '',
                  lastTimestamp: DateTime.now().millisecondsSinceEpoch,
                ));
                _loadChats();
                if (mounted) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatScreen(partnerId: partnerId, partnerName: partnerName),
                  )).then((_) => _loadChats());
                }
              },
              child: const Text('افزودن'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          if (_searching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'جستجوی مکالمه…',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _searching = false;
                        _searchCtrl.clear();
                        _filter('');
                      });
                    },
                  ),
                ),
                onChanged: _filter,
              ),
            ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 80, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('هیچ مکالمه‌ای وجود ندارد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 6),
                        Text('گفتگو را شروع کنید', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6))),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final chat = _filtered[i];
                      return Dismissible(
                        key: ValueKey(chat.chatId),
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.push_pin, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            setState(() => chat.isPinned = !chat.isPinned);
                            LocalStore.updateChatItem(chat);
                            return false;
                          }
                          LocalStore.clearChat(chat.partnerId);
                          _loadChats();
                          return true;
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Avatar(name: chat.partnerName, photoUrl: chat.partnerPhoto, showOnline: chat.isOnline),
                          title: Row(
                            children: [
                              if (chat.isPinned)
                                const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.push_pin, size: 16, color: Colors.grey)),
                              Expanded(
                                child: Text(
                                  chat.partnerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (chat.isMuted)
                                const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.volume_off, size: 16, color: Colors.grey)),
                              Text(
                                formatChatTime(chat.lastTimestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: chat.unreadCount > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat.lastMessage.isNotEmpty ? chat.lastMessage : 'شروع گفتگو…',
                                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (chat.unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(11)),
                                  child: Text(
                                    chat.unreadCount.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            LocalStore.markAsRead(chat.partnerId);
                            Navigator.push(ctx, MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                partnerId: chat.partnerId,
                                partnerName: chat.partnerName,
                                partnerPhoto: chat.partnerPhoto,
                              ),
                            )).then((_) => _loadChats());
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!_searching)
            FloatingActionButton(
              mini: true,
              heroTag: 'search',
              onPressed: () => setState(() => _searching = true),
              child: const Icon(Icons.search),
            ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _newChat,
            heroTag: 'newchat',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
