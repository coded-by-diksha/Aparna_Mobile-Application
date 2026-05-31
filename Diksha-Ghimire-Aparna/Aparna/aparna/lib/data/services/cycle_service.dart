import 'dart:convert';
import '../../core/constant/apiConstant.dart';
import '../../core/network/auth_http_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CycleService {
  final String _baseUrl = '${ApiConstant.baseUrl}cycles';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _historyCachePrefix = 'cycle_history_cache_';
  static const String _predictionCachePrefix = 'cycle_prediction_cache_';

  Future<String> _cacheSuffix() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null || token.isEmpty) {
      return 'anonymous';
    }

    var hash = 0;
    for (final codeUnit in token.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }

    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));

    return hash.toUnsigned(32).toRadixString(16);
  }

  Future<String> _historyCacheKey() async =>
      '$_historyCachePrefix${await _cacheSuffix()}';

  Future<String> _predictionCacheKey() async =>
      '$_predictionCachePrefix${await _cacheSuffix()}';

  Future<void> _saveCache(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> _readCache(String key) async {
    return _secureStorage.read(key: key);
  }

  Future<List<dynamic>?> _readCachedHistory() async {
    try {
      final raw = await _readCache(await _historyCacheKey());
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
    } catch (e) {
      print('Error reading cached cycle history: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _readCachedPrediction() async {
    try {
      final raw = await _readCache(await _predictionCacheKey());
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (e) {
      print('Error reading cached cycle prediction: $e');
    }
    return null;
  }

  Future<List<dynamic>> fetchHistory() async {
    try {
      final response = await AuthHttpClient.instance.get(
        Uri.parse('$_baseUrl/history'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final history = json.decode(response.body) as List<dynamic>;
        await _saveCache(await _historyCacheKey(), response.body);
        return history;
      } else {
        final cachedHistory = await _readCachedHistory();
        if (cachedHistory != null) {
          return cachedHistory;
        }
        throw Exception('Failed to load history');
      }
    } catch (e) {
      print('Error fetching cycle history: $e');
      final cachedHistory = await _readCachedHistory();
      return cachedHistory ?? [];
    }
  }

  Future<Map<String, dynamic>> fetchPrediction() async {
    try {
      final response = await AuthHttpClient.instance.get(
        Uri.parse('$_baseUrl/prediction'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final prediction = json.decode(response.body) as Map<String, dynamic>;
        await _saveCache(await _predictionCacheKey(), response.body);
        return prediction;
      } else {
        final cachedPrediction = await _readCachedPrediction();
        if (cachedPrediction != null) {
          return cachedPrediction;
        }
        throw Exception('Failed to load prediction');
      }
    } catch (e) {
      print('Error fetching cycle prediction: $e');
      final cachedPrediction = await _readCachedPrediction();
      return cachedPrediction ?? {};
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
        final prediction = json.decode(response.body) as Map<String, dynamic>;
        await _saveCache(await _predictionCacheKey(), response.body);
        return prediction;
      } else {
        throw Exception('Failed to adjust prediction');
      }
    } catch (e) {
      print('Error adjusting prediction: $e');
      return {};
    }
  }
}

