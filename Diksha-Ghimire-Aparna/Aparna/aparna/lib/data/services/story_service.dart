import 'dart:convert';
import '../../core/constant/apiConstant.dart';
import '../../core/network/auth_http_client.dart';
import '../models/story_model.dart';

class StoryService {
  static const String baseUrl = '${ApiConstant.baseUrl}blogs/stories';

  Future<List<UserStory>> fetchStories() async {
    final response = await AuthHttpClient.instance.get(
      Uri.parse('$baseUrl/all'),
      requiresAuth: false,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => UserStory.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load stories');
    }
  }

  Future<UserStory> createStory({
    required String title,
    required String content,
    required bool isAnonymous,
    String? authorName,
  }) async {
    final response = await AuthHttpClient.instance.post(
      Uri.parse('$baseUrl/create'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'title': title,
        'content': content,
        'is_anonymous': isAnonymous,
        'author_name': authorName,
      }),
    );

    if (response.statusCode == 201) {
      return UserStory.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create story: ${response.body}');
    }
  }

  Future<void> deleteStory(int id) async {
    final response = await AuthHttpClient.instance.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete story');
    }
  }
}
