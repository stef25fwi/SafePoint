import 'enums.dart';
import '../core/constants/app_constants.dart';

class CheckinModel {
  final String id;
  final String eventId;
  final String shelterId;
  final String personId;
  final String? familyId;
  final CheckinType type;
  final String? scannedBy;
  final DateTime createdAt;
  final String? notes;

  // Champs multi-tenant (V2-ready)
  final String organizationId;
  final String? territoryId;
  final String createdBy;

  const CheckinModel({
    required this.id,
    required this.eventId,
    required this.shelterId,
    required this.personId,
    this.familyId,
    required this.type,
    this.scannedBy,
    required this.createdAt,
    this.notes,
    this.organizationId = AppDefaults.organizationId,
    this.territoryId,
    this.createdBy = AppDefaults.demoUserId,
  });

  // PostgreSQL-compatible field mapping (V2 migration → checkins table)
  Map<String, dynamic> toSqlMap() => {
        'id': id,
        'organization_id': organizationId,
        'territory_id': territoryId,
        'crisis_event_id': eventId,
        'refuge_id': shelterId,
        'person_id': personId,
        'family_id': familyId,
        'type': type.name,
        'scanned_by': scannedBy,
        'created_at': createdAt.toIso8601String(),
        'created_by': createdBy,
        'notes': notes,
      };
}
