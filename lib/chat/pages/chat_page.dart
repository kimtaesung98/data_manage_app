import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/supabase_chat_service.dart';

class ChatPage extends StatefulWidget {
  final Conversation conversation;

  const ChatPage({super.key, required this.conversation});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _service = SupabaseChatService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  List<Message> _messages = [];
  final List<_OptimisticMessage> _optimistic = [];
  bool _sending = false;

  // [Fix #3] Store subscription so it can be canceled in dispose().
  // _channel was declared but never assigned — removed entirely.
  StreamSubscription<List<Message>>? _messagesSub;

  @override
  void initState() {
    super.initState();
    _subscribeMessages();
  }

  void _subscribeMessages() {
    _messagesSub = _service
        .messagesStream(widget.conversation.id)
        .listen((msgs) {
      if (mounted) {
        setState(() => _messages = msgs);
        _scrollToBottom();
      }
    });
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;

    _textController.clear();
    setState(() {
      _sending = true;
      _optimistic.add(_OptimisticMessage(text));
    });
    _scrollToBottom();

    try {
      await _service.sendToClaude(
        conversationId: widget.conversation.id,
        history: _messages,
        userMessage: text,
      );
      // Realtime stream updates _messages automatically
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('전송 실패: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _optimistic.clear();
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allMessages = [
      ..._messages.map((m) => _MessageItem(
            content: m.content,
            isUser: m.isUser,
            pending: false,
          )),
      ..._optimistic.map((o) => _MessageItem(
            content: o.text,
            isUser: true,
            pending: true,
          )),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.conversation.title,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: allMessages.isEmpty
                ? _emptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: allMessages.length,
                    itemBuilder: (_, i) => allMessages[i],
                  ),
          ),
          if (_sending)
            const LinearProgressIndicator(
              backgroundColor: Color(0xFF1A1A2E),
              color: Color(0xFF7C5CFC),
            ),
          _InputBar(
            controller: _textController,
            onSend: _send,
            enabled: !_sending,
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome,
                size: 48, color: Color(0xFF7C5CFC)),
            const SizedBox(height: 12),
            const Text('무엇이든 물어보세요',
                style: TextStyle(color: Colors.white54, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'Claude가 답변드립니다',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.25), fontSize: 13),
            ),
          ],
        ),
      );
}

class _MessageItem extends StatelessWidget {
  final String content;
  final bool isUser;
  final bool pending;

  const _MessageItem({
    required this.content,
    required this.isUser,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF7C5CFC)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Opacity(
          opacity: pending ? 0.6 : 1.0,
          child: Text(
            content,
            style: TextStyle(
              color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              maxLines: 4,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요…',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: enabled ? onSend : null,
            icon: const Icon(Icons.send_rounded),
            color: const Color(0xFF7C5CFC),
            disabledColor: Colors.white12,
            style: IconButton.styleFrom(
              backgroundColor: enabled
                  ? const Color(0xFF7C5CFC).withOpacity(0.15)
                  : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptimisticMessage {
  final String text;
  _OptimisticMessage(this.text);
}
