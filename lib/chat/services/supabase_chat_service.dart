import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class SupabaseChatService {
  final _client = Supabase.instance.client;

  // ── Conversations ──────────────────────────────────────────────────────────

  Future<List<Conversation>> fetchConversations() async {
    final rows = await _client
        .from('conversations')
        .select()
        .order('created_at', ascending: false);
    return (rows as List).map((r) => Conversation.fromMap(r)).toList();
  }

  Future<Conversation> createConversation(String title) async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('conversations')
        .insert({'user_id': userId, 'title': title})
        .select()
        .single();
    return Conversation.fromMap(row);
  }

  Future<void> deleteConversation(String id) async {
    await _client.from('conversations').delete().eq('id', id);
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  Stream<List<Message>> messagesStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => rows.map(Message.fromMap).toList());
  }

  Future<Message> insertMessage({
    required String conversationId,
    required String role,
    required String content,
  }) async {
    final row = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'role': role,
          'content': content,
        })
        .select()
        .single();
    return Message.fromMap(row);
  }

  // ── Claude via Edge Function ───────────────────────────────────────────────

  /// Calls the `chat` Edge Function which proxies to Anthropic API.
  /// The Function stores the assistant reply in DB and returns it.
  Future<String> sendToClaude({
    required String conversationId,
    required List<Message> history,
    required String userMessage,
  }) async {
    final response = await _client.functions.invoke(
      'chat',
      body: {
        'conversation_id': conversationId,
        'message': userMessage,
        'history': history
            .map((m) => {'role': m.role.name, 'content': m.content})
            .toList(),
      },
    );
    return (response.data as Map<String, dynamic>)['reply'] as String;
  }
}
