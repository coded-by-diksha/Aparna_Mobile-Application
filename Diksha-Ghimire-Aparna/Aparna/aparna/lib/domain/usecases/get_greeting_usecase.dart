import '../repositories/aama_repository.dart';

class GetGreetingUseCase {
  final AamaRepository repository;

  GetGreetingUseCase(this.repository);

  Future<String> call(String userName, String token, {String language = 'en'}) async {
    if (userName.trim().isEmpty) {
      throw Exception('User name cannot be empty');
    }
    return await repository.getGreeting(userName, token, language: language);
  }
}
