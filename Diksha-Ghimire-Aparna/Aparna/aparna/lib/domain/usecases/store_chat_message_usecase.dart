import '../repositories/aama_repository.dart';

class StoreChatMessageUseCase {
  final AamaRepository repository;

  StoreChatMessageUseCase(this.repository);

  Future<void> call({
    required int userId,
    required String message,
    required String response,
    required String token,
  }) async {
    if (userId <= 0) {
      throw Exception('Invalid user ID');
    }
    if (message.trim().isEmpty || response.trim().isEmpty) {
      throw Exception('Message and response cannot be empty');
    }
    return await repository.storeChatMessage(
      userId: userId,
      message: message,
      response: response,
      token: token,
    );
  }
}
