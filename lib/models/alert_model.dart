import 'enums.dart';

class AlertModel {
  final String id;
  final String eventId;
  final String shelterId;
  final String? personId;
  final String? familyId;
  final String type;
  final AlertSeverity severity;
  final String title;
  final String description;
  final AlertStatus status;
  final String? assignedTo;
  final String? location;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const AlertModel({
    required this.id,
    required this.eventId,
    required this.shelterId,
    this.personId,
    this.familyId,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.status,
    this.assignedTo,
    this.location,
    required this.createdAt,
    this.resolvedAt,
  });

  AlertModel copyWith({AlertStatus? status, DateTime? resolvedAt}) {
    return AlertModel(
      id: id,
      eventId: eventId,
      shelterId: shelterId,
      personId: personId,
      familyId: familyId,
      type: type,
      severity: severity,
      title: title,
      description: description,
      status: status ?? this.status,
      assignedTo: assignedTo,
      location: location,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
