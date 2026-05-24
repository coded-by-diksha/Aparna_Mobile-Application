import 'package:equatable/equatable.dart';

abstract class AamaEvent extends Equatable {
  const AamaEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAamaEvent extends AamaEvent {
  final String? userName;
  final int? userId;
  final String token;
  final String language;

  const InitializeAamaEvent({
    this.userName,
    this.userId,
    required this.token,
    this.language = 'en',
  });

  @override
  List<Object?> get props => [userName, userId, token, language];
}

class SendMessageEvent extends AamaEvent {
  final String message;
  final String token;
  final int? userId;
  final String? userName;
  final String language;

  const SendMessageEvent({
    required this.message,
    required this.token,
    this.userId,
    this.userName,
    this.language = 'en',
  });

  @override
  List<Object?> get props => [message, token, userId, userName, language];
}

class GetGreetingEvent extends AamaEvent {
  final String userName;
  final String token;
  final String language;

  const GetGreetingEvent({
    required this.userName,
    required this.token,
    this.language = 'en',
  });

  @override
  List<Object?> get props => [userName, token, language];
}

class LoadChatHistoryEvent extends AamaEvent {
  final int userId;
  final String token;

  const LoadChatHistoryEvent({required this.userId, required this.token});

  @override
  List<Object?> get props => [userId, token];
}

class StoreChatMessageEvent extends AamaEvent {
  final int userId;
  final String message;
  final String response;
  final String token;

  const StoreChatMessageEvent({
    required this.userId,
    required this.message,
    required this.response,
    required this.token,
  });

  @override
  List<Object?> get props => [userId, message, response, token];
}
