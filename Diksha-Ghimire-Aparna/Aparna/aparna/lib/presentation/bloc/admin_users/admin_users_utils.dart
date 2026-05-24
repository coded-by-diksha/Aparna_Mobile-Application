import '../../../core/constant/apiConstant.dart';
import 'package:aparna/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AdminUsersUtils {
  static String getTimeAgo(BuildContext context, DateTime? dateTime) {
    final l10n = AppLocalizations.of(context)!;
    if (dateTime == null) return l10n.never;
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) return l10n.daysAgo(difference.inDays);
    if (difference.inHours > 0) return l10n.hoursAgo(difference.inHours);
    if (difference.inMinutes > 0) return l10n.minsAgo(difference.inMinutes);
    return l10n.justNow;
  }

  static String? getProfilePhotoUrl(Map<String, dynamic> user) {
    final profilePhoto = user['profilephoto'] ?? user['profile_photo'];
    if (profilePhoto == null || profilePhoto.toString().trim().isEmpty) {
      return null;
    }

    final normalized = profilePhoto.toString().replaceAll('\\', '/').trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }

    final path = normalized.replaceFirst(RegExp(r'^/+'), '');
    final base = ApiConstant.baseUrl.endsWith('/') ? ApiConstant.baseUrl : '${ApiConstant.baseUrl}/';
    return '$base$path';
  }

  static int getCycleCount(Map<String, dynamic> user) {
    final cycleCount = user['cycle_count'];
    if (cycleCount == null) return 0;
    if (cycleCount is int) return cycleCount;
    if (cycleCount is String) return int.tryParse(cycleCount) ?? 0;
    return 0;
  }

  static int getBlogCount(Map<String, dynamic> user) {
    final blogCount = user['blog_count'];
    if (blogCount == null) return 0;
    if (blogCount is int) return blogCount;
    if (blogCount is String) return int.tryParse(blogCount) ?? 0;
    return 0;
  }

  static int getClinicCount(Map<String, dynamic> user) {
    final clinicCount = user['clinic_count'];
    if (clinicCount == null) return 0;
    if (clinicCount is int) return clinicCount;
    if (clinicCount is String) return int.tryParse(clinicCount) ?? 0;
    return 0;
  }

  static String getJoinedDateLabel(DateTime? dateTime) {
    if (dateTime == null) return '--';
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }

  static DateTime? getCreatedDate(Map<String, dynamic> user) {
    final createdDate = user['createdat'] ?? user['created_at'] ?? user['createdAt'];
    if (createdDate != null) {
      try {
        if (createdDate is DateTime) {
          return createdDate.isUtc ? createdDate.toLocal() : createdDate;
        }
        if (createdDate is String) {
          final normalized = createdDate.trim();
          final hasTimezone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(normalized);
          final parsed = DateTime.parse(hasTimezone ? normalized : '${normalized}Z');
          return parsed.toLocal();
        }
      } catch (e) {
        print('Error parsing created date: $e');
        return null;
      }
    }
    return null;
  }
}
