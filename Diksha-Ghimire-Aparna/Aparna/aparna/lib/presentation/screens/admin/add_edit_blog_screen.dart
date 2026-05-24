import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/blog_model.dart';
import '../../../data/services/blog_service.dart';
import '../../../main.dart';
import 'package:aparna/l10n/app_localizations.dart';
import 'package:aparna/core/constant/apiConstant.dart';

class AddEditBlogScreen extends StatefulWidget {
  final Blog? blog;

  const AddEditBlogScreen({Key? key, this.blog}) : super(key: key);

  @override
  State<AddEditBlogScreen> createState() => _AddEditBlogScreenState();
}

class _AddEditBlogScreenState extends State<AddEditBlogScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final BlogService _blogService = BlogService();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isSaving = false;
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.blog?.title ?? '');
    _contentController = TextEditingController(text: widget.blog?.content ?? '');
    _selectedCategoryId = widget.blog?.categoryId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _blogService.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('ERROR loading categories: $e');
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveBlog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    try {
      // For now, using the simplest version to fix compilation
      // Title and content are required
      final title = _titleController.text;
      final content = _contentController.text;
      
      if (widget.blog != null) {
        await _blogService.updateBlog(
          id: widget.blog!.id!,
          title: title,
          content: content,
          categoryId: _selectedCategoryId,
          images: _imageFile != null ? [XFile(_imageFile!.path)] : [],
        );
      } else {
        await _blogService.createBlog(
          title: title,
          content: content,
          categoryId: _selectedCategoryId,
          images: _imageFile != null ? [XFile(_imageFile!.path)] : [],
        );
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.success)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final horizontalPadding = (size.width * 0.05).clamp(16.0, 32.0);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8F8),
              Color(0xFFFFF0F0),
              Color(0xFFFFEBEB),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(l10n),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel(l10n.articleTitle, Icons.title_rounded),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _titleController,
                                decoration: _buildInputDecoration(l10n.articleTitle),
                                validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel(l10n.category, Icons.category_rounded),
                              const SizedBox(height: 10),
                              _isLoadingCategories
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                                        ),
                                      ),
                                    )
                                  : DropdownButtonFormField<int>(
                                      value: _selectedCategoryId,
                                      decoration: _buildInputDecoration(l10n.category),
                                      items: _categories.map((category) {
                                        return DropdownMenuItem<int>(
                                          value: category['id'],
                                          child: Text(category['name'] ?? ''),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCategoryId = value;
                                        });
                                      },
                                      validator: (value) => value == null ? 'Please select a category' : null,
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel(l10n.content, Icons.edit_note_rounded),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _contentController,
                                maxLines: 12,
                                decoration: _buildInputDecoration(l10n.writeYourHeartOut),
                                validator: (v) => v!.isEmpty ? 'Please enter some content' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel(l10n.images, Icons.add_photo_alternate_rounded),
                              const SizedBox(height: 12),
                              _buildImagePicker(
                                file: _imageFile,
                                imageUrl: widget.blog?.imageUrl,
                                onTap: _pickImage,
                                label: l10n.images,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.black87, size: 26),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.blog == null ? l10n.newPost : l10n.edit,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          TextButton.icon(
            onPressed: () => _showPreview(),
            icon: Icon(Icons.preview_rounded, size: 20, color: AppTheme.primaryColor),
            label: Text('Preview', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
          ),
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ElevatedButton(
                    onPressed: _saveBlog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInputLabel(String label, [IconData? icon]) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 10),
        ],
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildImagePicker({
    required File? file,
    required String? imageUrl,
    required VoidCallback onTap,
    required String label,
  }) {
    final hasImage = file != null || imageUrl != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey.shade300,
            width: hasImage ? 2 : 1,
          ),
          boxShadow: [
            if (!hasImage)
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
          image: file != null
              ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
              : (imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(
                        imageUrl.startsWith('http') ? imageUrl : '${ApiConstant.baseUrl}${imageUrl.replaceAll(r'\', '/').replaceFirst(RegExp(r'^/+'), '')}',
                      ),
                      fit: BoxFit.cover,
                    )
                  : null),
        ),
        child: hasImage
            ? Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Icon(Icons.edit_rounded, size: 22, color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_photo_alternate_rounded, size: 36, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to add cover image',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
      ),
    );
  }

  void _showPreview() {
    final title = _titleController.text;
    final content = _contentController.text;
    final categoryName = _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => {'name': 'General'},
    )['name'];

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Preview'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_imageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!, width: double.infinity, height: 200, fit: BoxFit.cover),
                  )
                else if (widget.blog?.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      (() {
                        final normalized = widget.blog!.imageUrl!.replaceAll('\\', '/');
                        if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
                          return normalized;
                        }
                        return '${ApiConstant.baseUrl}${normalized.replaceFirst(RegExp(r'^/+'), '')}';
                      })(),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    categoryName,
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  title.isEmpty ? 'Untitled' : title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Text(
                  content.isEmpty ? 'No content' : content,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

