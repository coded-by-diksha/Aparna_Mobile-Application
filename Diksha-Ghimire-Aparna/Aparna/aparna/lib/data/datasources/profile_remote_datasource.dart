import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/user_model.dart';
import '../../core/constant/apiConstant.dart';
import '../../core/network/auth_http_client.dart';

class ProfileRemoteDataSource {
  final String baseUrl = ApiConstant.baseUrl;

  Future<UserModel> getUserProfile(int userId, String token) async {
    try {
      final response = await AuthHttpClient.instance.get(
        Uri.parse('${baseUrl}profile/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return UserModel.fromJson(data['profile']);
        } else {
          throw Exception(
            '${data['error'] ?? 'Failed to load profile'} (code ${response.statusCode})',
          );
        }
      } else {
        throw Exception('Failed to load profile (code ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error getting profile: $e');
    }
  }

  Future<UserModel> updateUserProfile({
    required int userId,
    required String username,
    required String email,
    required String phone,
    String? dateOfBirth,
    String? profilePhoto,
    required String token,
  }) async {
    try {
      // Build request body - only include profilephoto if explicitly provided
      final Map<String, dynamic> requestBody = {
        'username': username,
        'email': email,
        'phone': phone,
        'dateofbirth': dateOfBirth,
      };
      
      // Only add profilephoto if it's not null
      if (profilePhoto != null) {
        requestBody['profilephoto'] = profilePhoto;
      }
      
      final response = await AuthHttpClient.instance.put(
        Uri.parse('${baseUrl}profile/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return UserModel.fromJson(data['profile']);
        } else {
          throw Exception(data['error'] ?? 'Failed to update profile');
        }
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  Future<UserModel> updateProfilePhoto({
    required int userId,
    required String photoUrl,
    required String token,
  }) async {
    try {
      var request = await AuthHttpClient.instance.authorizedMultipartRequest(
        'PUT',
        Uri.parse('${baseUrl}profile/photo/$userId'),
      );
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Determine mime type and filename
      String? mimeType;
      String filename = photoUrl.split('/').last;

      if (photoUrl.toLowerCase().endsWith('.jpg') || photoUrl.toLowerCase().endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (photoUrl.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (photoUrl.toLowerCase().endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (photoUrl.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      } else {
        mimeType = 'image/jpeg';
        if (!filename.toLowerCase().contains('.')) {
          filename = '$filename.jpg';
        }
      }

      request.files.add(await http.MultipartFile.fromPath(
        'profilephoto', 
        photoUrl,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return UserModel.fromJson(data['profile']);
        } else {
          throw Exception(
            '${data['error'] ?? 'Failed to update profile photo'} (code ${response.statusCode})',
          );
        }
      } else {
        String errorMessage = 'Failed to update profile photo: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final data = json.decode(response.body) as Map<String, dynamic>;
            errorMessage = (data['error'] ?? data['message'] ?? errorMessage).toString();
          } catch (_) {
            final rawBody = response.body.trim();
            if (rawBody.isNotEmpty) {
              errorMessage = rawBody.length > 180
                  ? '${rawBody.substring(0, 180)}...'
                  : rawBody;
            }
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error updating profile photo: $e');
    }
  }
}
