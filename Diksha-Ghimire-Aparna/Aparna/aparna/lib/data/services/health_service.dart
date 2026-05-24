import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:health/health.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constant/apiConstant.dart';
import '../../core/network/auth_http_client.dart';
import '../models/health_model.dart';
import '../../presentation/bloc/health_dashboard/health_dashboard_state.dart';

/// Represents a connectable health data source shown on Add Wearable screen.
class ConnectableDeviceOption {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<HealthDataType> healthTypes;

  const ConnectableDeviceOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.healthTypes,
  });
}

class HealthService {
  final health = Health();
  final String _baseUrl = '${ApiConstant.baseUrl}health';
  bool _configured = false;

  HealthService();

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await health.configure();
    _configured = true;
  }

  // --- Backend API (synced with Node backend) ---

  Future<String?> _getReadableLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final parts = <String>[
            if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) placemark.subLocality!,
            if (placemark.locality != null && placemark.locality!.isNotEmpty) placemark.locality!,
            if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) placemark.administrativeArea!,
            if (placemark.country != null && placemark.country!.isNotEmpty) placemark.country!,
          ];
          final readableLocation = parts.join(', ');
          if (readableLocation.isNotEmpty) {
            return readableLocation;
          }
        }
      } catch (e) {
        print('Error reverse geocoding location: $e');
      }

      return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  Future<HealthModel?> syncCurrentLocation(
    dynamic userId, {
    HealthModel? currentData,
  }) async {
    try {
      final readableLocation = await _getReadableLocation();
      if (readableLocation == null || readableLocation.isEmpty) {
        return currentData;
      }

      final existingData = currentData ?? await fetchHealthData(userId);
      if (existingData != null && existingData.location == readableLocation) {
        return existingData;
      }

      final uid = userId is int ? userId : 0;
      final updatedData = HealthModel(
        userId: existingData?.userId ?? uid,
        heartRate: existingData?.heartRate ?? 0,
        activityIntensity: existingData?.activityIntensity ?? '',
        healthDataHistory: existingData?.healthDataHistory ?? HealthDataHistory.empty,
        activityRecognition: existingData?.activityRecognition ?? '',
        location: readableLocation,
        deviceName: existingData?.deviceName ?? '',
        deviceType: existingData?.deviceType ?? '',
        deviceToken: existingData?.deviceToken ?? '',
        lastUpdated: DateTime.now(),
      );

      if (existingData == null) {
        await recordHealthData(updatedData);
      } else {
        await updateHealthData(userId, updatedData);
      }

      return updatedData;
    } catch (e) {
      print('Error syncing location to health data: $e');
      return currentData;
    }
  }

  /// GET /health/:userId - fetch health data for user from backend
  Future<HealthModel?> fetchHealthData(dynamic userId) async {
    try {
      final response = await AuthHttpClient.instance.get(
        Uri.parse('$_baseUrl/${userId.toString()}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty) return null;
        final json = jsonDecode(body) as Map<String, dynamic>?;
        return json != null ? HealthModel.fromJson(json) : null;
      }
      if (response.statusCode == 404) return null;
      throw Exception('Failed to load health data: ${response.statusCode}');
    } catch (e) {
      print('Error fetching health data: $e');
      rethrow;
    }
  }

  /// Sync real data from Health Connect / Apple Health (Fitbit, Google Fit, etc.).
  /// [deviceName], [deviceType], [deviceToken] are the selected source so backend and Health tab show "Connected".
  Future<HealthModel?> syncHealthDataFromDevice(
    dynamic userId, {
    required String deviceName,
    required String deviceType,
    required String deviceToken,
  }) async {
    try {
      await requestAuthorization();
      await _requestSleepReadAuthorization();

      final stepsToday = await getTotalStepsToday() ?? 0;
      final heartRate = await _getLatestHeartRate();
      final sleepHours = await _getSleepHoursLastNight();
      final waterMl = await _getWaterIntakeToday();
      final calories = await _getCaloriesFromDevice();
      print('[HealthService] Synced → steps: $stepsToday, heartRate: $heartRate, sleep: ${sleepHours.toStringAsFixed(1)}h, water: ${waterMl.round()}ml, calories: ${calories}kcal');

      var currentData = await fetchHealthData(userId);
      final uid = userId is int ? userId : 0;
      final distance = (stepsToday * 0.0008);
      String activityIntensity = 'Low';
      if (stepsToday > 10000) {
        activityIntensity = 'High';
      } else if (stepsToday > 5000) {
        activityIntensity = 'Moderate';
      }
      final location = currentData?.location ?? '';

      final syncedWater = waterMl > 0
          ? waterMl.round()
          : (currentData?.healthDataHistory.waterIntake ?? 0);

        final syncedSleepHours = sleepHours > 0
          ? sleepHours
          : (currentData?.healthDataHistory.sleepHours ?? 0.0);

      final syncedData = HealthModel(
        userId: currentData?.userId ?? uid,
        heartRate: heartRate,
        activityIntensity: activityIntensity,
        healthDataHistory: HealthDataHistory(
          steps: stepsToday,
          calories: calories,
          distance: distance,
          sleepHours: syncedSleepHours,
          waterIntake: syncedWater,
        ),
        activityRecognition: currentData?.activityRecognition ?? '',
        location: location,
        deviceName: deviceName,
        deviceType: deviceType,
        deviceToken: deviceToken,
        lastUpdated: DateTime.now(),
      );

      await updateHealthData(userId, syncedData);
      return syncedData;
    } catch (e) {
      print('Error syncing health data from device: $e');
      return null;
    }
  }

  /// Wide query window — Health Connect is brutally literal about date ranges.
  static final _queryWindow = const Duration(days: 7);

  Future<int> _getLatestHeartRate() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final points = await health.getHealthDataFromTypes(
        startTime: now.subtract(_queryWindow),
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );
      if (points.isEmpty) return 0;
      points.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final v = points.first.value;
      final bpm = v is NumericHealthValue ? v.numericValue.round() : 0;
      return bpm > 0 ? bpm : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Read sleep duration from the most recent night.
  /// Uses a 7-day window because Fitbit timestamps sleep sessions starting
  /// from the previous evening — a narrow "today-only" window misses them.
  Future<double> _getSleepHoursLastNight() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(_queryWindow);
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final nightWindowStart = todayMidnight.subtract(const Duration(hours: 12));

      try {
        final sessions = await health.getHealthDataFromTypes(
          startTime: start,
          endTime: now,
          types: [HealthDataType.SLEEP_SESSION],
        );
        if (sessions.isNotEmpty) {
          final lastNightSessions = sessions.where((p) {
            final overlapsNight = p.dateTo.isAfter(nightWindowStart) && p.dateFrom.isBefore(now);
            final endedToday = p.dateTo.isAfter(todayMidnight);
            return overlapsNight || endedToday;
          }).toList();

          if (lastNightSessions.isNotEmpty) {
            final mins = _sumMergedSleepMinutes(lastNightSessions, nightWindowStart, now);
            if (mins >= 30 && mins <= 16 * 60) {
              print('[HealthService] Sleep from SLEEP_SESSION: ${mins.toStringAsFixed(0)} min');
              return mins / 60.0;
            }
          }
        }
      } catch (_) {
        print('[HealthService] SLEEP_SESSION query failed, trying stage fallback');
      }

      // Fallback 1: use SLEEP_ASLEEP records for last-night window.
      final recentPoints = await health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.SLEEP_ASLEEP],
      );

      if (recentPoints.isNotEmpty) {
        final lastNightSleep = recentPoints
            .where((p) => p.dateTo.isAfter(nightWindowStart) && p.dateFrom.isBefore(now))
            .toList();

        if (lastNightSleep.isNotEmpty) {
          final mins = _sumMergedSleepMinutes(lastNightSleep, nightWindowStart, now);
          if (mins >= 30 && mins <= 16 * 60) {
            print('[HealthService] Sleep from SLEEP_ASLEEP: ${mins.toStringAsFixed(0)} min');
            return mins / 60.0;
          }
        }
      }

      // Fallback 2: merge staged sleep intervals to avoid overlap double-counting.
      final stageTypes = [
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_REM,
      ];
      final intervals = <Map<String, DateTime>>[];

      for (final type in stageTypes) {
        final points = await health.getHealthDataFromTypes(
          startTime: start,
          endTime: now,
          types: [type],
        );
        for (final p in points) {
          final clippedStart = p.dateFrom.isBefore(nightWindowStart) ? nightWindowStart : p.dateFrom;
          final clippedEnd = p.dateTo.isAfter(now) ? now : p.dateTo;
          if (clippedEnd.isAfter(clippedStart)) {
            intervals.add({'start': clippedStart, 'end': clippedEnd});
          }
        }
      }

      if (intervals.isNotEmpty) {
        intervals.sort((a, b) => a['start']!.compareTo(b['start']!));
        final merged = <Map<String, DateTime>>[];
        for (final interval in intervals) {
          if (merged.isEmpty || interval['start']!.isAfter(merged.last['end']!)) {
            merged.add({'start': interval['start']!, 'end': interval['end']!});
          } else if (interval['end']!.isAfter(merged.last['end']!)) {
            merged.last['end'] = interval['end']!;
          }
        }

        double minutes = 0;
        for (final m in merged) {
          minutes += m['end']!.difference(m['start']!).inMinutes;
        }

        if (minutes >= 30 && minutes <= 16 * 60) {
          print('[HealthService] Sleep from merged stages: ${minutes.toStringAsFixed(0)} min');
          return minutes / 60.0;
        }
      }

      print('[HealthService] No usable sleep data found for last-night window');
      return 0.0;
    } catch (e) {
      print('[HealthService] Sleep query error: $e');
      return 0.0;
    }
  }

  Future<bool> _requestSleepReadAuthorization() async {
    try {
      await _ensureConfigured();
      const sleepTypes = [
        HealthDataType.SLEEP_SESSION,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_AWAKE,
      ];
      final permissions = sleepTypes.map((_) => HealthDataAccess.READ).toList();
      return await health.requestAuthorization(sleepTypes, permissions: permissions);
    } catch (e) {
      print('[HealthService] Sleep permission request failed: $e');
      return false;
    }
  }

  double _sumMergedSleepMinutes(
    List<HealthDataPoint> points,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    final intervals = <Map<String, DateTime>>[];

    for (final p in points) {
      final start = p.dateFrom.isBefore(windowStart) ? windowStart : p.dateFrom;
      final end = p.dateTo.isAfter(windowEnd) ? windowEnd : p.dateTo;
      if (end.isAfter(start)) {
        intervals.add({'start': start, 'end': end});
      }
    }

    if (intervals.isEmpty) return 0.0;

    intervals.sort((a, b) => a['start']!.compareTo(b['start']!));
    final merged = <Map<String, DateTime>>[];

    for (final interval in intervals) {
      if (merged.isEmpty || interval['start']!.isAfter(merged.last['end']!)) {
        merged.add({'start': interval['start']!, 'end': interval['end']!});
      } else if (interval['end']!.isAfter(merged.last['end']!)) {
        merged.last['end'] = interval['end']!;
      }
    }

    double minutes = 0;
    for (final m in merged) {
      minutes += m['end']!.difference(m['start']!).inMinutes;
    }

    return minutes;
  }

  /// Read today's water intake from Health Connect.
  /// Uses a 7-day query window (Health Connect requires it), then filters
  /// to today's records. Health Connect stores WATER in LITERS.
  Future<double> _getWaterIntakeToday() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(_queryWindow);
      final todayMidnight = DateTime(now.year, now.month, now.day);

      final points = await health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.WATER],
      );

      double totalLiters = 0;
      for (final p in points) {
        final isToday = p.dateFrom.isAfter(todayMidnight) ||
            p.dateFrom.isAtSameMomentAs(todayMidnight);
        if (isToday) {
          final v = p.value;
          if (v is NumericHealthValue) {
            totalLiters += v.numericValue.toDouble();
          }
        }
      }
      return totalLiters * 1000;
    } catch (_) {
      return 0;
    }
  }

  /// Read today's calorie burn from Health Connect / Fitbit.
  /// Fetches TOTAL_CALORIES_BURNED (preferred) or falls back to ACTIVE_ENERGY_BURNED.
  Future<int> _getCaloriesFromDevice() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);

      // Try TOTAL_CALORIES_BURNED first (Health Connect total burn)
      var points = await health.getHealthDataFromTypes(
        startTime: todayMidnight,
        endTime: now,
        types: [HealthDataType.TOTAL_CALORIES_BURNED],
      );

      int totalCals = 0;
      for (final p in points) {
        if (p.value is NumericHealthValue) {
          totalCals += (p.value as NumericHealthValue).numericValue.round();
        }
      }

      if (totalCals > 0) {
        print('[HealthService] Calories (from TOTAL_CALORIES_BURNED): $totalCals');
        return totalCals;
      }

      // Fallback: use active burned energy when total calories are unavailable.
      points = await health.getHealthDataFromTypes(
        startTime: todayMidnight,
        endTime: now,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );

      for (final p in points) {
        if (p.value is NumericHealthValue) {
          totalCals += (p.value as NumericHealthValue).numericValue.round();
        }
      }

      if (totalCals > 0) {
        print('[HealthService] Calories (from ACTIVE_ENERGY_BURNED): $totalCals');
        return totalCals;
      }

      print('[HealthService] No calorie data found, returning 0');
      return 0;
    } catch (e) {
      print('[HealthService] Error reading calories: $e');
      return 0;
    }
  }

  /// POST /health/record - record health data (userId from JWT or body)
  Future<HealthModel?> recordHealthData(HealthModel data) async {
    try {
      final response = await AuthHttpClient.instance.post(
        Uri.parse('$_baseUrl/record'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data.toJson()),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        return json != null ? HealthModel.fromJson(json) : null;
      }
      throw Exception('Failed to record health data: ${response.statusCode}');
    } catch (e) {
      print('Error recording health data: $e');
      rethrow;
    }
  }

  /// PUT /health/:userId - update health data
  Future<HealthModel?> updateHealthData(dynamic userId, HealthModel data) async {
    try {
      final response = await AuthHttpClient.instance.put(
        Uri.parse('$_baseUrl/${userId.toString()}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data.toJson()),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        return json != null ? HealthModel.fromJson(json) : null;
      }
      throw Exception('Failed to update health data: ${response.statusCode}');
    } catch (e) {
      print('Error updating health data: $e');
      rethrow;
    }
  }

  /// DELETE /health/:userId
  Future<void> deleteHealthData(dynamic userId) async {
    try {
      final response = await AuthHttpClient.instance.delete(
        Uri.parse('$_baseUrl/${userId.toString()}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete health data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting health data: $e');
      rethrow;
    }
  }

  // --- Device / wearables (health package) ---
  // Types read from Health Connect (Android) / Apple Health (iOS).
  // Fitbit, Google Fit, etc. write here when connected to Health Connect.
  final types = [
    HealthDataType.STEPS,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.WATER,
  ];

  /// Device/source options that can be "connected" via health permissions.
  static List<ConnectableDeviceOption> getConnectableDeviceOptions() {
    return [
      ConnectableDeviceOption(
        id: 'steps',
        name: 'Steps & Activity',
        description: 'Sync steps and activity from your phone or wearable',
        icon: 'directions_walk',
        healthTypes: [HealthDataType.STEPS],
      ),
      ConnectableDeviceOption(
        id: 'blood_glucose',
        name: 'Blood Glucose',
        description: 'Read blood glucose data from supported devices',
        icon: 'monitor_heart',
        healthTypes: [HealthDataType.BLOOD_GLUCOSE],
      ),
      ConnectableDeviceOption(
        id: 'all',
        name: 'Full Health Sync',
        description: 'Steps, blood glucose, and write access',
        icon: 'fitness_center',
        healthTypes: [HealthDataType.STEPS, HealthDataType.BLOOD_GLUCOSE],
      ),
    ];
  }

  Future<bool> requestAuthorization() async {
    await _ensureConfigured();
    final permissions = types.map((_) => HealthDataAccess.READ).toList();
    return await health.requestAuthorization(types, permissions: permissions);
  }

  /// Request authorization for specific health data types (e.g. for one "device").
  Future<bool> requestAuthorizationForTypes(List<HealthDataType> typeList) async {
    await _ensureConfigured();
    final permissions = typeList.map((_) => HealthDataAccess.READ).toList();
    return await health.requestAuthorization(typeList, permissions: permissions);
  }

  Future<List<HealthDataPoint>> getHealthDataFromLast24Hours() async {
    await _ensureConfigured();
    var now = DateTime.now();
    return await health.getHealthDataFromTypes(
      startTime: now.subtract(const Duration(days: 1)),
      endTime: now,
      types: types,
    );
  }

  Future<bool> requestWritePermissions() async {
    var writeTypes = [
      HealthDataType.STEPS,
      HealthDataType.BLOOD_GLUCOSE,
      HealthDataType.WATER,
    ];
    var permissions = writeTypes.map((_) => HealthDataAccess.READ_WRITE).toList();
    return await health.requestAuthorization(writeTypes, permissions: permissions);
  }

  /// Log water intake (in ml) to Health Connect and update the backend.
  Future<bool> logWaterIntake(int ml, dynamic userId) async {
    try {
      await _ensureConfigured();
      final granted = await requestWritePermissions();
      if (!granted) return false;

      final now = DateTime.now();
      final liters = ml / 1000.0;
      final written = await health.writeHealthData(
        value: liters,
        type: HealthDataType.WATER,
        startTime: now.subtract(const Duration(seconds: 1)),
        endTime: now,
        recordingMethod: RecordingMethod.manual,
      );
      if (!written) return false;

      // Also update backend so the number shows even if Health Connect
      // read-back is delayed.
      if (userId != null) {
        final current = await fetchHealthData(userId);
        if (current != null) {
          final oldWater = current.healthDataHistory.waterIntake;
          final updated = HealthModel(
            userId: current.userId,
            heartRate: current.heartRate,
            activityIntensity: current.activityIntensity,
            healthDataHistory: HealthDataHistory(
              steps: current.healthDataHistory.steps,
              calories: current.healthDataHistory.calories,
              distance: current.healthDataHistory.distance,
              sleepHours: current.healthDataHistory.sleepHours,
              waterIntake: oldWater + ml,
            ),
            activityRecognition: current.activityRecognition,
            location: current.location,
            deviceName: current.deviceName,
            deviceType: current.deviceType,
            deviceToken: current.deviceToken,
            lastUpdated: DateTime.now(),
          );
          await updateHealthData(userId, updated);
        }
      }
      return true;
    } catch (e) {
      print('[HealthService] logWaterIntake error: $e');
      return false;
    }
  }

  Future<bool> logSleepHours(double hours, dynamic userId) async {
    try {
      await _ensureConfigured();
      final granted = await requestAuthorization();
      if (!granted) return false;

      // Log sleep in minutes (Health Connect uses minutes)
      final minutes = (hours * 60).toInt();
      if (minutes < 1) return false;

      final now = DateTime.now();
      final startTime = now.subtract(Duration(hours: hours.toInt()));
      
      final written = await health.writeHealthData(
        value: minutes.toDouble(),
        type: HealthDataType.SLEEP_ASLEEP,
        startTime: startTime,
        endTime: now,
        recordingMethod: RecordingMethod.manual,
      );
      if (!written) return false;

      // Also update backend  
      if (userId != null) {
        final current = await fetchHealthData(userId);
        if (current != null) {
          final updated = HealthModel(
            userId: current.userId,
            heartRate: current.heartRate,
            activityIntensity: current.activityIntensity,
            healthDataHistory: HealthDataHistory(
              steps: current.healthDataHistory.steps,
              calories: current.healthDataHistory.calories,
              distance: current.healthDataHistory.distance,
              sleepHours: hours,
              waterIntake: current.healthDataHistory.waterIntake,
            ),
            activityRecognition: current.activityRecognition,
            location: current.location,
            deviceName: current.deviceName,
            deviceType: current.deviceType,
            deviceToken: current.deviceToken,
            lastUpdated: DateTime.now(),
          );
          await updateHealthData(userId, updated);
        }
      }
      return true;
    } catch (e) {
      print('[HealthService] logSleepHours error: $e');
      return false;
    }
  }

  Future<bool> writeHealthData({
    required double value,
    required HealthDataType dataType,
    required DateTime startTime,
    required DateTime endTime,
    RecordingMethod? recordingMethod,
  }) async {
    return await health.writeHealthData(
      value: value,
      type: dataType,
      startTime: startTime,
      endTime: endTime,
      recordingMethod: recordingMethod ?? RecordingMethod.automatic,
    );
  }

  Future<int?> getTotalStepsToday() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      // Use 48h window — Health Connect can be finicky with exact boundaries
      final windowStart = todayMidnight.subtract(const Duration(hours: 24));

      // Try the aggregated API first
      var aggregated = await health.getTotalStepsInInterval(todayMidnight, now);
      if (aggregated != null && aggregated > 0) {
        print('[HealthService] Steps (aggregated): $aggregated');
        return aggregated;
      }

      // Fallback: wider window, filter to today (handles timezone/edge cases)
      final points = await health.getHealthDataFromTypes(
        startTime: windowStart,
        endTime: now,
        types: [HealthDataType.STEPS],
      );
      if (points.isNotEmpty) {
        int total = 0;
        final seen = <String>{};
        for (final p in points) {
          final isToday = p.dateFrom.isAfter(todayMidnight) ||
              p.dateFrom.isAtSameMomentAs(todayMidnight);
          if (!isToday) continue;
          final key = '${p.dateFrom.millisecondsSinceEpoch}_${p.dateTo.millisecondsSinceEpoch}';
          if (seen.add(key)) {
            final v = p.value;
            if (v is NumericHealthValue) {
              total += v.numericValue.round();
            }
          }
        }
        if (total > 0) {
          print('[HealthService] Steps (summed ${points.length} records, today): $total');
          return total;
        }
      }

      print('[HealthService] No step data found for today');
      return null;
    } catch (e) {
      print('[HealthService] Error reading steps: $e');
      return null;
    }
  }

  Future<List<HealthDataPoint>> getTotalStepsInInterval(DateTime start, DateTime end) async {
    await _ensureConfigured();
    return await health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [HealthDataType.STEPS],
    );
  }

  /// Scan for actual Bluetooth wearable devices.
  Future<List<WearableDevice>> scanForDevices() async {
    // Web/Desktop: return fallback devices immediately
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      print('Bluetooth scanning not supported on web/desktop');
      return _getFallbackDevices();
    }

    final Map<String, WearableDevice> deviceMap = {};
    
    try {
      // Request Bluetooth permissions
      if (Platform.isAndroid) {
        final locationStatus = await Permission.location.status;
        if (!locationStatus.isGranted) {
          final result = await Permission.location.request();
          if (!result.isGranted) {
            print('Location permission denied, cannot scan for Bluetooth devices');
            return _getFallbackDevices();
          }
        }
        final bluetoothScanStatus = await Permission.bluetoothScan.status;
        if (!bluetoothScanStatus.isGranted) {
          final result = await Permission.bluetoothScan.request();
          if (!result.isGranted) {
            print('Bluetooth scan permission denied');
            return _getFallbackDevices();
          }
        }
        final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
        if (!bluetoothConnectStatus.isGranted) {
          await Permission.bluetoothConnect.request();
        }
      }

      // Check if Bluetooth is available (with error handling)
      bool isSupported = false;
      try {
        isSupported = await FlutterBluePlus.isSupported;
      } catch (e) {
        print('Error checking Bluetooth support: $e');
        return _getFallbackDevices();
      }

      if (!isSupported) {
        print('Bluetooth not supported on this device');
        return _getFallbackDevices();
      }

      // Check if Bluetooth is on (with error handling)
      bool isOn = false;
      try {
        final adapterState = FlutterBluePlus.adapterState;
        final state = await adapterState.first.timeout(const Duration(seconds: 2));
        isOn = state == BluetoothAdapterState.on;
      } catch (e) {
        print('Error checking Bluetooth state: $e');
        return _getFallbackDevices();
      }

      if (!isOn) {
        print('Bluetooth is off');
        return []; // Return empty list so BLoC can show "no devices found" message
      }

      // Start scanning for 8 seconds to find more devices
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
      
      // Listen for scan results
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          final device = result.device;
          final name = device.platformName.isNotEmpty 
              ? device.platformName 
              : device.remoteId.toString();
          
          // Show all Bluetooth devices, not just wearables (user can choose)
          final wearableDevice = WearableDevice(
            id: device.remoteId.toString(),
            name: name,
            type: _isWearableDevice(name, result.advertisementData) 
                ? _getDeviceType(name) 
                : 'Bluetooth Device',
            icon: _getDeviceIcon(name),
            isAvailable: true,
          );
          
          // Store in map to avoid duplicates
          deviceMap[wearableDevice.id] = wearableDevice;
        }
      });

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 8));
      await subscription.cancel();
      await FlutterBluePlus.stopScan();

      final devices = deviceMap.values.toList();
      
      // Return empty list if no devices found (BLoC will handle showing "no devices found")
      // Only return fallback devices for unsupported platforms (handled at the start of this method)
      return devices;
    } catch (e) {
      final errorMsg = e.toString();
      final isPlatformError = errorMsg.contains('Platform.') ||
          errorMsg.contains('Unsupported operation') ||
          errorMsg.contains('_operatingSystem');
      
      if (isPlatformError) {
        print('Platform error during Bluetooth scan: $e');
        return _getFallbackDevices();
      }
      
      print('Error scanning for devices: $e');
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
      return _getFallbackDevices();
    }
  }

  /// Pair/connect to a Bluetooth device (or Health Connect).
  Future<bool> pairDevice(String deviceId) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return deviceId == 'health_connect';
    }
    try {
      if (deviceId == 'health_connect') return true;
      
      // Try to create device from ID (for recently scanned devices)
      BluetoothDevice? targetDevice;
      try {
        // Parse the device ID (format: "XX:XX:XX:XX:XX:XX")
        targetDevice = BluetoothDevice.fromId(deviceId);
      } catch (e) {
        print('Could not create device from ID: $e');
        return false;
      }
      
      // Connect to device
      await targetDevice.connect(timeout: const Duration(seconds: 15));
      
      // Discover services
      await targetDevice.discoverServices();
      
      print('Successfully paired with device: ${targetDevice.platformName}');
      return true;
    } catch (e) {
      print('Error pairing device: $e');
      return false;
    }
  }

  /// Check if a device is a wearable/fitness device based on name and advertisement data.
  bool _isWearableDevice(String name, AdvertisementData adData) {
    final lowerName = name.toLowerCase();
    final wearableKeywords = [
      'watch', 'band', 'fitbit', 'garmin', 'polar', 'xiaomi', 'mi band',
      'samsung', 'galaxy watch', 'apple watch', 'wear', 'fitness', 'tracker',
      'heart', 'pulse', 'activity', 'smartwatch', 'wearable'
    ];
    
    return wearableKeywords.any((keyword) => lowerName.contains(keyword)) ||
           adData.serviceUuids.any((uuid) => 
             uuid.toString().contains('heart') || 
             uuid.toString().contains('fitness') ||
             uuid.toString().contains('health'));
  }

  /// Get device type based on name.
  String _getDeviceType(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('watch') || lowerName.contains('apple') || 
        lowerName.contains('galaxy') || lowerName.contains('wear')) {
      return 'Smartwatch';
    }
    return 'Fitness Tracker';
  }

  /// Get device icon based on name.
  String _getDeviceIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('fitbit') || lowerName.contains('garmin') || 
        lowerName.contains('polar') || lowerName.contains('fitness')) {
      return 'fitness_center';
    }
    return 'watch';
  }

  /// Single option: sync real data from Health Connect (Fitbit, Google Fit, etc.).
  List<WearableDevice> _getFallbackDevices() {
    return [
      const WearableDevice(
        id: 'health_connect',
        name: 'Health Connect (Fitbit, Google Fit, etc.)',
        type: 'Sync real data from apps connected to Health Connect',
        icon: 'fitness_center',
        isAvailable: true,
      ),
    ];
  }
}
