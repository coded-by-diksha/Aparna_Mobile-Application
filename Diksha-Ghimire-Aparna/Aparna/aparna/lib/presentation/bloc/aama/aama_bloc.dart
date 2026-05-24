import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/chat_message_entity.dart';
import '../../../domain/usecases/send_message_usecase.dart';
import '../../../domain/usecases/get_greeting_usecase.dart';
import '../../../domain/usecases/get_chat_history_usecase.dart';
import '../../../domain/usecases/store_chat_message_usecase.dart';
import 'aama_event.dart';
import 'aama_state.dart';

class AamaBloc extends Bloc<AamaEvent, AamaState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetGreetingUseCase getGreetingUseCase;
  final GetChatHistoryUseCase getChatHistoryUseCase;
  final StoreChatMessageUseCase storeChatMessageUseCase;

  AamaBloc({
    required this.sendMessageUseCase,
    required this.getGreetingUseCase,
    required this.getChatHistoryUseCase,
    required this.storeChatMessageUseCase,
  }) : super(AamaInitial()) {
    on<InitializeAamaEvent>(_onInitialize);
    on<SendMessageEvent>(_onSendMessage);
    on<GetGreetingEvent>(_onGetGreeting);
    on<LoadChatHistoryEvent>(_onLoadChatHistory);
    on<StoreChatMessageEvent>(_onStoreChatMessage);
  }

  AamaChatState get _currentChatState {
    final s = state;
    return s is AamaChatState ? s : const AamaChatState();
  }

  Future<void> _onInitialize(
    InitializeAamaEvent event,
    Emitter<AamaState> emit,
  ) async {
    emit(const AamaChatState(isLoading: true));

    try {
      String greeting = '';
      List<ChatMessageEntity> history = [];

      if (event.userName != null && event.userName!.isNotEmpty) {
        greeting = await getGreetingUseCase(
          event.userName!,
          event.token,
          language: event.language,
        );
      }

      if (event.userId != null) {
        history = await getChatHistoryUseCase(event.userId!, event.token);
        if (history.isNotEmpty && greeting.isEmpty) {
          greeting = history.last.response;
        }
      }

      emit(AamaChatState(
        messages: history,
        greetingText: greeting,
      ));
    } catch (e) {
      emit(AamaChatState(errorMessage: e.toString()));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<AamaState> emit,
  ) async {
    final current = _currentChatState;

    final userMessage = ChatMessageEntity(
      userId: event.userId ?? 0,
      message: event.message,
      response: '',
      sender: event.userName ?? 'User',
      createdAt: DateTime.now(),
    );

    final updatedMessages = List<ChatMessageEntity>.from(current.messages)
      ..add(userMessage);

    emit(current.copyWith(messages: updatedMessages, isLoading: true, errorMessage: null));

    try {
      final response = await sendMessageUseCase(
        event.message,
        event.token,
        language: event.language,
      );

      final messagesWithResponse = List<ChatMessageEntity>.from(updatedMessages);
      messagesWithResponse[messagesWithResponse.length - 1] =
          messagesWithResponse.last.copyWith(response: response);

      emit(current.copyWith(
        messages: messagesWithResponse,
        greetingText: response,
        isLoading: false,
      ));

      if (event.userId != null) {
        add(StoreChatMessageEvent(
          userId: event.userId!,
          message: event.message,
          response: response,
          token: event.token,
        ));
      }
    } catch (e) {
      emit(current.copyWith(
        messages: updatedMessages,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onGetGreeting(
    GetGreetingEvent event,
    Emitter<AamaState> emit,
  ) async {
    final current = _currentChatState;
    emit(current.copyWith(isLoading: true));
    try {
      final greeting = await getGreetingUseCase(
        event.userName,
        event.token,
        language: event.language,
      );
      emit(current.copyWith(greetingText: greeting, isLoading: false));
    } catch (e) {
      emit(current.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistoryEvent event,
    Emitter<AamaState> emit,
  ) async {
    final current = _currentChatState;
    emit(current.copyWith(isLoading: true));
    try {
      final chatHistory = await getChatHistoryUseCase(event.userId, event.token);
      String greeting = current.greetingText;
      if (chatHistory.isNotEmpty && greeting.isEmpty) {
        greeting = chatHistory.last.response;
      }
      emit(current.copyWith(
        messages: chatHistory,
        greetingText: greeting,
        isLoading: false,
      ));
    } catch (e) {
      emit(current.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onStoreChatMessage(
    StoreChatMessageEvent event,
    Emitter<AamaState> emit,
  ) async {
    try {
      await storeChatMessageUseCase(
        userId: event.userId,
        message: event.message,
        response: event.response,
        token: event.token,
      );
    } catch (_) {
      // Silent fail — don't disrupt chat experience
    }
  }
}
