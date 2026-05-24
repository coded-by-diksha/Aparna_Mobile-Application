import '../entities/user_entity.dart';

abstract class ProfileRepository {
  Future<UserEntity> getUserProfile(int userId, String token);
  Future<UserEntity> updateUserProfile({
    required int userId,
    required String username,
    required String email,
    required String phone,
    String? dateOfBirth,
    String? profilePhoto,
    required String token,
  });
  Future<UserEntity> updateProfilePhoto({
    required int userId,
    required String photoUrl,
    required String token,
  });
}
