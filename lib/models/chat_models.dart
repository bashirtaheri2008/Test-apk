import 'dart:math';

class User {
  final String uid;
  String name;
  String phone;
  String bio;
  String photoURL;
  bool verified;
  bool isOnline;
  int lastSeen;

  User({
    required this.uid,
    this.name = '',
    this.phone = '',
    this.bio = '',
    this.photoURL = '',
    this.verified = false,
    this.isOnline = false,
    this.lastSeen = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        uid: json['uid'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        bio: json['bio'] ?? '',
        photoURL: json['photoURL'] ?? '',
        verified: json['verified'] ?? false,
        isOnline: json['isOnline'] ?? false,
        lastSeen: int.tryParse(json['lastSeen']?.toString() ?? '0') ?? 0,
      );
}

enum MessageStatus { sending, sent, delivered, read }
enum MessageType { text, image, video, audio, document, contact, location, sticker }
enum MessageReaction { none, like, love, laugh, wow, sad, angry, thumbsUp }

class Message {
  String id;
  String text;
  String senderId;
  String senderName;
  int timestamp;
  MessageType type;
  String mediaURL;
  String mediaCaption;
  int mediaDuration;
  MessageStatus status;
  MessageReaction reaction;
  String replyToId;
  String replyToText;
  String replyToName;
  String forwardedFrom;
  bool isStarred;
  bool isDeleted;
  String senderPhoto;

  Message({
    required this.id,
    this.text = '',
    this.senderId = '',
    this.senderName = '',
    this.timestamp = 0,
    this.type = MessageType.text,
    this.mediaURL = '',
    this.mediaCaption = '',
    this.mediaDuration = 0,
    this.status = MessageStatus.sent,
    this.reaction = MessageReaction.none,
    this.replyToId = '',
    this.replyToText = '',
    this.replyToName = '',
    this.forwardedFrom = '',
    this.isStarred = false,
    this.isDeleted = false,
    this.senderPhoto = '',
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] ?? '',
        text: json['text'] ?? '',
        senderId: json['senderId'] ?? '',
        senderName: json['senderName'] ?? '',
        timestamp: int.tryParse(json['timestamp']?.toString() ?? '0') ?? 0,
        type: MessageType.values.firstWhere(
          (e) => e.name == (json['type'] ?? 'text'),
          orElse: () => MessageType.text,
        ),
        mediaURL: json['mediaURL'] ?? '',
        mediaCaption: json['mediaCaption'] ?? '',
        mediaDuration: int.tryParse(json['mediaDuration']?.toString() ?? '0') ?? 0,
        forwardedFrom: json['forwardedFrom'] ?? '',
        isStarred: json['isStarred'] ?? false,
        isDeleted: json['isDeleted'] ?? false,
      );
}

class ChatItem {
  String chatId;
  String partnerId;
  String partnerName;
  String partnerPhoto;
  String partnerBio;
  String lastMessage;
  int lastTimestamp;
  int unreadCount;
  bool isOnline;
  bool isPinned;
  bool isMuted;
  bool isGroup;
  String groupIcon;
  List<String> groupMembers;
  String lastSenderName;
  bool isTyping;
  String lastMessageType;

  ChatItem({
    required this.chatId,
    required this.partnerId,
    this.partnerName = '',
    this.partnerPhoto = '',
    this.partnerBio = '',
    this.lastMessage = '',
    this.lastTimestamp = 0,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isPinned = false,
    this.isMuted = false,
    this.isGroup = false,
    this.groupIcon = '',
    this.groupMembers = const [],
    this.lastSenderName = '',
    this.isTyping = false,
    this.lastMessageType = 'text',
  });
}

class StatusItem {
  String id;
  String userId;
  String userName;
  String userPhoto;
  String content;
  String bg;
  String type;
  int timestamp;
  bool viewed;
  String caption;

  StatusItem({
    required this.id,
    this.userId = '',
    this.userName = '',
    this.userPhoto = '',
    this.content = '',
    this.bg = '',
    this.type = 'text',
    this.timestamp = 0,
    this.viewed = false,
    this.caption = '',
  });
}

class CallItem {
  String id;
  String userId;
  String userName;
  String userPhoto;
  int timestamp;
  bool isOutgoing;
  bool isMissed;
  bool isVideo;

  CallItem({
    required this.id,
    this.userId = '',
    this.userName = '',
    this.userPhoto = '',
    this.timestamp = 0,
    this.isOutgoing = false,
    this.isMissed = false,
    this.isVideo = false,
  });
}

class GroupChat {
  String groupId;
  String name;
  String icon;
  String description;
  List<String> members;
  List<String> adminIds;
  int createdAt;
  String createdBy;

  GroupChat({
    required this.groupId,
    this.name = '',
    this.icon = '',
    this.description = '',
    this.members = const [],
    this.adminIds = const [],
    this.createdAt = 0,
    this.createdBy = '',
  });
}

String generateOtp() {
  final rng = Random();
  return List.generate(6, (_) => rng.nextInt(10).toString()).join();
}

String chatId(String a, String b) {
  final sorted = [a, b]..sort();
  return '${sorted[0]}_${sorted[1]}';
}

String formatTime(int ts) {
  if (ts == 0) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(ts);
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String formatChatTime(int ts) {
  if (ts == 0) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(ts);
  final now = DateTime.now();
  final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
  if (isToday) return formatTime(ts);
  final diff = now.difference(dt).inDays;
  if (diff == 1) return 'دیروز';
  if (diff < 7) {
    const days = ['یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه'];
    return days[dt.weekday - 1];
  }
  return '${dt.day}/${dt.month}';
}

String formatLastSeen(int lastSeen) {
  if (lastSeen == 0) return 'اخیراً';
  final diff = DateTime.now().millisecondsSinceEpoch - lastSeen;
  final mins = diff ~/ 60000;
  if (mins < 1) return 'هم‌اکنون آنلاین';
  if (mins < 60) return '$mins دقیقه پیش';
  final hours = mins ~/ 60;
  if (hours < 24) return '$hours ساعت پیش';
  final days = hours ~/ 24;
  return '$days روز پیش';
}

String formatDuration(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

String getInitials(String name) {
  if (name.isEmpty) return '؟';
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name[0].toUpperCase();
}

String getReactionEmoji(MessageReaction r) {
  switch (r) {
    case MessageReaction.like: return '👍';
    case MessageReaction.love: return '❤️';
    case MessageReaction.laugh: return '😂';
    case MessageReaction.wow: return '😮';
    case MessageReaction.sad: return '😢';
    case MessageReaction.angry: return '😠';
    case MessageReaction.thumbsUp: return '👏';
    default: return '';
  }
}

List<String> getReactionEmojiList() => ['👍', '❤️', '😂', '😮', '😢', '😠', '👏'];
