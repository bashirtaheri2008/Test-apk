import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/prefs_service.dart';
import '../services/local_store.dart';
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
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Message> _messages = [];
  String _myUid = '';
  String _myName = '';
  bool _showSend = false;
  bool _showEmoji = false;
  bool _showAttach = false;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  Message? _replyTo;

  @override
  void initState() {
    super.initState();
    _myUid = PrefsService.uid;
    _myName = PrefsService.name;
    _loadMessages();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _loadMessages() {
    final msgs = LocalStore.getMessages(widget.partnerId);
    setState(() => _messages = msgs);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMsg() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() {
      _showSend = false;
      _replyTo = null;
    });

    final msg = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      senderId: _myUid,
      senderName: _myName,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      status: MessageStatus.sent,
      replyToId: _replyTo?.id ?? '',
      replyToText: _replyTo?.text ?? '',
      replyToName: _replyTo?.senderName ?? '',
    );

    LocalStore.saveMessage(widget.partnerId, msg);
    _loadMessages();

    // Simulate auto-reply after 2 seconds for testing
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        final replies = [
          'سلام! چطوری؟',
          'خوبم تو چطوری؟',
          'بله دقیقاً',
          'باشه حتماً',
          'مرسی 🙏',
          'بعداً صحبت می‌کنیم',
          '👍',
          'کارت درسته',
        ];
        final reply = replies[DateTime.now().millisecond % replies.length];
        final incoming = Message(
          id: 'in_${DateTime.now().millisecondsSinceEpoch}',
          text: reply,
          senderId: widget.partnerId,
          senderName: widget.partnerName,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          status: MessageStatus.delivered,
        );
        LocalStore.saveMessage(widget.partnerId, incoming);
        _loadMessages();
      }
    });
  }

  void _startRecording() {
    setState(() => _isRecording = true);
    _recordSeconds = 0;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _recordSeconds++);
    });
  }

  void _stopRecording() {
    _recordTimer?.cancel();
    setState(() => _isRecording = false);
    final msg = Message(
      id: 'voice_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _myUid,
      senderName: _myName,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      type: MessageType.audio,
      mediaDuration: _recordSeconds,
      status: MessageStatus.sent,
    );
    LocalStore.saveMessage(widget.partnerId, msg);
    _loadMessages();
  }

  void _showMsgActions(Message msg) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('پاسخ'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _replyTo = msg);
                },
              ),
              ListTile(
                leading: const Icon(Icons.shortcut),
                title: const Text('فوروارد'),
                onTap: () {
                  Navigator.pop(context);
                  _snack('فوروارد به‌زودی');
                },
              ),
              ListTile(
                leading: Icon(msg.isStarred ? Icons.star : Icons.star_border),
                title: Text(msg.isStarred ? 'حذف از ستاره‌دار' : 'ستاره‌دار'),
                onTap: () {
                  Navigator.pop(context);
                  msg.isStarred = !msg.isStarred;
                  LocalStore.updateMessage(widget.partnerId, msg);
                  _loadMessages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('کپی متن'),
                onTap: () {
                  Navigator.pop(context);
                  _snack('کپی شد');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('حذف پیام', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  LocalStore.deleteMessage(widget.partnerId, msg.id);
                  _loadMessages();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReactions(Message msg) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.ltr,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int idx = 0; idx < getReactionEmojiList().length; idx++)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      final reactions = MessageReaction.values;
                      if (idx + 1 < reactions.length) {
                        msg.reaction = msg.reaction == reactions[idx + 1]
                            ? MessageReaction.none
                            : reactions[idx + 1];
                        LocalStore.updateMessage(widget.partnerId, msg);
                        _loadMessages();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      child: Text(getReactionEmojiList()[idx], style: const TextStyle(fontSize: 28)),
                    ),
                  ),
              ],
            ),
          ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                Avatar(name: widget.partnerName, photoUrl: widget.partnerPhoto, radius: 20, showOnline: true),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.partnerName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    Text('آنلاین', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () => _snack('تماس تصویری به‌زودی!')),
            IconButton(icon: const Icon(Icons.call_outlined), onPressed: () => _snack('تماس صوتی به‌زودی!')),
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'search', child: Text('جستجو')),
                const PopupMenuItem(value: 'mute', child: Text('بی‌صدا')),
                const PopupMenuItem(value: 'clear', child: Text('پاک‌سازی گفتگو')),
              ],
              onSelected: (v) {
                if (v == 'clear') {
                  LocalStore.clearChat(widget.partnerId);
                  _loadMessages();
                  _snack('گفتگو پاک شد');
                } else {
                  _snack('این قابلیت به‌زودی');
                }
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(color: isDark ? const Color(0xFF0b141a) : const Color(0xFFe7e0d4)),
          child: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text('شروع گفتگو', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[i];
                          return MessageBubble(
                            message: msg,
                            isMe: msg.senderId == _myUid,
                            onLongPress: () => _showMsgActions(msg),
                            onReact: () => _showReactions(msg),
                            onReply: () => setState(() => _replyTo = msg),
                          );
                        },
                      ),
              ),
              if (_replyTo != null)
                Container(
                  color: isDark ? const Color(0xFF202c33) : const Color(0xFFf0f0f0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Container(width: 3, height: 36, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_replyTo!.senderName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                            Text(_replyTo!.text, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _replyTo = null)),
                    ],
                  ),
                ),
              if (_showAttach)
                Container(
                  color: isDark ? const Color(0xFF202c33) : const Color(0xFFf0f0f0),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _attachItem(Icons.image, 'تصویر', Colors.purple, () { setState(() => _showAttach = false); _snack('ارسال تصویر به‌زودی'); }),
                      _attachItem(Icons.camera_alt, 'دوربین', Colors.red, () { setState(() => _showAttach = false); _snack('دوربین به‌زودی'); }),
                      _attachItem(Icons.insert_drive_file, 'فایل', Colors.blue, () { setState(() => _showAttach = false); _snack('ارسال فایل به‌زودی'); }),
                      _attachItem(Icons.location_on, 'موقعیت', Colors.green, () { setState(() => _showAttach = false); _snack('ارسال موقعیت به‌زودی'); }),
                    ],
                  ),
                ),
              SafeArea(
                child: Container(
                  color: isDark ? const Color(0xFF202c33) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: _isRecording
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2a3942) : const Color(0xFFf0f0f0),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.mic, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(child: Text(formatDuration(_recordSeconds), style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface))),
                              GestureDetector(
                                onTap: _stopRecording,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            IconButton(
                              icon: Icon(_showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined, color: theme.colorScheme.onSurfaceVariant),
                              onPressed: () => setState(() => _showEmoji = !_showEmoji),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _msgCtrl,
                                maxLines: 5,
                                minLines: 1,
                                style: TextStyle(color: theme.colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: 'پیام خود را بنویسید…',
                                  hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF2a3942) : const Color(0xFFf0f5f7),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  prefixIcon: IconButton(
                                    icon: const Icon(Icons.attach_file),
                                    onPressed: () => setState(() => _showAttach = !_showAttach),
                                  ),
                                ),
                                onChanged: (val) => setState(() => _showSend = val.trim().isNotEmpty),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                              child: IconButton(
                                icon: Icon(_showSend ? Icons.send : Icons.mic, color: Colors.white, size: 20),
                                onPressed: _showSend ? _sendMsg : _startRecording,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_showEmoji && !_isRecording)
                Container(
                  height: 200,
                  color: isDark ? const Color(0xFF202c33) : const Color(0xFFf0f0f0),
                  child: GridView.count(
                    crossAxisCount: 7,
                    padding: const EdgeInsets.all(8),
                    children: ['😀','😂','😍','🥰','😎','😭','😡','👍','👎','❤️','🔥','🎉','👏','🙏','💯','😴','🤔','😏','😢','🤯','😱','💀','🤡','👋','👌','💪','🫶','🥺'].map((e) =>
                      GestureDetector(
                        onTap: () {
                          _msgCtrl.text += e;
                          setState(() => _showSend = true);
                        },
                        child: Center(child: Text(e, style: const TextStyle(fontSize: 28))),
                      ),
                    ).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
