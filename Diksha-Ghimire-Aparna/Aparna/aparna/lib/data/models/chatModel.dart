class ChatMessage {
  final int? id;
  final int userId;
  final String message;
  final String response;
  final String sender;
  final DateTime createdAt;

  ChatMessage({
    this.id,
    required this.userId,
    required this.message,
    required this.response,
    required this.sender,
    required this.createdAt,
  });

  // Factory constructor to create ChatMessage from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      userId: json['user_id'],
      message: json['message'] ?? '',
      response: json['response'] ?? '',
      sender: json['sender'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  // Convert ChatMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'message': message,
      'response': response,
      'sender': sender,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  ChatMessage copyWith({
    int? id,
    int? userId,
    String? message,
    String? response,
    String? sender,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      response: response ?? this.response,
      sender: sender ?? this.sender,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
