import 'dart:convert';
import '../../core/constant/apiConstant.dart';
import '../../core/network/auth_http_client.dart';

class CycleService {
  final String _baseUrl = '${ApiConstant.baseUrl}cycles';

  Future<List<dynamic>> fetchHistory() async {
    try {
      final response = await AuthHttpClient.instance.get(
        Uri.parse('$_baseUrl/history'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      print('Error fetching cycle history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchPrediction() async {
    try {
      final response = await AuthHttpClient.instance.get(
        Uri.parse('$_baseUrl/prediction'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load prediction');
      }
    } catch (e) {
      print('Error fetching cycle prediction: $e');
      return {};
    }
  }

  Future<bool> recordPeriod({
    required String startDate,
    int? mensesLength,
    String? notes,
    int? moodScore,
    List<String>? emotions,
    int? flowLevel,
  }) async {
    try {
      final response = await AuthHttpClient.instance.post(
        Uri.parse('$_baseUrl/record'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'period_start_date': startDate,
          'menses_length': mensesLength,
          'notes': notes,
          'mood_score': moodScore,
          'emotions': emotions,
          'flow_level': flowLevel,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error recording period: $e');
      return false;
    }
  }

  Future<bool> addDailyLog({
    required String logDate,
    required String feeling,
    int? moodScore,
    int? flowLevel,
  }) async {
    try {
      final response = await AuthHttpClient.instance.post(
        Uri.parse('$_baseUrl/daily-log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'log_date': logDate,
          'feeling': feeling,
          'mood_score': moodScore,
          'flow_level': flowLevel,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error adding daily log: $e');
      return false;
    }
  }

  Future<bool> deletePeriod(int id) async {
    try {
      final response = await AuthHttpClient.instance.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting period: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> adjustPrediction({
    required String predictedDate,
    int dayShift = 1,
  }) async {
    try {
      final response = await AuthHttpClient.instance.post(
        Uri.parse('$_baseUrl/adjust-prediction'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'predictedDate': predictedDate,
          'dayShift': dayShift,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to adjust prediction');
      }
    } catch (e) {
      print('Error adjusting prediction: $e');
      return {};
    }
  }
}

