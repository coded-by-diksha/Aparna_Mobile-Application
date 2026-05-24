import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String? id;
  final String username;
  final String email;
  final String? phone;
  final String? dateOfBirth;
  final String? profilephoto;

  const UserEntity({
    this.id,
    required this.username,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.profilephoto,
  });

  @override
  List<Object?> get props => [id, username, email, phone, dateOfBirth, profilephoto];
}
