import '../repositories/aama_repository.dart';

class SendMessageUseCase {
  final AamaRepository repository;

  SendMessageUseCase(this.repository);

  Future<String> call(String message, String token, {String language = 'en'}) async {
    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }
    return await repository.sendMessage(message, token, language: language);
  }
}
