import 'package:equatable/equatable.dart';

abstract class DetailedUserEvent extends Equatable {
  const DetailedUserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserDetail extends DetailedUserEvent {
  final Map<String, dynamic> userData;

  const LoadUserDetail(this.userData);

  @override
  List<Object?> get props => [userData];
}

class DeleteUserFromDetail extends DetailedUserEvent {
  final String userId;

  const DeleteUserFromDetail(this.userId);

  @override
  List<Object?> get props => [userId];
}
