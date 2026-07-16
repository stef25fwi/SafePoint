import 'enums.dart';
import '../core/constants/app_constants.dart';

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

  /// Transfert à l'origine de l'alerte (notification « transfert entrant »),
  /// permettant d'ouvrir directement sa fiche depuis la notification.
  final String? relatedTransferId;

  final DateTime createdAt;
  final DateTime? resolvedAt;

  // Champs multi-tenant (V2-ready)
  final String organizationId;
  final String? territoryId;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  AlertModel({
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
    this.relatedTransferId,
    required this.createdAt,
    this.resolvedAt,
    this.organizationId = AppDefaults.organizationId,
    this.territoryId,
    DateTime? updatedAt,
    this.createdBy = AppDefaults.systemUserId,
    this.updatedBy = AppDefaults.systemUserId,
  }) : updatedAt = updatedAt ?? createdAt;

  // PostgreSQL-compatible field mapping (V2 migration → alerts table)
  Map<String, dynamic> toSqlMap() => {
        'id': id,
        'organization_id': organizationId,
        'territory_id': territoryId,
        'crisis_event_id': eventId,
        'refuge_id': shelterId,
        'person_id': personId,
        'family_id': familyId,
        'type': type,
        'severity': severity.name,
        'title': title,
        'description': description,
        'status': status.name,
        'assigned_to': assignedTo,
        'location': location,
        'related_transfer_id': relatedTransferId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'created_by': createdBy,
        'updated_by': updatedBy,
        'resolved_at': resolvedAt?.toIso8601String(),
      };

  AlertModel copyWith({
    AlertStatus? status,
    DateTime? resolvedAt,
    String? assignedTo,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
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
      assignedTo: assignedTo ?? this.assignedTo,
      location: location,
      relatedTransferId: relatedTransferId,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      organizationId: organizationId,
      territoryId: territoryId,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
