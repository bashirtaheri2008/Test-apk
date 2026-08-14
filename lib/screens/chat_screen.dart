import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/api_service.dart';
import '../services/prefs_service.dart';
import '../widgets/avatar.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String partnerPhoto;

  const ChatScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    this.partnerPhoto = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _loading = true;
  String _myUid = '';
  String _myName = '';
  Timer? _pollTimer;
  bool _showSend = false;

  @override
  void initState() {
    super.initState();
    _myUid = PrefsService.uid;
    _myName = PrefsService.name;
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (_myUid.isEmpty) return;
    try {
      final msgs = await ApiService.getMessages(_myUid, widget.partnerId);
      setState(() {
        _messages = msgs;
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      dev.log('Error loading messages: $e');
      setState(() => _loading = false);
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    setState(() => _showSend = false);

    final tempMsg = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      senderId: _myUid,
      senderName: _myName,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      status: MessageStatus.sending,
    );
    setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    final success = await ApiService.sendMessage(_myUid, widget.partnerId, text, _myName);
    if (success) {
      _loadMessages();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در ارسال پیام')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              Avatar(name: widget.partnerName, photoUrl: widget.partnerPhoto, radius: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.partnerName,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  Text('آخرین بازدید اخیراً',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.call_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تماس صوتی به‌زودی!')),
                );
              },
            ),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a2332) : const Color(0xFFe7e0d4),
          ),
          child: Column(
            children: [
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_outlined,
                                    size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                                const SizedBox(height: 12),
                                Text('شروع گفتگو',
                                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            itemCount: _messages.length,
                            itemBuilder: (ctx, i) {
                              final msg = _messages[i];
                              return MessageBubble(message: msg, isMe: msg.senderId == _myUid);
                            },
                          ),
              ),
              SafeArea(
                child: Container(
                  color: isDark ? const Color(0xFF1e293b) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.emoji_emotions_outlined, color: theme.colorScheme.onSurfaceVariant),
                        onPressed: () {},
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: 4,
                          minLines: 1,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'پیام خود را بنویسید…',
                            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFf1f5f9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onChanged: (val) => setState(() => _showSend = val.trim().isNotEmpty),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.attach_file, color: theme.colorScheme.onSurfaceVariant),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ارسال فایل به‌زودی!')),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(_showSend ? Icons.send : Icons.mic, color: Colors.white, size: 20),
                          onPressed: _showSend ? _sendMessage : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ضبط صوت به‌زیدی!')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
