class Blog {
  final int? id;
  final int? userId;
  final String title;
  final String content;
  final List<String> images;
  final String? video;
  final String? category;
  final int? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? author;
  final int? views;
  
  String? get imageUrl => images.isNotEmpty ? images.first : null;

  Blog({
    this.id,
    this.userId,
    required this.title,
    required this.content,
    this.images = const [],
    this.video,
    this.category,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.createdAt,
    this.updatedAt,
    this.author,
    this.views,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Blog(
      id: parseInt(json['id']),
      userId: parseInt(json['userid']),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      images: json['images'] != null 
          ? List<String>.from(json['images']) 
          : [],
      video: json['video'],
      category: json['category'],
      categoryId: parseInt(json['category_id']),
      categoryName: json['categoryName'],
      categoryIcon: json['categoryIcon'],
      createdAt: json['createdat'] != null 
          ? DateTime.tryParse(json['createdat'].toString()) 
          : null,
      updatedAt: json['updatedat'] != null 
          ? DateTime.tryParse(json['updatedat'].toString()) 
          : null,
      author: json['authorName'],
      views: parseInt(json['views']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userid': userId,
      'title': title,
      'content': content,
      'images': images,
      'video': video,
      'category_id': categoryId,
      'views': views,
    };
  }
}
