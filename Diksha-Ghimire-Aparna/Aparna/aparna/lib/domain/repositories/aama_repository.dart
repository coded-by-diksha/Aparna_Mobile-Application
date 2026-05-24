import '../entities/chat_message_entity.dart';

abstract class AamaRepository {
  Future<String> sendMessage(String message, String token, {String language = 'en'});
  Future<String> getGreeting(String userName, String token, {String language = 'en'});
  Future<void> storeChatMessage({
    required int userId,
    required String message,
    required String response,
    required String token,
  });
  Future<List<ChatMessageEntity>> getChatHistory({
    required int userId,
    required String token,
  });
}
