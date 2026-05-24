import 'package:flutter/material.dart';
import 'add_edit_blog_screen.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/models/blog_model.dart';
import 'package:aparna/l10n/app_localizations.dart';
import '../blog_details_screen.dart';

class AdminBlogsScreen extends StatefulWidget {
  const AdminBlogsScreen({Key? key}) : super(key: key);

  @override
  State<AdminBlogsScreen> createState() => _AdminBlogsScreenState();
}

class _AdminBlogsScreenState extends State<AdminBlogsScreen> {
  final AdminService _adminService = AdminService();
  List<Blog> _blogs = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Blog> get _filteredBlogs {
    if (_searchQuery.isEmpty) return _blogs;
    final q = _searchQuery.toLowerCase();
    return _blogs.where((blog) {
      return blog.title.toLowerCase().contains(q) ||
          blog.content.toLowerCase().contains(q) ||
          (blog.categoryName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadBlogs();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBlogs() async {
    try {
      print('DEBUG: Loading blogs in AdminBlogsScreen');
      final blogsJson = await _adminService.fetchBlogs();
      print('DEBUG: Received ${blogsJson.length} blog maps from service');
      
      if (mounted) {
        setState(() {
          try {
            _blogs = blogsJson.map((json) {
              try {
                return Blog.fromJson(json);
              } catch (e) {
                print('ERROR parsing blog JSON: $e');
                print('OFFENDING JSON: $json');
                rethrow;
              }
            }).toList();
            print('DEBUG: Successfully parsed ${_blogs.length} Blog models');
          } catch (e) {
            print('FATAL ERROR in mapping blogs: $e');
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Catch block in _loadBlogs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final horizontalPadding = (size.width * 0.05).clamp(16.0, 32.0);
    final verticalPadding = (size.height * 0.05).clamp(16.0, 32.0);
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE91E63),
                    ),
                  )
                : _filteredBlogs.isEmpty
                    ? _buildEmptyState()
                    : _buildBlogList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final verticalPadding = (size.height * 0.05).clamp(16.0, 32.0);
    return Container(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      color: const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with illustration and title
          Row(
            children: [
              Image.asset(
                'assets/blog_page.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.manageBlog,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.createAndEditBlogPosts,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // Search bar and Add button
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchForBlogs,
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8B0B0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToAddBlog(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            l10n.add,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            l10n.noBlogPostsYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createFirstBlogPost,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlogList() {
    final blogs = _filteredBlogs;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: blogs.length,
      itemBuilder: (context, index) {
        return _buildBlogCard(blogs[index]);
      },
    );
  }

  String _getCategoryEmoji(String? categoryName) {
    if (categoryName == null || categoryName.isEmpty) {
      return '📝';
    }
    
    final category = categoryName.toLowerCase();
    
    // Map categories to emojis
    if (category.contains('menstrual') || category.contains('period') || category.contains('cycle')) {
      return '🩸';
    } else if (category.contains('health') || category.contains('wellness')) {
      return '💚';
    } else if (category.contains('Remedies') || category.contains('diet') || category.contains('food')) {
      return '🥗';
    } else if (category.contains('exercise') || category.contains('fitness') || category.contains('workout')) {
      return '💪';
    } else if (category.contains('mental') || category.contains('mind') || category.contains('mindfulness')) {
      return '🧠';
    } else if (category.contains('pregnancy') || category.contains('fertility')) {
      return '🤰';
    } else if (category.contains('stories') || category.contains('care')) {
      return '✨';
    } else if (category.contains('tips') || category.contains('advice')) {
      return '💡';
    } else if (category.contains('education') || category.contains('learn')) {
      return '📚';
    } else {
      return '📝';
    }
  }

  Widget _buildBlogCard(Blog blog) {
    // Format date
    String formattedDate = 'N/A';
    if (blog.createdAt != null) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      formattedDate = '${months[blog.createdAt!.month - 1]} ${blog.createdAt!.day}, ${blog.createdAt!.year}';
    }
    
    // Get description preview
    String description = blog.content;
    if (description.length > 80) {
      description = '${description.substring(0, 80)}...';
    }
    
    final categoryEmoji = _getCategoryEmoji(blog.categoryName);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlogDetailsScreen(blog: blog),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left icon container with pink background and category emoji
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF8E8E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                categoryEmoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with Published tag
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        blog.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.published,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Category
                Text(
                  blog.categoryName ?? AppLocalizations.of(context)!.general,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 6),
                // Description
                Text(
                  description.isEmpty ? AppLocalizations.of(context)!.noDescriptionAvailable : description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Date and action icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade600),
                          onPressed: () => _navigateToEditBlog(blog),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => _deleteBlog(blog.id.toString()),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _navigateToAddBlog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditBlogScreen()),
    );
    if (result == true) _loadBlogs();
  }

  void _navigateToEditBlog(Blog blog) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditBlogScreen(blog: blog),
      ),
    );

    if (result == true) {
      _loadBlogs();
    }
  }

  Future<void> _deleteBlog(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteBlogConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteBlog(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.success),
              backgroundColor: Colors.green,
            ),
          );
          _loadBlogs();
        }
      } catch (e) {
        print('Error deleting blog: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.failedToDeleteBlog}: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}

