import '../entities/user_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateUserProfileUseCase {
  final ProfileRepository repository;

  UpdateUserProfileUseCase(this.repository);

  Future<UserEntity> call({
    required int userId,
    required String username,
    required String email,
    required String phone,
    String? dateOfBirth,
    String? profilePhoto,
    required String token,
  }) async {
    return await repository.updateUserProfile(
      userId: userId,
      username: username,
      email: email,
      phone: phone,
      dateOfBirth: dateOfBirth,
      profilePhoto: profilePhoto,
      token: token,
    );
  }
}
