import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../data/models/blog_model.dart';
import '../../core/constant/apiConstant.dart';

// Blog details screen
class BlogDetailsScreen extends StatefulWidget {
  final Blog blog;

  const BlogDetailsScreen({Key? key, required this.blog}) : super(key: key);

  @override
  State<BlogDetailsScreen> createState() => _BlogDetailsScreenState();
}

class _BlogDetailsScreenState extends State<BlogDetailsScreen> {
  bool _imageLoadFailed = false;

  Blog get blog => widget.blog;

  bool get _showHeaderImage =>
      blog.images.isNotEmpty && !_imageLoadFailed;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final horizontalPadding = (size.width * 0.06).clamp(20.0, 32.0);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showHeaderImage) _buildPremiumHeader(context),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: _showHeaderImage ? 40 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_showHeaderImage) _buildInlineTitle(),
                      _buildMarkdownContent(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildBackButton(context)
        ],
      ),
    );
  }

  Widget _buildInlineTitle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 100),
      child: Text(
        blog.title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    final rawImage = blog.images.first;
    final normalized = rawImage.replaceAll('\\', '/');
    final imageUrl = normalized.startsWith('http://') || normalized.startsWith('https://')
      ? normalized
      : '${ApiConstant.baseUrl}${normalized.replaceFirst(RegExp(r'^/+'), '')}';

    return SizedBox(
      height: 400,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: 40,
            child: ClipPath(
              clipper: HeaderClipper(),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_imageLoadFailed) {
                      setState(() => _imageLoadFailed = true);
                    }
                  });
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF91C5E4),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    blog.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    blog.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFFF8A5A5),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildMarkdownContent() {
    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
          MarkdownBody(
            data: blog.content,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 16,
                height: 1.7,
                color: Color(0xFF4A4A4A),
              ),
              h1: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.4,
                color: Colors.black,
              ),
              h2: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.4,
                color: Colors.black,
              ),
              listBullet: const TextStyle(
                fontSize: 16,
                color: Color(0xFFF8A5A5),
                fontWeight: FontWeight.bold,
              ),
              blockSpacing: 15,
            ),
          ),
       ],
    );
  }
}

// Custom Clipper for the diagonal cut look
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height - 80); // Diagonal cut
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
