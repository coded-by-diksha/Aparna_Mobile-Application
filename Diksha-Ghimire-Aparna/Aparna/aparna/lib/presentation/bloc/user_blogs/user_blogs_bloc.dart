import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/blog_service.dart';
import 'user_blogs_event.dart';
import 'user_blogs_state.dart';

class UserBlogsBloc extends Bloc<UserBlogsEvent, UserBlogsState> {
  final BlogService blogService;

  UserBlogsBloc({required this.blogService}) : super(UserBlogsInitial()) {
    on<LoadUserBlogs>(_onLoadUserBlogs);
    on<RecordBlogView>(_onRecordBlogView);
  }

  Future<void> _onLoadUserBlogs(LoadUserBlogs event, Emitter<UserBlogsState> emit) async {
    emit(UserBlogsLoading());
    try {
      final blogs = await blogService.fetchBlogs();
      emit(UserBlogsLoaded(blogs));
    } catch (e) {
      emit(UserBlogsError(e.toString()));
    }
  }

  Future<void> _onRecordBlogView(RecordBlogView event, Emitter<UserBlogsState> emit) async {
    try {
      if (event.blog.id != null) {
        await blogService.recordBlogView(event.blog.id!);
      }
    } catch (_) {}
  }
}
