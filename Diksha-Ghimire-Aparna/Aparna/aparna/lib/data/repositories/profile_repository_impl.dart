import '../../domain/repositories/profile_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity> getUserProfile(int userId, String token) async {
    final userModel = await remoteDataSource.getUserProfile(userId, token);
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> updateUserProfile({
    required int userId,
    required String username,
    required String email,
    required String phone,
    String? dateOfBirth,
    String? profilePhoto,
    required String token,
  }) async {
    final userModel = await remoteDataSource.updateUserProfile(
      userId: userId,
      username: username,
      email: email,
      phone: phone,
      dateOfBirth: dateOfBirth,
      profilePhoto: profilePhoto,
      token: token,
    );
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> updateProfilePhoto({
    required int userId,
    required String photoUrl,
    required String token,
  }) async {
    final userModel = await remoteDataSource.updateProfilePhoto(
      userId: userId,
      photoUrl: photoUrl,
      token: token,
    );
    return userModel.toEntity();
  }
}
