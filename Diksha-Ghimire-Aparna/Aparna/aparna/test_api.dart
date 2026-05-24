import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('Testing API connectivity...');
  
  try {
    // Test basic connectivity
    final response = await http.get(
      Uri.parse('http://192.168.100.182:3000/'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(Duration(seconds: 10));
    
    print('Server response status: ${response.statusCode}');
    print('Server response body: ${response.body}');
    
    // Test login endpoint
    final loginResponse = await http.post(
      Uri.parse('http://192.168.100.182:3000/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'identifier': 'ananya.sharma',
        'password': 'TestPassword123'
      }),
    ).timeout(Duration(seconds: 10));
    
    print('Login response status: ${loginResponse.statusCode}');
    print('Login response body: ${loginResponse.body}');
    
  } catch (e) {
    print('Error: $e');
  }
}