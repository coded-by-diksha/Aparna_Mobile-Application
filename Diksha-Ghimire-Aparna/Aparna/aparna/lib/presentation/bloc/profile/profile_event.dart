import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserProfile extends ProfileEvent {
  final int userId;
  final String token;

  const LoadUserProfile({required this.userId, required this.token});

  @override
  List<Object?> get props => [userId, token];
}

class UpdateUserProfile extends ProfileEvent {
  final int userId;
  final String username;
  final String email;
  final String phone;
  final String? dateOfBirth;
  final String? profilePhoto;
  final String token;

  const UpdateUserProfile({
    required this.userId,
    required this.username,
    required this.email,
    required this.phone,
    this.dateOfBirth,
    this.profilePhoto,
    required this.token,
  });

  @override
  List<Object?> get props => [userId, username, email, phone, dateOfBirth, profilePhoto, token];
}

class UpdateProfilePhoto extends ProfileEvent {
  final int userId;
  final String photoUrl;
  final String token;

  const UpdateProfilePhoto({
    required this.userId,
    required this.photoUrl,
    required this.token,
  });

  @override
  List<Object?> get props => [userId, photoUrl, token];
}
