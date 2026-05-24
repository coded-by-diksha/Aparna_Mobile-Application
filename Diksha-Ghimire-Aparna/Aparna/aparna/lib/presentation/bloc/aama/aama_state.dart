import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_message_entity.dart';

abstract class AamaState extends Equatable {
  const AamaState();

  @override
  List<Object?> get props => [];
}

class AamaInitial extends AamaState {}

class AamaChatState extends AamaState {
  final List<ChatMessageEntity> messages;
  final String greetingText;
  final bool isLoading;
  final String? errorMessage;
  final bool messageSaved;

  const AamaChatState({
    this.messages = const [],
    this.greetingText = '',
    this.isLoading = false,
    this.errorMessage,
    this.messageSaved = false,
  });

  AamaChatState copyWith({
    List<ChatMessageEntity>? messages,
    String? greetingText,
    bool? isLoading,
    String? errorMessage,
    bool? messageSaved,
  }) {
    return AamaChatState(
      messages: messages ?? this.messages,
      greetingText: greetingText ?? this.greetingText,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      messageSaved: messageSaved ?? this.messageSaved,
    );
  }

  @override
  List<Object?> get props => [messages, greetingText, isLoading, errorMessage, messageSaved];
}
