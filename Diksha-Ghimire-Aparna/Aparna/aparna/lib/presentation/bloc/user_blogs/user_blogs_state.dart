import 'package:equatable/equatable.dart';
import '../../../data/models/blog_model.dart';

abstract class UserBlogsState extends Equatable {
  const UserBlogsState();
  // Get props
  @override
  List<Object?> get props => [];
}

// User blogs initial
class UserBlogsInitial extends UserBlogsState {}

// User blogs loading
class UserBlogsLoading extends UserBlogsState {}

// User blogs loaded
class UserBlogsLoaded extends UserBlogsState {
  final List<Blog> blogs;

  const UserBlogsLoaded(this.blogs);

  @override
  List<Object?> get props => [blogs];
}

// User blogs error
  class UserBlogsError extends UserBlogsState {
  final String message;

  const UserBlogsError(this.message);

  @override
  List<Object?> get props => [message];
}
