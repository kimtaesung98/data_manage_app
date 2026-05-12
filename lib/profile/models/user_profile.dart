class UserProfile {
  final String id;
  final String? nickname;
  final String? avatarUrl;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    this.nickname,
    this.avatarUrl,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        nickname: map['nickname'] as String?,
        avatarUrl: map['avatar_url'] as String?,
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  UserProfile copyWith({
    String? nickname,
    String? avatarUrl,
  }) =>
      UserProfile(
        id: id,
        nickname: nickname ?? this.nickname,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toUpsertMap() => {
        'id': id,
        'nickname': nickname,
        'avatar_url': avatarUrl,
      };
}
