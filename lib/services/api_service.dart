import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';

class ApiService {
  static const String _projectId = 'web-rasa';
  static const String _base =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  static Future<User?> getUser(String uid) async {
    try {
      final res = await http.get(Uri.parse('$_base/users/$uid'));
      if (res.statusCode != 200) return null;
      final fields = json.decode(res.body)['fields'] ?? {};
      return User(
        uid: uid,
        name: _s(fields['name']),
        phone: _s(fields['phone']),
        bio: _s(fields['bio']),
        photoURL: _s(fields['photoURL']),
      );
    } catch (_) { return null; }
  }

  static Future<bool> createOrUpdateUser(String uid, String phone,
      [String name = 'کاربر هم‌گب', String bio = '', String photoURL = '']) async {
    try {
      final fields = {
        'phone': {'stringValue': phone},
        'name': {'stringValue': name},
        'bio': {'stringValue': bio},
        'photoURL': {'stringValue': photoURL},
        'verified': {'booleanValue': false},
      };
      final mask = 'updateMask.fieldPaths=phone&updateMask.fieldPaths=name&updateMask.fieldPaths=bio&updateMask.fieldPaths=photoURL&updateMask.fieldPaths=verified';
      final res = await http.patch(Uri.parse('$_base/users/$uid?$mask'),
          body: json.encode({'fields': fields}), headers: {'Content-Type': 'application/json'});
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<bool> updateUserProfile(String uid, String name, String bio, String photoURL) async {
    try {
      final fields = {'name': {'stringValue': name}, 'bio': {'stringValue': bio}, 'photoURL': {'stringValue': photoURL}};
      final mask = 'updateMask.fieldPaths=name&updateMask.fieldPaths=bio&updateMask.fieldPaths=photoURL';
      final res = await http.patch(Uri.parse('$_base/users/$uid?$mask'),
          body: json.encode({'fields': fields}), headers: {'Content-Type': 'application/json'});
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<List<Message>> getMessages(String uid, String partnerId) async {
    try {
      final cid = chatId(uid, partnerId);
      final res = await http.get(Uri.parse('$_base/chats/$cid/messages?orderBy=timestamp&pageSize=100'));
      if (res.statusCode != 200) return [];
      final docs = json.decode(res.body)['documents'] as List? ?? [];
      return docs.map((doc) {
        final f = doc['fields'] ?? {};
        return Message(
          id: doc['name'].toString().split('/').last,
          text: _s(f['text']),
          senderId: _s(f['senderId']),
          senderName: _s(f['senderName']),
          timestamp: int.tryParse(_s(f['timestamp'])) ?? 0,
          type: MessageType.values.firstWhere((e) => e.name == _s(f['type']), orElse: () => MessageType.text),
          mediaURL: _s(f['mediaURL']),
          mediaCaption: _s(f['mediaCaption']),
          forwardedFrom: _s(f['forwardedFrom']),
          isStarred: _b(f['isStarred']),
          isDeleted: _b(f['isDeleted']),
        );
      }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (_) { return []; }
  }

  static Future<bool> sendMessage(String uid, String partnerId, String text, String senderName,
      {String replyToId = '', String replyToText = '', String replyToName = '', String forwardedFrom = ''}) async {
    try {
      final cid = chatId(uid, partnerId);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fields = <String, dynamic>{
        'text': {'stringValue': text},
        'senderId': {'stringValue': uid},
        'senderName': {'stringValue': senderName},
        'timestamp': {'integerValue': ts.toString()},
        'type': {'stringValue': 'text'},
      };
      if (replyToId.isNotEmpty) fields['replyToId'] = {'stringValue': replyToId};
      if (replyToText.isNotEmpty) fields['replyToText'] = {'stringValue': replyToText};
      if (replyToName.isNotEmpty) fields['replyToName'] = {'stringValue': replyToName};
      if (forwardedFrom.isNotEmpty) fields['forwardedFrom'] = {'stringValue': forwardedFrom};
      final res = await http.post(Uri.parse('$_base/chats/$cid/messages'),
          body: json.encode({'fields': fields}), headers: {'Content-Type': 'application/json'});
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<List<ChatItem>> getUserChats(String uid) async {
    try {
      final query = {
        'structuredQuery': {
          'from': [{'collectionId': 'chats'}],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'members'},
              'op': 'ARRAY_CONTAINS',
              'value': {'stringValue': uid},
            }
          },
        }
      };
      final res = await http.post(Uri.parse('$_base:runQuery'),
          body: json.encode(query), headers: {'Content-Type': 'application/json'});
      if (res.statusCode != 200) return [];
      final docs = json.decode(res.body) as List? ?? [];
      final items = <ChatItem>[];
      for (final doc in docs) {
        final f = doc['fields'] ?? {};
        final members = (f['members']?['arrayValue']?['values'] as List?)?.map((e) => e['stringValue']?.toString() ?? '').toList() ?? [];
        final partnerId = members.firstWhere((m) => m != uid, orElse: () => '');
        if (partnerId.isEmpty) continue;
        final partner = await getUser(partnerId);
        items.add(ChatItem(
          chatId: doc['name'].toString().split('/').last,
          partnerId: partnerId,
          partnerName: partner?.name ?? partnerId,
          partnerPhoto: partner?.photoURL ?? '',
          lastMessage: _s(f['lastMessage']),
          lastTimestamp: int.tryParse(_s(f['lastTimestamp'])) ?? 0,
          unreadCount: int.tryParse(_s(f['unreadCount'])) ?? 0,
        ));
      }
      items.sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
      return items;
    } catch (_) { return []; }
  }

  static Future<bool> ensureChatExists(String uid, String partnerId, String myName) async {
    try {
      final cid = chatId(uid, partnerId);
      final check = await http.get(Uri.parse('$_base/chats/$cid'));
      if (check.statusCode == 200) return true;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fields = {
        'members': {'arrayValue': {'values': [{'stringValue': uid}, {'stringValue': partnerId}]}},
        'lastMessage': {'stringValue': ''},
        'lastTimestamp': {'integerValue': ts.toString()},
        'createdAt': {'integerValue': ts.toString()},
      };
      final res = await http.post(Uri.parse('$_base/chats/$cid'),
          body: json.encode({'fields': fields}), headers: {'Content-Type': 'application/json'});
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<User?> findUserByPhone(String phone) async {
    try {
      final uid = phone.replaceAll(RegExp(r'[^0-9]'), '');
      return await getUser(uid);
    } catch (_) { return null; }
  }

  static String _s(dynamic field) {
    if (field == null) return '';
    if (field is String) return field;
    return field['stringValue']?.toString() ?? '';
  }
  static bool _b(dynamic field) => field?['booleanValue'] ?? false;
}
