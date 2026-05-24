import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    super.id,
    required super.username,
    required super.email,
    super.phone,
    super.dateOfBirth,
    super.profilephoto,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['uid'] ?? json['id'])?.toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone']?.toString(),
      dateOfBirth: json['dateofbirth'] ?? json['dateOfBirth'] ?? json['date_of_birth'],
      profilephoto: json['profilephoto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': id,
      'username': username,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'profilephoto': profilephoto,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      username: username,
      email: email,
      phone: phone,
      dateOfBirth: dateOfBirth,
      profilephoto: profilephoto,
    );
  }
}
