import 'dart:convert';

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  if (v is num) return v.toInt();
  return 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  if (v is num) return v.toDouble();
  return 0.0;
}

HealthDataHistory _healthDataHistoryFromJson(dynamic v) {
  if (v == null) return HealthDataHistory.empty;
  if (v is String) return HealthDataHistory.fromJson(Map<String, dynamic>.from(jsonDecode(v)));
  if (v is Map<String, dynamic>) return HealthDataHistory.fromJson(v);
  if (v is Map) return HealthDataHistory.fromJson(Map<String, dynamic>.from(v));
  return HealthDataHistory.empty;
}

class HealthDataHistory {
  final int steps;
  final int calories;
  final double distance;
  final double sleepHours;
  final int waterIntake;

  HealthDataHistory({
    required this.steps,
    required this.calories,
    required this.distance,
    required this.sleepHours,
    required this.waterIntake,
  });

  factory HealthDataHistory.fromJson(Map<String, dynamic> json) {
    return HealthDataHistory(
      steps: _toInt(json['steps']),
      calories: _toInt(json['calories']),
      distance: _toDouble(json['distance']),
      sleepHours: _toDouble(json['sleep_hours']),
      waterIntake: _toInt(json['water_intake']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps,
      'calories': calories,
      'distance': distance,
      'sleep_hours': sleepHours,
      'water_intake': waterIntake,
    };
  }

  static HealthDataHistory get empty => HealthDataHistory(
        steps: 0,
        calories: 0,
        distance: 0.0,
        sleepHours: 0.0,
        waterIntake: 0,
      );
}

class HealthModel {
  final int userId;
  final int heartRate;
  final String activityIntensity;
  final HealthDataHistory healthDataHistory;
  final String activityRecognition;
  final String location;
  final String deviceName;
  final String deviceType;
  final String deviceToken;
  final DateTime? lastUpdated;

  HealthModel({
    required this.userId,
    required this.heartRate,
    required this.activityIntensity,
    required this.healthDataHistory,
    required this.activityRecognition,
    required this.location,
    required this.deviceName,
    required this.deviceType,
    required this.deviceToken,
    this.lastUpdated,
  });

  factory HealthModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseLastUpdated(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return HealthModel(
      userId: _toInt(json['userId'] ?? json['user_id']),
      heartRate: _toInt(json['heartRate'] ?? json['heart_rate']),
      activityIntensity: json['activityIntensity']?.toString() ?? json['activity_intensity']?.toString() ?? '',
      healthDataHistory: _healthDataHistoryFromJson(json['healthDataHistory'] ?? json['health_data_history']),
      activityRecognition: json['activityRecognition']?.toString() ?? json['activity_recognition']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      deviceName: json['deviceName']?.toString() ?? json['device_name']?.toString() ?? '',
      deviceType: json['deviceType']?.toString() ?? json['device_type']?.toString() ?? '',
      deviceToken: json['deviceToken']?.toString() ?? json['device_token']?.toString() ?? '',
      lastUpdated: parseLastUpdated(json['lastUpdated'] ?? json['last_updated'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'heartRate': heartRate,
      'activityIntensity': activityIntensity,
      'healthDataHistory': healthDataHistory.toJson(),
      'activityRecognition': activityRecognition,
      'location': location,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'deviceToken': deviceToken,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Placeholder when backend has no health record yet (e.g. after connect, before first sync).
  static HealthModel empty(int userId) => HealthModel(
        userId: userId,
        heartRate: 0,
        activityIntensity: '',
        healthDataHistory: HealthDataHistory.empty,
        activityRecognition: '',
        location: '',
        deviceName: '',
        deviceType: '',
        deviceToken: '',
        lastUpdated: null,
      );
}
