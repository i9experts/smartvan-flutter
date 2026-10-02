import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_errors.dart';
import '../chat_api.dart';
import '../chat_socket.dart';
import '../chat_templates.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _navy = Color(0xFF1B2B6B);

  final List<ChatMessage> _messages = []; // newest first
  final _input = TextEditingController();
  final _socket = ChatSocket();
  final List<StreamSubscription> _subs = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _sending = false;

  String get _cid => widget.conversation.id;

  @override
  void initState() {
    super.initState();
    _load();
    _socket.connect();
    _subs.add(_socket.messages.listen(_onIncoming));
    _subs.add(_socket.reads.listen((cid) {
      if (cid != _cid || !mounted) return;
      setState(() {
        for (var i = 0; i < _messages.length; i++) {
          final m = _messages[i];
          if (m.senderType == myChatRole && m.readAt == null) {
            _messages[i] = m.copyWith(readAt: DateTime.now());
          }
        }
      });
    }));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _socket.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final (list, more) = await ChatApi.messages(_cid);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
        _hasMore = more;
      });
      ChatApi.markRead(_cid).ignore();
    } catch (e) {
      _snack(ApiErrors.message(e, fallback: 'Could not load messages.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _messages.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final (list, more) = await ChatApi.messages(_cid, before: _messages.last.createdAt);
      if (!mounted) return;
      setState(() {
        _messages.addAll(list.where((m) => !_messages.any((x) => x.id == m.id)));
        _hasMore = more;
      });
    } catch (_) {
      // keep what we have
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onIncoming(ChatMessage m) {
    if (m.conversationId != _cid || !mounted) return;
    if (_messages.any((x) => x.id == m.id)) return;
    setState(() => _messages.insert(0, m));
    if (m.senderType != myChatRole) ChatApi.markRead(_cid).ignore();
  }

  Future<void> _send(String text, {String? templateKey}) async {
    final t = text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final sent = await ChatApi.send(_cid, t, templateKey: templateKey);
      if (!mounted) return;
      if (templateKey == null) _input.clear();
      if (!_messages.any((x) => x.id == sent.id)) {
        setState(() => _messages.insert(0, sent));
      }
    } catch (e) {
      _snack(ApiErrors.message(e, fallback: 'Message not sent. Try again.'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F3FF),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.otherUser.name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16)),
            if (c.kidNames.isNotEmpty)
              Text(c.kidNames.join(', '),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _navy))
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.pixels >= n.metrics.maxScrollExtent - 100) _loadMore();
                      return false;
                    },
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= _messages.length) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        return _bubble(_messages[i]);
                      },
                    ),
                  ),
          ),
          _quickReplies(),
          _composer(),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.senderType == myChatRole;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? _navy : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 2),
            bottomRight: Radius.circular(mine ? 2 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(m.text,
                style: TextStyle(color: mine ? Colors.white : const Color(0xFF1A1A2E), fontFamily: 'Poppins')),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('h:mm a').format(m.createdAt),
                    style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : const Color(0xFF8A94A6))),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(m.readAt != null ? Icons.done_all : Icons.done,
                      size: 14, color: m.readAt != null ? const Color(0xFF7FD3FF) : Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickReplies() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: parentQuickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final (key, text) = parentQuickReplies[i];
          return ActionChip(
            label: Text(text, style: const TextStyle(fontSize: 12)),
            onPressed: _sending ? null : () => _send(text, templateKey: key),
          );
        },
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Type a message',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : () => _send(_input.text),
              style: IconButton.styleFrom(backgroundColor: _navy),
              icon: _sending
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
