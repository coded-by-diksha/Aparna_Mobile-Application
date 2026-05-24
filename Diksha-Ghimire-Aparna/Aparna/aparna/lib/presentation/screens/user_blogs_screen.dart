import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/blog_model.dart';
import '../bloc/user_blogs/user_blogs_bloc.dart';
import '../bloc/user_blogs/user_blogs_event.dart';
import '../bloc/user_blogs/user_blogs_state.dart';
import 'blog_details_screen.dart';
import 'user_stories_screen.dart';

class UserBlogsScreen extends StatefulWidget {
  const UserBlogsScreen({Key? key}) : super(key: key);

  @override
  State<UserBlogsScreen> createState() => _UserBlogsScreenState();
}

class _UserBlogsScreenState extends State<UserBlogsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserBlogsBloc>().add(LoadUserBlogs());
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final horizontalPadding = (size.width * 0.05).clamp(16.0, 32.0);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFFF8A5A5),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Articles',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocConsumer<UserBlogsBloc, UserBlogsState>(
                listener: (context, state) {
                  if (state is UserBlogsError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to load blogs: ${state.message}')),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is UserBlogsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF8A5A5),
                      ),
                    );
                  }

                  final blogs = state is UserBlogsLoaded ? state.blogs : <Blog>[];

                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: blogs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const UserStoriesScreen()),
                            );
                          },
                          child: _buildBlogGridCard(
                            Blog(
                              title: 'User stories',
                              content: '',
                              categoryName: 'Stories',
                              categoryIcon: '💬',
                            ),
                          ),
                        );
                      }

                      final blog = blogs[index - 1];
                      if (blog.title.toLowerCase().contains('user stories') ||
                          blog.categoryName == 'Stories') {
                        return const SizedBox.shrink();
                      }

                      return GestureDetector(
                        onTap: () {
                          context.read<UserBlogsBloc>().add(RecordBlogView(blog));
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlogDetailsScreen(blog: blog),
                            ),
                          );
                        },
                        child: _buildBlogGridCard(blog),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build blog grid card
  Widget _buildBlogGridCard(Blog blog) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section with Pink Gradient and Emoji
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF8A5A5).withOpacity(0.6),
                    const Color(0xFFF8A5A5).withOpacity(0.4),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  blog.categoryIcon ?? '🌸',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
          ),
          // Bottom metadata section
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEEE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          blog.categoryName ?? 'General',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF8A5A5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        blog.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A4A4A),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}