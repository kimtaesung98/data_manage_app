enum MessageRole { user, assistant }

class Message {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: map['id'] as String,
        conversationId: map['conversation_id'] as String,
        role: (map['role'] as String) == 'assistant'
            ? MessageRole.assistant
            : MessageRole.user,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toInsertMap() => {
        'conversation_id': conversationId,
        'role': role == MessageRole.assistant ? 'assistant' : 'user',
        'content': content,
      };

  bool get isUser => role == MessageRole.user;
}
