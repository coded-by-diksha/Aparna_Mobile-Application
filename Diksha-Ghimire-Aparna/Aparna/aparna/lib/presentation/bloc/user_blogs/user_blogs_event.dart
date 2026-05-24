import 'package:equatable/equatable.dart';
import '../../../data/models/blog_model.dart';

abstract class UserBlogsEvent extends Equatable {
  const UserBlogsEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserBlogs extends UserBlogsEvent {}

class RecordBlogView extends UserBlogsEvent {
  final Blog blog;

  const RecordBlogView(this.blog);

  @override
  List<Object?> get props => [blog.id];
}
