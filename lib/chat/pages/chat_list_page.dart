import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/conversation.dart';
import '../providers/chat_auth_provider.dart';
import '../services/supabase_chat_service.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _service = SupabaseChatService();
  List<Conversation> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _conversations = await _service.fetchConversations();
    } catch (e) {
      if (mounted) setState(() => _error = '대화 목록을 불러오지 못했습니다.\n$e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _newConversation() async {
    final conv = await _service.createConversation('새 대화');
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatPage(conversation: conv)),
    );
    _load();
  }

  Future<void> _delete(Conversation conv) async {
    await _service.deleteConversation(conv.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ChatAuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF7C5CFC), size: 18),
            SizedBox(width: 8),
            Text('대화 목록',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
            tooltip: '로그아웃',
            onPressed: auth.signOut,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newConversation,
        backgroundColor: const Color(0xFF7C5CFC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('새 대화', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C5CFC)))
          : _error != null
              ? _errorState()
              : _conversations.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF7C5CFC),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) => _ConvTile(
                      conversation: _conversations[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ChatPage(conversation: _conversations[i])),
                        );
                        _load();
                      },
                      onDelete: () => _delete(_conversations[i]),
                    ),
                  ),
                ),
    );
  }

  Widget _errorState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _load,
              child: const Text('다시 시도',
                  style: TextStyle(color: Color(0xFF7C5CFC))),
            ),
          ],
        ),
      );

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 64, color: Colors.white12),
            const SizedBox(height: 16),
            const Text('아직 대화가 없습니다',
                style: TextStyle(color: Colors.white38, fontSize: 15)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _newConversation,
              child: const Text('첫 대화 시작하기',
                  style: TextStyle(color: Color(0xFF7C5CFC))),
            ),
          ],
        ),
      );
}

class _ConvTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConvTile({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date =
        DateFormat('MM/dd HH:mm').format(conversation.createdAt.toLocal());
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.white.withOpacity(0.05),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFF7C5CFC),
        child: Icon(Icons.chat_bubble, color: Colors.white, size: 16),
      ),
      title: Text(conversation.title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(date,
          style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
        onPressed: onDelete,
      ),
    );
  }
}
