import 'dart:convert';
import '../../core/constant/apiConstant.dart';
import '../../core/network/auth_http_client.dart';

class AdminService {
  static const String baseUrl = '${ApiConstant.baseUrl}admin';

  Future<Map<String, dynamic>> fetchStats() async {
    try {
      print('Fetching stats from $baseUrl/stats');
      final response = await AuthHttpClient.instance.get(
        Uri.parse('$baseUrl/stats'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error fetching stats: ${response.statusCode} - ${response.body}');
        return {};
      }
    } catch (e) {
      print('Exception fetching stats: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      print('Fetching users from $baseUrl/users...');
      final response = await AuthHttpClient.instance.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((u) => u as Map<String, dynamic>).toList();
      } else {
        print('Error fetching users: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception fetching users: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchBlogs() async {
    try {
      final url = '${ApiConstant.baseUrl}blogs';
      print('DEBUG: Fetching admin blogs from $url');
      final response = await AuthHttpClient.instance.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('DEBUG: Fetch blogs response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('DEBUG: Received ${data.length} blogs');
        return data.map((b) => b as Map<String, dynamic>).toList();
      } else {
        print('ERROR: Failed to fetch blogs: ${response.body}');
        return [];
      }
    } catch (e) {
      print('EXCEPTION in fetchBlogs: $e');
      return [];
    }
  }

  Future<void> deleteBlog(String id) async {
    try {
      final url = '${ApiConstant.baseUrl}blogs/$id';
      print('DEBUG: Deleting blog from URL: $url');
      print('DEBUG: Blog ID: $id');
      
      final response = await AuthHttpClient.instance.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print('DEBUG: Delete blog response status: ${response.statusCode}');
      print('DEBUG: Delete blog response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else {
        final errorBody = response.body;
        print('Error deleting blog: ${response.statusCode} - $errorBody');
        throw Exception('Failed to delete blog: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('Exception in deleteBlog: $e');
      rethrow;
    }
  }

  // Expert Help APIs
  Future<List<Map<String, dynamic>>> fetchExperts() async {
    try {
      final url = '${ApiConstant.baseUrl}experthelp';
      final response = await AuthHttpClient.instance.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        print('Error fetching experts: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception in fetchExperts: $e');
      return [];
    }
  }

  Future<bool> createExpert(Map<String, dynamic> data) async {
    try {
      final url = '${ApiConstant.baseUrl}experthelp';
      final response = await AuthHttpClient.instance.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 201;
    } catch (e) {
      print('Exception in createExpert: $e');
      return false;
    }
  }

  Future<bool> updateExpert(String id, Map<String, dynamic> data) async {
    try {
      final url = '${ApiConstant.baseUrl}experthelp/$id';
      final response = await AuthHttpClient.instance.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Exception in updateExpert: $e');
      return false;
    }
  }

  Future<bool> deleteExpert(String id) async {
    try {
      final url = '${ApiConstant.baseUrl}experthelp/$id';
      final response = await AuthHttpClient.instance
          .delete(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Exception in deleteExpert: $e');
      return false;
    }
  }
  Future<bool> deleteUserByID(String id) async {
    try {
      final url = '${ApiConstant.baseUrl}admin/users/delete/$id';
      final response = await AuthHttpClient.instance
          .delete(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('Exception in deleteUserByID: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> createUserByAdmin({
    required String username,
    required String email,
    required String password,
    String? phone,
    String? dateofbirth,
    String role = 'user',
  }) async {
    try {
      final url = '${ApiConstant.baseUrl}admin/users';
      final response = await AuthHttpClient.instance
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'username': username,
              'email': email,
              'password': password,
              'phone': (phone ?? '').trim().isEmpty ? null : phone,
              'dateofbirth': (dateofbirth ?? '').trim().isEmpty ? null : dateofbirth,
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      print('Error creating user by admin: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Exception in createUserByAdmin: $e');
      return null;
    }
  }
}
