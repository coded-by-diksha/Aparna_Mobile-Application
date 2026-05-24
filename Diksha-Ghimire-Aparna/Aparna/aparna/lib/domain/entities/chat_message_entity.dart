import 'package:equatable/equatable.dart';

class ChatMessageEntity extends Equatable {
  final int? id;
  final int userId;
  final String message;
  final String response;
  final String sender;
  final DateTime createdAt;

  const ChatMessageEntity({
    this.id,
    required this.userId,
    required this.message,
    required this.response,
    required this.sender,
    required this.createdAt,
  });

  ChatMessageEntity copyWith({
    int? id,
    int? userId,
    String? message,
    String? response,
    String? sender,
    DateTime? createdAt,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      response: response ?? this.response,
      sender: sender ?? this.sender,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, message, response, sender, createdAt];
}
