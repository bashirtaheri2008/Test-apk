import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/api_service.dart';
import '../services/prefs_service.dart';
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
  List<ChatItem> _filteredChats = [];
  bool _loading = true;
  bool _searching = false;
  final _searchController = TextEditingController();
  String _myUid = '';
  String _myName = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() {
    setState(() {
      _myUid = PrefsService.uid;
      _myName = PrefsService.name;
    });
    _loadChats();
  }

  Future<void> _loadChats() async {
    if (_myUid.isEmpty) return;
    setState(() => _loading = true);
    try {
      final chats = await ApiService.getUserChats(_myUid);
      setState(() {
        _chats = chats;
        _filteredChats = chats;
        _loading = false;
      });
    } catch (e) {
      dev.log('Error loading chats: $e');
      setState(() => _loading = false);
    }
  }

  void _filter(String query) {
    setState(() {
      _filteredChats = query.isEmpty
          ? _chats
          : _chats.where((c) => c.partnerName.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  void _showAddContact() {
    final phoneController = TextEditingController();
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
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text('+93', style: TextStyle(fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '+93×××××××××',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
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
              onPressed: () async {
                Navigator.pop(context);
                final phone = phoneController.text.trim();
                if (phone.length != 9) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('شماره نامعتبر است')),
                  );
                  return;
                }
                final normalized = '+93$phone';
                final user = await ApiService.findUserByPhone(normalized);
                if (user != null) {
                  await ApiService.ensureChatExists(_myUid, user.uid, _myName);
                  _loadChats();
                  if (mounted) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        partnerId: user.uid,
                        partnerName: user.name.isNotEmpty ? user.name : normalized,
                        partnerPhoto: user.photoURL,
                      ),
                    ));
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('کاربر یافت نشد')),
                    );
                  }
                }
              },
              child: const Text('افزودن'),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('خروج'),
          content: const Text('آیا مطمئن هستید می‌خواهید خارج شوید؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                await PrefsService.logout();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                }
              },
              child: const Text('بله، خروج'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: _searching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'جستجوی مکالمه…',
                        border: InputBorder.none,
                      ),
                      onChanged: _filter,
                    )
                  : const Text('پیام‌ها', style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: Icon(_searching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      _searching = !_searching;
                      if (!_searching) {
                        _searchController.clear();
                        _filter('');
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                ),
                PopupMenuButton(
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'about', child: Text('درباره هم‌گب')),
                    const PopupMenuItem(value: 'logout', child: Text('خروج')),
                  ],
                  onSelected: (val) {
                    if (val == 'logout') _logout();
                    if (val == 'about') {
                      showDialog(
                        context: context,
                        builder: (_) => Directionality(
                          textDirection: TextDirection.rtl,
                          child: AlertDialog(
                            title: const Text('درباره هم‌گب'),
                            content: const Text('پیام‌رسان هم‌گب\nنسخه ۳.۰ (Flutter)\nارتباط امن، سریع و هوشمند'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('باشه')),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (_filteredChats.isEmpty)
              SliverFillRemaining(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 80, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('هیچ مکالمه‌ای وجود ندارد',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text('گفتگو را شروع کنید',
                        style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6))),
                  ],
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final chat = _filteredChats[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: Avatar(
                        name: chat.partnerName,
                        photoUrl: chat.partnerPhoto,
                        showOnline: chat.isOnline,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.partnerName.isNotEmpty ? chat.partnerName : chat.partnerId,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            formatChatTime(chat.lastTimestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: chat.unreadCount > 0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
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
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                chat.unreadCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(ctx, MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            partnerId: chat.partnerId,
                            partnerName: chat.partnerName,
                            partnerPhoto: chat.partnerPhoto,
                          ),
                        ));
                      },
                    );
                  },
                  childCount: _filteredChats.length,
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddContact,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
