import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constant/apiConstant.dart';
import '../../core/guards/auth_guard.dart'; // For AuthService
import '../../core/network/auth_http_client.dart';
import '../models/blog_model.dart';

class BlogService {
  static final String baseUrl = '${ApiConstant.baseUrl}blogs';

  Future<List<Blog>> fetchBlogs() async {
    final token = await AuthService.getToken();
    final response = await AuthHttpClient.instance.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Blog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load blogs');
    }
  }

  Future<Blog> fetchBlogById(int id) async {
    final token = await AuthService.getToken();
    final response = await AuthHttpClient.instance.get(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Blog.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load blog details');
    }
  }

  Future<Blog> createBlog({
    required String title,
    required String content,
    int? categoryId,
    List<XFile> images = const [],
    XFile? video,
  }) async {
    final token = await AuthService.getToken();
    final userId = await AuthService.getUserId();
    
    if (userId == null) throw Exception('User not logged in');

    var request = await AuthHttpClient.instance.authorizedMultipartRequest(
      'POST',
      Uri.parse(baseUrl),
    );
    
    print('DEBUG: Token retrieved from AuthService: "$token"');
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
      print('DEBUG: Added Authorization header to request');
    } else {
      print('WARNING: Token is null or empty, Authorization header NOT added');
    }

    request.fields['title'] = title ;
    request.fields['content'] = content ;
    if (categoryId != null) request.fields['category_id'] = categoryId.toString();
    request.fields['userid'] = userId.toString();
    // Assuming backend might need lang_id, default to 1 or passed value
    request.fields['lang_id'] = '1'; 

    // Add images
    for (var image in images) {
      final bytes = await image.readAsBytes();
      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
      final mimeTypeData = mimeType.split('/');
      
      request.files.add(http.MultipartFile.fromBytes(
        'images',
        bytes,
        filename: image.name,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ));
    }

    // Add video
    if (video != null) {
      final bytes = await video.readAsBytes();
      final mimeType = lookupMimeType(video.path) ?? 'video/mp4';
      final mimeTypeData = mimeType.split('/');
      
      request.files.add(http.MultipartFile.fromBytes(
        'video',
        bytes,
        filename: video.name,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ));
    }

    final streamAction = await request.send();
    final response = await http.Response.fromStream(streamAction);

    if (response.statusCode == 201) {
      return Blog.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create blog: ${response.body}');
    }
  }

  Future<Blog> updateBlog({
    required int id,
    String? title,
    String? content,
    int? categoryId,
    List<XFile> images = const [],
    XFile? video,
    String? existingImages, 
    // Our backend: if files sent, they replace or append depending on logic?
    // Backend logic: "if imageFiles ... updateData.images = imageFiles".
    // So if we send new images, it replaces the field.
  }) async {
    final token = await AuthService.getToken();
    final userId = await AuthService.getUserId();

    var request = await AuthHttpClient.instance.authorizedMultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/$id'),
    );

    print('DEBUG: Token retrieved from AuthService for Update: "$token"');
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    // We should send userId even on update if backend requires it (it does in update logic 'userid: req.body.userid')
    // Ideally update shouldn't change author, but backend logic uses it.
    if (userId != null) request.fields['userid'] = userId.toString();

    if (title != null) request.fields['title'] = title;
    if (content != null) request.fields['content'] = content;
    if (categoryId != null) request.fields['category_id'] = categoryId.toString();
    
    for (var image in images) {
      final bytes = await image.readAsBytes();
      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
      final mimeTypeData = mimeType.split('/');
      request.files.add(http.MultipartFile.fromBytes(
        'images',
        bytes,
        filename: image.name,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ));
    }

    if (video != null) {
      final bytes = await video.readAsBytes();
      final mimeType = lookupMimeType(video.path) ?? 'video/mp4';
      final mimeTypeData = mimeType.split('/');
      request.files.add(http.MultipartFile.fromBytes(
        'video',
        bytes,
        filename: video.name,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ));
    }

    final streamAction = await request.send();
    final response = await http.Response.fromStream(streamAction);

    if (response.statusCode == 200) {
      return Blog.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update blog: ${response.body}');
    }
  }

  Future<void> deleteBlog(int id) async {
    final token = await AuthService.getToken();
    final response = await AuthHttpClient.instance.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete blog');
    }
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final token = await AuthService.getToken();
    final response = await AuthHttpClient.instance.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<List<Blog>> fetchRandomBlogs({int limit = 2}) async {
    final token = await AuthService.getToken();
    final response = await AuthHttpClient.instance.get(
      Uri.parse('$baseUrl/random?limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Blog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load random blogs');
    }
  }

  Future<void> recordBlogView(int blogId) async {
    final token = await AuthService.getToken();
    final userId = await AuthService.getUserId();
    
    final response = await AuthHttpClient.instance.post(
      Uri.parse('$baseUrl/view/$blogId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode({
        if (userId != null) 'userid': userId,
      }),
    );

    if (response.statusCode != 200) {
      print('Warning: Failed to record blog view: ${response.statusCode}');
    }
  }
}
