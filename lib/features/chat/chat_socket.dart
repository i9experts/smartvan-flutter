import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants/app_constants.dart';
import '../../core/storage/token_storage.dart';
import 'chat_api.dart';

/// Real-time chat events while a chat screen is open. The server puts
/// every socket in a personal room, so no join is needed.
class ChatSocket {
  io.Socket? _socket;
  final _messages = StreamController<ChatMessage>.broadcast();
  final _reads = StreamController<String>.broadcast();

  Stream<ChatMessage> get messages => _messages.stream;

  /// conversationId whose messages the other side has read.
  Stream<String> get reads => _reads.stream;

  Future<void> connect() async {
    final token = await TokenStorage.read() ?? '';
    final socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );
    socket.on('chatMessage', (data) {
      if (data is Map) _messages.add(ChatMessage.fromJson(data));
    });
    socket.on('chatRead', (data) {
      if (data is Map && data['conversationId'] != null) {
        _reads.add(data['conversationId'].toString());
      }
    });
    socket.connect();
    _socket = socket;
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _messages.close();
    _reads.close();
  }
}
