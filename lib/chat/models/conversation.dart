class Conversation {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;

  const Conversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
  });

  factory Conversation.fromMap(Map<String, dynamic> map) => Conversation(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        title: map['title'] as String? ?? '새 대화',
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toInsertMap() => {
        'user_id': userId,
        'title': title,
      };
}
