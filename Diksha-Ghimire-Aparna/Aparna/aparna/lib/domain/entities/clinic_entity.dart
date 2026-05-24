import 'package:equatable/equatable.dart';

class ClinicEntity extends Equatable {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String description;
  final String distance;
  final String? clinicImage; // URL or base64 from backend

  const ClinicEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.description,
    this.distance = '',
    this.clinicImage,
  });

  @override
  List<Object?> get props => [id, name, address, latitude, longitude, phone, description, distance, clinicImage];
}
