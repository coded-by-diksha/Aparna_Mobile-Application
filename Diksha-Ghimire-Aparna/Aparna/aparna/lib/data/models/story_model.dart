class UserStory {
  final int? id;
  final int? userId;
  final String title;
  final String content;
  final String authorName;
  final bool isAnonymous;
  final DateTime? createdAt;

  UserStory({
    this.id,
    this.userId,
    required this.title,
    required this.content,
    this.authorName = 'Anonymous',
    this.isAnonymous = true,
    this.createdAt,
  });

  factory UserStory.fromJson(Map<String, dynamic> json) {
    return UserStory(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      authorName: json['author_name'] ?? 'Anonymous',
      isAnonymous: json['is_anonymous'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'is_anonymous': isAnonymous,
      'author_name': authorName,
    };
  }
}
