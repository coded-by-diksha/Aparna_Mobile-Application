import 'package:equatable/equatable.dart';
import '../../../data/models/health_model.dart';

abstract class DetailedUserState extends Equatable {
  const DetailedUserState();

  @override
  List<Object?> get props => [];
}

class DetailedUserInitial extends DetailedUserState {}

class DetailedUserLoading extends DetailedUserState {}

class DetailedUserLoaded extends DetailedUserState {
  final Map<String, dynamic> userData;
  final HealthModel? healthData;

  const DetailedUserLoaded({
    required this.userData,
    this.healthData,
  });

  String get userName =>
      userData['username'] ?? userData['name'] ?? 'Unknown User';

  String get userEmail => userData['email'] ?? 'No email';

  String? get profilePhotoUrl {
    final photo = userData['profilephoto'] ?? userData['profile_photo'];
    if (photo == null || photo.toString().trim().isEmpty) return null;
    return photo.toString();
  }

  int get cycleCount {
    final v = userData['cycle_count'];
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  bool get isAdmin {
    final role = userData['role']?.toString().toLowerCase();
    return role == 'admin';
  }

  int get blogCount {
    final v = userData['blog_count'];
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  int get clinicCount {
    final v = userData['clinic_count'];
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  DateTime? get createdDate {
    final v = userData['createdat'] ?? userData['created_at'] ?? userData['createdAt'];
    if (v == null) return null;
    if (v is DateTime) return v.isUtc ? v.toLocal() : v;
    if (v is String) {
      final normalized = v.trim();
      final hasTimezone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(normalized);
      final parsed = DateTime.tryParse(hasTimezone ? normalized : '${normalized}Z');
      return parsed?.toLocal();
    }
    return null;
  }

  String get userId {
    final uid = userData['uid'] ?? userData['id'];
    return uid?.toString() ?? '';
  }

  @override
  List<Object?> get props => [userData, healthData];
}

class DetailedUserError extends DetailedUserState {
  final String message;

  const DetailedUserError(this.message);

  @override
  List<Object?> get props => [message];
}

class DetailedUserDeleted extends DetailedUserState {
  final String message;

  const DetailedUserDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

class DetailedUserDeleteError extends DetailedUserState {
  final String message;
  final Map<String, dynamic> userData;
  final HealthModel? healthData;

  const DetailedUserDeleteError({
    required this.message,
    required this.userData,
    this.healthData,
  });

  @override
  List<Object?> get props => [message, userData, healthData];
}
