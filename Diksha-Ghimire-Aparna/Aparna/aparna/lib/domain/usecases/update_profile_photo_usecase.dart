import '../entities/user_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateProfilePhotoUseCase {
  final ProfileRepository repository;

  UpdateProfilePhotoUseCase(this.repository);

  Future<UserEntity> call({
    required int userId,
    required String photoUrl,
    required String token,
  }) async {
    return await repository.updateProfilePhoto(
      userId: userId,
      photoUrl: photoUrl,
      token: token,
    );
  }
}
