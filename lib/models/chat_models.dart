import 'dart:math';

class User {
  final String uid;
  final String name;
  final String phone;
  final String bio;
  final String photoURL;
  final bool verified;

  User({
    required this.uid,
    this.name = '',
    this.phone = '',
    this.bio = '',
    this.photoURL = '',
    this.verified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        uid: json['uid'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        bio: json['bio'] ?? '',
        photoURL: json['photoURL'] ?? '',
        verified: json['verified'] ?? false,
      );
}

class Message {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final int timestamp;
  final String type;
  final String imageURL;
  final MessageStatus status;

  Message({
    required this.id,
    this.text = '',
    this.senderId = '',
    this.senderName = '',
    this.timestamp = 0,
    this.type = 'text',
    this.imageURL = '',
    this.status = MessageStatus.sent,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] ?? '',
        text: json['text'] ?? '',
        senderId: json['senderId'] ?? '',
        senderName: json['senderName'] ?? '',
        timestamp: int.tryParse(json['timestamp']?.toString() ?? '0') ?? 0,
        type: json['type'] ?? 'text',
        imageURL: json['imageURL'] ?? '',
      );
}

enum MessageStatus { sending, sent, delivered, read }

class ChatItem {
  final String chatId;
  final String partnerId;
  final String partnerName;
  final String partnerPhoto;
  final String lastMessage;
  final int lastTimestamp;
  final int unreadCount;
  final bool isOnline;

  ChatItem({
    required this.chatId,
    required this.partnerId,
    this.partnerName = '',
    this.partnerPhoto = '',
    this.lastMessage = '',
    this.lastTimestamp = 0,
    this.unreadCount = 0,
    this.isOnline = false,
  });
}

/// Generate a random OTP for testing (server is offline)
String generateOtp() {
  final rng = Random();
  return List.generate(6, (_) => rng.nextInt(10).toString()).join();
}

/// Chat ID helper
String chatId(String a, String b) {
  final sorted = [a, b]..sort();
  return '${sorted[0]}_${sorted[1]}';
}

/// Format timestamp to HH:mm
String formatTime(int ts) {
  if (ts == 0) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(ts);
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// Format timestamp for chat list — show "Yesterday" or time
String formatChatTime(int ts) {
  if (ts == 0) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(ts);
  final now = DateTime.now();
  final isToday = dt.year == now.year &&
      dt.month == now.month &&
      dt.day == now.day;
  if (isToday) return formatTime(ts);
  final diff = now.difference(dt).inDays;
  if (diff == 1) return 'دیروز';
  if (diff < 7) {
    const days = ['یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه'];
    return days[dt.weekday - 1];
  }
  return '${dt.day}/${dt.month}';
}

/// Get initials from a name
String getInitials(String name) {
  if (name.isEmpty) return '؟';
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name[0].toUpperCase();
}
