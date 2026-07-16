import 'enums.dart';
import '../core/constants/app_constants.dart';

class NeedModel {
  final String id;
  final String eventId;
  final String shelterId;
  final String? personId;
  final String? familyId;
  final NeedType type;
  final String urgency; // critical | high | medium | low
  final String status; // open | in_progress | resolved
  final String? description;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  // Champs multi-tenant (V2-ready)
  final String organizationId;
  final String? territoryId;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  NeedModel({
    required this.id,
    required this.eventId,
    required this.shelterId,
    this.personId,
    this.familyId,
    required this.type,
    required this.urgency,
    required this.status,
    this.description,
    required this.createdAt,
    this.resolvedAt,
    this.organizationId = AppDefaults.organizationId,
    this.territoryId,
    DateTime? updatedAt,
    this.createdBy = AppDefaults.demoUserId,
    this.updatedBy = AppDefaults.demoUserId,
  }) : updatedAt = updatedAt ?? createdAt;

  // PostgreSQL-compatible field mapping (V2 migration → needs table)
  Map<String, dynamic> toSqlMap() => {
        'id': id,
        'organization_id': organizationId,
        'territory_id': territoryId,
        'crisis_event_id': eventId,
        'refuge_id': shelterId,
        'person_id': personId,
        'family_id': familyId,
        'type': type.name,
        'urgency': urgency,
        'status': status,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'created_by': createdBy,
        'updated_by': updatedBy,
        'resolved_at': resolvedAt?.toIso8601String(),
      };
}
