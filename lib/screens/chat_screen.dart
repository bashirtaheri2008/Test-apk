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

  const ChatScreen({super.key, required this.partnerId, required this.partnerName, this.partnerPhoto = ''});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Message> _messages = [];
  bool _loading = true;
  String _myUid = '';
  String _myName = '';
  Timer? _pollTimer;
  bool _showSend = false;
  bool _showEmoji = false;
  bool _showAttach = false;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  // Reply
  Message? _replyTo;
  // Selected message for actions
  Message? _selectedMsg;
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    _myUid = PrefsService.uid;
    _myName = PrefsService.name;
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _recordTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ApiService.getMessages(_myUid, widget.partnerId);
      setState(() { _messages = msgs; _loading = false; });
      _scrollToBottom();
    } catch (e) { dev.log('Error: $e'); setState(() => _loading = false); }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendMsg() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() { _showSend = false; _replyTo = null; });
    final temp = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      text: text, senderId: _myUid, senderName: _myName,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      status: MessageStatus.sending,
      replyToId: _replyTo?.id ?? '',
      replyToText: _replyTo?.text ?? '',
      replyToName: _replyTo?.senderName ?? '',
    );
    setState(() => _messages.add(temp));
    _scrollToBottom();
    final ok = await ApiService.sendMessage(_myUid, widget.partnerId, text, _myName,
      replyToId: _replyTo?.id ?? '', replyToText: _replyTo?.text ?? '', replyToName: _replyTo?.senderName ?? '');
    if (ok) _loadMessages();
    else if (mounted) _snack('خطا در ارسال پیام');
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
    // Simulate sending voice message
    final temp = Message(
      id: 'voice_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _myUid, senderName: _myName,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      type: MessageType.audio, mediaDuration: _recordSeconds,
      status: MessageStatus.sent,
    );
    setState(() => _messages.add(temp));
    _scrollToBottom();
  }

  void _showMsgActions(Message msg) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.reply), title: const Text('پاسخ'), onTap: () { Navigator.pop(context); setState(() => _replyTo = msg); }),
          ListTile(leading: const Icon(Icons.shortcut), title: const Text('فوروارد'), onTap: () { Navigator.pop(context); _snack('فوروارد به‌زودی'); }),
          ListTile(leading: Icon(msg.isStarred ? Icons.star : Icons.star_border), title: Text(msg.isStarred ? 'حذف از ستاره‌دار' : 'ستاره‌دار'),
            onTap: () { Navigator.pop(context); setState(() => msg.isStarred = !msg.isStarred); }),
          ListTile(leading: const Icon(Icons.copy), title: const Text('کپی متن'), onTap: () { Navigator.pop(context); _snack('کپی شد'); }),
          ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('حذف پیام', style: TextStyle(color: Colors.red)),
            onTap: () { Navigator.pop(context); setState(() { msg.isDeleted = true; }); }),
        ])),
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
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              for (final emoji in getReactionEmojiList())
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      final reactions = MessageReaction.values;
                      final idx = getReactionEmojiList().indexOf(emoji);
                      if (idx >= 0 && idx < reactions.length - 1) {
                        msg.reaction = msg.reaction == reactions[idx + 1] ? MessageReaction.none : reactions[idx + 1];
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.surfaceContainerHighest),
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
            ]),
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
            child: Row(children: [
              Avatar(name: widget.partnerName, photoUrl: widget.partnerPhoto, radius: 20, showOnline: true),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.partnerName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text('آنلاین', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
              ]),
            ]),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () => _snack('تماس تصویری به‌زودی!')),
            IconButton(icon: const Icon(Icons.call_outlined), onPressed: () => _snack('تماس صوتی به‌زودی!')),
            PopupMenuButton(itemBuilder: (_) => [
              const PopupMenuItem(value: 'search', child: Text('جستجو')),
              const PopupMenuItem(value: 'mute', child: Text('بی‌صدا')),
              const PopupMenuItem(value: 'wallpaper', child: Text('پس‌زمینه')),
              const PopupMenuItem(value: 'clear', child: Text('پاک‌سازی گفتگو')),
            ], onSelected: (v) => _snack('این قابلیت به‌زودی')),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(color: isDark ? const Color(0xFF0b141a) : const Color(0xFFe7e0d4)),
          child: Column(children: [
            // Messages
            Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.chat_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text('شروع گفتگو', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  ]))
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
                  )),
            // Reply bar
            if (_replyTo != null)
              Container(
                color: isDark ? const Color(0xFF202c33) : const Color(0xFFf0f0f0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(children: [
                  Container(width: 3, height: 36, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_replyTo!.senderName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    Text(_replyTo!.text, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _replyTo = null)),
                ]),
              ),
            // Attachment panel
            if (_showAttach)
              Container(
                color: isDark ? const Color(0xFF202c33) : const Color(0xFFf0f0f0),
                padding: const EdgeInsets.all(16),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _attachItem(Icons.image, 'تصویر', Colors.purple, () { setState(() => _showAttach = false); _snack('ارسال تصویر به‌زودی'); }),
                  _attachItem(Icons.camera_alt, 'دوربین', Colors.red, () { setState(() => _showAttach = false); _snack('دوربین به‌زودی'); }),
                  _attachItem(Icons.insert_drive_file, 'فایل', Colors.blue, () { setState(() => _showAttach = false); _snack('ارسال فایل به‌زودی'); }),
                  _attachItem(Icons.location_on, 'موقعیت', Colors.green, () { setState(() => _showAttach = false); _snack('ارسال موقعیت به‌زودی'); }),
                  _attachItem(Icons.person, 'مخاطب', Colors.orange, () { setState(() => _showAttach = false); _snack('ارسال مخاطب به‌زودی'); }),
                ]),
              ),
            // Input bar
            SafeArea(child: Container(
              color: isDark ? const Color(0xFF202c33) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: _isRecording
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF2a3942) : const Color(0xFFf0f0f0), borderRadius: BorderRadius.circular(24)),
                    child: Row(children: [
                      const Icon(Icons.mic, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(formatDuration(_recordSeconds), style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface))),
                      GestureDetector(onTap: _stopRecording, child: Container(width: 44, height: 44, decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.send, color: Colors.white, size: 20))),
                    ]),
                  )
                : Row(children: [
                    IconButton(icon: Icon(_showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined, color: theme.colorScheme.onSurfaceVariant),
                      onPressed: () => setState(() => _showEmoji = !_showEmoji)),
                    Expanded(child: TextField(
                      controller: _msgCtrl, maxLines: 5, minLines: 1,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'پیام خود را بنویسید…',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        filled: true, fillColor: isDark ? const Color(0xFF2a3942) : const Color(0xFFf0f5f7),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        prefixIcon: IconButton(icon: const Icon(Icons.attach_file), onPressed: () => setState(() => _showAttach = !_showAttach)),
                      ),
                      onChanged: (val) => setState(() => _showSend = val.trim().isNotEmpty),
                    )),
                    const SizedBox(width: 4),
                    Container(width: 48, height: 48, decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                      child: IconButton(
                        icon: Icon(_showSend ? Icons.send : Icons.mic, color: Colors.white, size: 20),
                        onPressed: _showSend ? _sendMsg : _startRecording,
                      )),
                  ]),
            )),
            // Emoji panel placeholder
            if (_showEmoji && !_isRecording)
              Container(height: 200, color: isDark ? const Color(0xFF202c33) : const Color(0xFFf0f0f0),
                child: GridView.count(crossAxisCount: 7, padding: const EdgeInsets.all(8),
                  children: ['😀','😂','😍','🥰','😎','😭','😡','👍','👎','❤️','🔥','🎉','👏','🙏','💯','😴','🤔','😏','😢','🤯','😱','💀','🤡','👋','👌','💪','🫶','🥺'].map((e) =>
                    GestureDetector(onTap: () { _msgCtrl.text += e; setState(() => _showSend = true); },
                      child: Center(child: Text(e, style: const TextStyle(fontSize: 28))))).toList())),
          ]),
        ),
      ),
    );
  }

  Widget _attachItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 50, height: 50, decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 24)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]));
  }
}
