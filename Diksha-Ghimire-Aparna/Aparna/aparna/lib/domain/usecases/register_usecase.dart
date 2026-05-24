import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Map<String, dynamic>> call({
    required String email,
    required String otp,
  }) async {
    return await repository.register(
      email: email,
      otp: otp,
    );
  }
}
