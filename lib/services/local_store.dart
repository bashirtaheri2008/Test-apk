import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';

class LocalStore {
  static SharedPreferences? _prefs;
  static Future<void> init() async => _prefs = await SharedPreferences.getInstance();
  static SharedPreferences get _sp {
    if (_prefs == null) throw StateError('LocalStore not initialized');
    return _prefs!;
  }

  // ===== Messages =====
  static String _msgKey(String partnerId) => 'msgs_$partnerId';

  static List<Message> getMessages(String partnerId) {
    final raw = _sp.getString(_msgKey(partnerId));
    if (raw == null) return [];
    final list = json.decode(raw) as List;
    return list.map((e) => Message(
      id: e['id'] ?? '',
      text: e['text'] ?? '',
      senderId: e['senderId'] ?? '',
      senderName: e['senderName'] ?? '',
      timestamp: e['timestamp'] ?? 0,
      type: MessageType.values.firstWhere(
        (t) => t.name == (e['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      mediaURL: e['mediaURL'] ?? '',
      mediaCaption: e['mediaCaption'] ?? '',
      mediaDuration: e['mediaDuration'] ?? 0,
      forwardedFrom: e['forwardedFrom'] ?? '',
      isStarred: e['isStarred'] ?? false,
      isDeleted: e['isDeleted'] ?? false,
      replyToId: e['replyToId'] ?? '',
      replyToText: e['replyToText'] ?? '',
      replyToName: e['replyToName'] ?? '',
    )).toList();
  }

  static void saveMessage(String partnerId, Message msg) {
    final msgs = getMessages(partnerId);
    // Remove temp message with same id if exists
    msgs.removeWhere((m) => m.id == msg.id);
    msgs.add(msg);
    msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _sp.setString(_msgKey(partnerId), json.encode(msgs.map((m) => {
      'id': m.id,
      'text': m.text,
      'senderId': m.senderId,
      'senderName': m.senderName,
      'timestamp': m.timestamp,
      'type': m.type.name,
      'mediaURL': m.mediaURL,
      'mediaCaption': m.mediaCaption,
      'mediaDuration': m.mediaDuration,
      'forwardedFrom': m.forwardedFrom,
      'isStarred': m.isStarred,
      'isDeleted': m.isDeleted,
      'replyToId': m.replyToId,
      'replyToText': m.replyToText,
      'replyToName': m.replyToName,
    }).toList()));
    // Also update chat list
    _updateChatListEntry(partnerId, msg);
  }

  static void updateMessage(String partnerId, Message updated) {
    final msgs = getMessages(partnerId);
    final idx = msgs.indexWhere((m) => m.id == updated.id);
    if (idx >= 0) {
      msgs[idx] = updated;
      _sp.setString(_msgKey(partnerId), json.encode(msgs.map((m) => {
        'id': m.id, 'text': m.text, 'senderId': m.senderId, 'senderName': m.senderName,
        'timestamp': m.timestamp, 'type': m.type.name, 'mediaURL': m.mediaURL,
        'mediaCaption': m.mediaCaption, 'mediaDuration': m.mediaDuration,
        'forwardedFrom': m.forwardedFrom, 'isStarred': m.isStarred, 'isDeleted': m.isDeleted,
        'replyToId': m.replyToId, 'replyToText': m.replyToText, 'replyToName': m.replyToName,
      }).toList()));
    }
  }

  static void deleteMessage(String partnerId, String msgId) {
    final msgs = getMessages(partnerId);
    final idx = msgs.indexWhere((m) => m.id == msgId);
    if (idx >= 0) {
      msgs[idx].isDeleted = true;
      _sp.setString(_msgKey(partnerId), json.encode(msgs.map((m) => {
        'id': m.id, 'text': m.text, 'senderId': m.senderId, 'senderName': m.senderName,
        'timestamp': m.timestamp, 'type': m.type.name, 'mediaURL': m.mediaURL,
        'mediaCaption': m.mediaCaption, 'mediaDuration': m.mediaDuration,
        'forwardedFrom': m.forwardedFrom, 'isStarred': m.isStarred, 'isDeleted': m.isDeleted,
        'replyToId': m.replyToId, 'replyToText': m.replyToText, 'replyToName': m.replyToName,
      }).toList()));
    }
  }

  static void clearChat(String partnerId) {
    _sp.remove(_msgKey(partnerId));
    _removeChatFromList(partnerId);
  }

  // ===== Chat List =====
  static const _chatListKey = 'local_chat_list';

  static List<ChatItem> getChatList() {
    final raw = _sp.getString(_chatListKey);
    if (raw == null) return [];
    final list = json.decode(raw) as List;
    return list.map((e) => ChatItem(
      chatId: e['chatId'] ?? '',
      partnerId: e['partnerId'] ?? '',
      partnerName: e['partnerName'] ?? '',
      partnerPhoto: e['partnerPhoto'] ?? '',
      lastMessage: e['lastMessage'] ?? '',
      lastTimestamp: e['lastTimestamp'] ?? 0,
      unreadCount: e['unreadCount'] ?? 0,
      isPinned: e['isPinned'] ?? false,
      isMuted: e['isMuted'] ?? false,
    )).toList();
  }

  static void _updateChatListEntry(String partnerId, Message msg) {
    final chats = getChatList();
    final myUid = _sp.getString('uid') ?? '';
    final idx = chats.indexWhere((c) => c.partnerId == partnerId);
    
    final isMe = msg.senderId == myUid;
    final lastText = msg.isDeleted
      ? 'پیام حذف شد'
      : msg.type == MessageType.audio
        ? '🎤 پیام صوتی'
        : msg.type == MessageType.image
          ? '📷 تصویر'
          : msg.text;

    if (idx >= 0) {
      chats[idx].lastMessage = lastText;
      chats[idx].lastTimestamp = msg.timestamp;
      if (!isMe) chats[idx].unreadCount += 1;
    } else {
      chats.add(ChatItem(
        chatId: 'local_$partnerId',
        partnerId: partnerId,
        partnerName: partnerId,
        lastMessage: lastText,
        lastTimestamp: msg.timestamp,
        unreadCount: isMe ? 0 : 1,
      ));
    }
    
    chats.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.lastTimestamp.compareTo(a.lastTimestamp);
    });
    
    _sp.setString(_chatListKey, json.encode(chats.map((c) => {
      'chatId': c.chatId, 'partnerId': c.partnerId, 'partnerName': c.partnerName,
      'partnerPhoto': c.partnerPhoto, 'lastMessage': c.lastMessage,
      'lastTimestamp': c.lastTimestamp, 'unreadCount': c.unreadCount,
      'isPinned': c.isPinned, 'isMuted': c.isMuted,
    }).toList()));
  }

  static void updateChatItem(ChatItem item) {
    final chats = getChatList();
    final idx = chats.indexWhere((c) => c.partnerId == item.partnerId);
    if (idx >= 0) {
      chats[idx] = item;
    } else {
      chats.add(item);
    }
    _sp.setString(_chatListKey, json.encode(chats.map((c) => {
      'chatId': c.chatId, 'partnerId': c.partnerId, 'partnerName': c.partnerName,
      'partnerPhoto': c.partnerPhoto, 'lastMessage': c.lastMessage,
      'lastTimestamp': c.lastTimestamp, 'unreadCount': c.unreadCount,
      'isPinned': c.isPinned, 'isMuted': c.isMuted,
    }).toList()));
  }

  static void markAsRead(String partnerId) {
    final chats = getChatList();
    final idx = chats.indexWhere((c) => c.partnerId == partnerId);
    if (idx >= 0) {
      chats[idx].unreadCount = 0;
      _sp.setString(_chatListKey, json.encode(chats.map((c) => {
        'chatId': c.chatId, 'partnerId': c.partnerId, 'partnerName': c.partnerName,
        'partnerPhoto': c.partnerPhoto, 'lastMessage': c.lastMessage,
        'lastTimestamp': c.lastTimestamp, 'unreadCount': c.unreadCount,
        'isPinned': c.isPinned, 'isMuted': c.isMuted,
      }).toList()));
    }
  }

  static void _removeChatFromList(String partnerId) {
    final chats = getChatList();
    chats.removeWhere((c) => c.partnerId == partnerId);
    _sp.setString(_chatListKey, json.encode(chats.map((c) => {
      'chatId': c.chatId, 'partnerId': c.partnerId, 'partnerName': c.partnerName,
      'partnerPhoto': c.partnerPhoto, 'lastMessage': c.lastMessage,
      'lastTimestamp': c.lastTimestamp, 'unreadCount': c.unreadCount,
      'isPinned': c.isPinned, 'isMuted': c.isMuted,
    }).toList()));
  }

  // ===== Simulated incoming messages for testing =====
  static void simulateIncoming(String partnerId, String partnerName, String text) {
    final msg = Message(
      id: 'in_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      senderId: partnerId,
      senderName: partnerName,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      status: MessageStatus.delivered,
    );
    saveMessage(partnerId, msg);
  }
}
