import 'dart:convert';
import 'dart:developer';
import '../models/chatModel.dart';
import '../../core/constant/apiConstant.dart';
import '../../core/network/auth_http_client.dart';

class AamaRemoteDataSource {
  final String baseUrl = ApiConstant.baseUrl;

  Future<String> sendMessage(String message, String token, {String language = 'en'}) async {
    log('Sending message to Aama: $message in language: $language');
    log('Token: ${token.isNotEmpty ? "Present" : "MISSING"}');
    try {
      final headers = {
        'Content-Type': 'application/json',
      };
      
      // Only add Authorization header if token is not empty
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await AuthHttpClient.instance.post(
        Uri.parse('${baseUrl}aama/chat'),
        headers: headers,
        body: json.encode({
          'message': message,
          'language': language,
        }),
        requiresAuth: token.isNotEmpty,
      );
      log(response.statusCode.toString());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Only store chat message if user_id is present
          if (data['user_id'] != null) {
            await storeChatMessage(
              userId: data['user_id'] as int,
              message: message,
              response: data['response'],
              token: token,
            );
          }
          return data['response'];
        } else {
          throw Exception('Failed to get response from Aama');
        }
      
      } else {
        throw Exception('Failed to connect to Aama: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error communicating with Aama: $e');
    }
  }

  Future<String> getGreeting(String userName, String token, {String language = 'en'}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };
      
      // Only add Authorization header if token is not empty
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await AuthHttpClient.instance.post(
        Uri.parse('${baseUrl}aama/greeting'),
        headers: headers,
        body: json.encode({
          'userName': userName,
          'language': language,
        }),
        requiresAuth: token.isNotEmpty,
      );
      
      print('Greeting response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['response'];
        } else {
          throw Exception('Failed to get greeting from Aama');
        }
      } else {
        throw Exception('Failed to connect to Aama: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting greeting: $e');
    }
  }

  Future<void> storeChatMessage({
    required int userId,
    required String message,
    required String response,
    required String token,
  }) async {
    try {
      final httpResponse = await AuthHttpClient.instance.post(
        Uri.parse('${baseUrl}aama/storeChat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'user_id': userId,
          'message': message,
          'response': response,
        }),
        requiresAuth: token.isNotEmpty,
      );
      log('Store chat response status: ${httpResponse.statusCode}');

      if (httpResponse.statusCode == 200) {
        final data = json.decode(httpResponse.body);
        if (data['success'] != true) {
          throw Exception('Failed to store chat message');
        }
      } else {
        throw Exception('Failed to store chat: ${httpResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('Error storing chat message: $e');
    }
  }

  Future<List<ChatMessage>> getChatHistory({
    required int userId,
    required String token,
  }) async {
    try {
      final response = await AuthHttpClient.instance.get(
        Uri.parse('${baseUrl}aama/chathistory?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        requiresAuth: token.isNotEmpty,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> chatHistoryJson = data['chatHistory'];
          return chatHistoryJson
              .map((json) => ChatMessage.fromJson(json))
              .toList();
        } else {
          throw Exception('Failed to get chat history');
        }
      } else {
        throw Exception('Failed to connect to server: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting chat history: $e');
    }
  }
}
