import 'package:equatable/equatable.dart';

abstract class ChangePasswordState extends Equatable {
  const ChangePasswordState();

  @override
  List<Object?> get props => [];
}

class ChangePasswordInitial extends ChangePasswordState {}

class ChangePasswordLoading extends ChangePasswordState {}

class ChangePasswordSuccess extends ChangePasswordState {
  final String message;

  const ChangePasswordSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class ChangePasswordFailure extends ChangePasswordState {
  final String message;

  const ChangePasswordFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
