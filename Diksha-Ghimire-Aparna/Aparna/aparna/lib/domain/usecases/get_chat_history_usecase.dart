import '../entities/chat_message_entity.dart';
import '../repositories/aama_repository.dart';

class GetChatHistoryUseCase {
  final AamaRepository repository;

  GetChatHistoryUseCase(this.repository);

  Future<List<ChatMessageEntity>> call(int userId, String token) async {
    if (userId <= 0) {
      throw Exception('Invalid user ID');
    }
    return await repository.getChatHistory(userId: userId, token: token);
  }
}
