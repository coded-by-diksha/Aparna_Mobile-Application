import 'package:equatable/equatable.dart';
import 'package:health/health.dart';

class HealthEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<HealthDataType> healthTypes;

  const HealthEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.healthTypes,
  });

  @override
  List<Object?> get props => [id, name, description, icon, healthTypes];
}