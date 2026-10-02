import '../../core/network/api_errors.dart';
import '../../core/network/api_service.dart';

class ChatUser {
  final String id;
  final String type; // 'parent' | 'driver'
  final String name;
  final String? image;
  const ChatUser(this.id, this.type, this.name, this.image);

  factory ChatUser.fromJson(Map m) => ChatUser(
        m['id']?.toString() ?? '',
        m['type']?.toString() ?? '',
        m['name']?.toString() ?? '',
        m['image']?.toString(),
      );
}

class Conversation {
  final String id;
  final ChatUser otherUser;
  final List<String> kidNames;
  final String? lastText;
  final String? lastSenderType;
  final DateTime? lastAt;
  final int unread;

  const Conversation({
    required this.id,
    required this.otherUser,
    required this.kidNames,
    this.lastText,
    this.lastSenderType,
    this.lastAt,
    this.unread = 0,
  });

  factory Conversation.fromJson(Map m) {
    final last = m['lastMessage'] is Map ? m['lastMessage'] as Map : null;
    return Conversation(
      id: m['conversationId']?.toString() ?? '',
      otherUser: ChatUser.fromJson(m['otherUser'] is Map ? m['otherUser'] as Map : const {}),
      kidNames: (m['kids'] is List ? m['kids'] as List : const [])
          .whereType<Map>()
          .map((k) => k['fullname']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList(),
      lastText: last?['text']?.toString(),
      lastSenderType: last?['senderType']?.toString(),
      lastAt: DateTime.tryParse(last?['at']?.toString() ?? '')?.toLocal(),
      unread: (m['unread'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderType;
  final String text;
  final DateTime createdAt;
  final DateTime? readAt;

  /// Local-only: still sending.
  final bool pending;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.text,
    required this.createdAt,
    this.readAt,
    this.pending = false,
  });

  factory ChatMessage.fromJson(Map m) => ChatMessage(
        id: m['messageId']?.toString() ?? '',
        conversationId: m['conversationId']?.toString() ?? '',
        senderType: m['senderType']?.toString() ?? '',
        text: m['text']?.toString() ?? '',
        createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
        readAt: DateTime.tryParse(m['readAt']?.toString() ?? '')?.toLocal(),
      );

  ChatMessage copyWith({DateTime? readAt}) => ChatMessage(
        id: id,
        conversationId: conversationId,
        senderType: senderType,
        text: text,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
        pending: pending,
      );
}

class ChatApi {
  ChatApi._();

  static Map _data(dynamic body) => body is Map && body['data'] is Map ? body['data'] as Map : const {};

  static Future<List<Conversation>> conversations() async {
    final res = ApiErrors.ensureOk(await ApiService.get('/chat/conversations'));
    final d = res.data is Map ? res.data['data'] : null;
    return d is List ? d.whereType<Map>().map(Conversation.fromJson).toList() : [];
  }

  static Future<int> unread() async {
    final res = ApiErrors.ensureOk(await ApiService.get('/chat/unread'));
    return (_data(res.data)['unread'] as num?)?.toInt() ?? 0;
  }

  static Future<Conversation> start(String kidId) async {
    final res = ApiErrors.ensureOk(await ApiService.post('/chat/start', {'kidId': kidId}));
    return Conversation.fromJson(_data(res.data));
  }

  /// Newest first.
  static Future<(List<ChatMessage>, bool)> messages(String conversationId, {DateTime? before}) async {
    final q = before == null ? '' : '?before=${Uri.encodeComponent(before.toUtc().toIso8601String())}';
    final res = ApiErrors.ensureOk(await ApiService.get('/chat/$conversationId/messages$q'));
    final body = res.data is Map ? res.data as Map : const {};
    final d = body['data'];
    final list = d is List ? d.whereType<Map>().map(ChatMessage.fromJson).toList() : <ChatMessage>[];
    return (list, body['hasMore'] == true);
  }

  static Future<ChatMessage> send(String conversationId, String text, {String? templateKey}) async {
    final res = ApiErrors.ensureOk(await ApiService.post('/chat/$conversationId/messages', {
      'text': text,
      if (templateKey != null) 'templateKey': templateKey,
    }));
    return ChatMessage.fromJson(_data(res.data));
  }

  static Future<void> markRead(String conversationId) async {
    ApiErrors.ensureOk(await ApiService.post('/chat/$conversationId/read', {}));
  }
}
