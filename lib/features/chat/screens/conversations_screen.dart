import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_errors.dart';
import '../chat_api.dart';
import '../chat_socket.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  static const _navy = Color(0xFF1B3B69);
  List<Conversation> _items = [];
  bool _loading = true;
  String? _error;
  final _socket = ChatSocket();
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _socket.connect();
    _sub = _socket.messages.listen((_) => _load(silent: true));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _socket.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final items = await ChatApi.conversations();
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiErrors.message(e, fallback: 'Could not load messages.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _time(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return DateFormat('h:mm a').format(t);
    }
    return DateFormat('d MMM').format(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F3FF),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Messages', style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _navy))
            : _items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      const Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFF8A94A6)),
                      const SizedBox(height: 12),
                      Text(
                        _error ?? 'No messages yet.\nOpen My Kids and tap Message to talk to your driver.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF8A94A6), fontFamily: 'Poppins'),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = _items[i];
                      final subtitle = c.kidNames.isEmpty ? '' : '${c.kidNames.join(', ')} · ';
                      return ListTile(
                        tileColor: Colors.white,
                        leading: CircleAvatar(
                          backgroundColor: _navy.withOpacity(0.1),
                          backgroundImage: c.otherUser.image != null ? NetworkImage(c.otherUser.image!) : null,
                          child: c.otherUser.image == null
                              ? Text(c.otherUser.name.isNotEmpty ? c.otherUser.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: _navy, fontWeight: FontWeight.bold))
                              : null,
                        ),
                        title: Text(c.otherUser.name,
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: c.unread > 0 ? FontWeight.bold : FontWeight.w500)),
                        subtitle: Text('$subtitle${c.lastText ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_time(c.lastAt),
                                style: const TextStyle(fontSize: 11, color: Color(0xFF8A94A6))),
                            if (c.unread > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF27AE60),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('${c.unread}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11)),
                              ),
                          ],
                        ),
                        onTap: () async {
                          await context.push('/chat', extra: c);
                          _load(silent: true);
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
