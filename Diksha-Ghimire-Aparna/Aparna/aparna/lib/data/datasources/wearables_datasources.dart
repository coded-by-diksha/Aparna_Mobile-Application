import 'dart:convert';
import '../models/health_model.dart';
import '../../core/constant/apiConstant.dart';
import '../../core/network/auth_http_client.dart';

class WearablesRemoteDataSource {


  final String baseUrl = ApiConstant.baseUrl;

  
  Future<void> addHealthData(HealthModel healthModel) async {
    try {
      final response = await AuthHttpClient.instance.post(
        Uri.parse('${baseUrl}health'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(healthModel.toJson()),
      );
      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to add health data');
      }
    }
    catch (e) {
      throw Exception('Error adding health data: $e');
    }
  }

  Future<void> updateHealthData(HealthModel healthModel) async {
    try {
      final response = await AuthHttpClient.instance.put(
        Uri.parse('${baseUrl}health/${healthModel.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(healthModel.toJson()),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return;
        } else {
          throw Exception('Failed to update health data');
        }
      } else {
        throw Exception('Failed to update health data');
      }
    } catch (e) {
      throw Exception('Error updating health data: $e');
    }
  }

  Future<HealthModel> getHealthData(int userId) async {
    try {
      final response = await AuthHttpClient.instance.get(
        Uri.parse('${baseUrl}health/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return HealthModel.fromJson(data['healthData']);
        }
      }
      throw Exception('Failed to get health data');
    }
    catch (e) {
      throw Exception('Error getting health data: $e');
    }
  }
}