import 'enums.dart';
import '../core/constants/app_constants.dart';

class EmergencyEventModel {
  final String id;
  final String name;
  final String type;
  final EventStatus status;
  final String volcanoName;
  final DateTime startedAt;
  final DateTime? endedAt;

  // Champs multi-tenant (V2-ready)
  final String organizationId;
  final String? territoryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String updatedBy;

  EmergencyEventModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.volcanoName,
    required this.startedAt,
    this.endedAt,
    this.organizationId = AppDefaults.organizationId,
    this.territoryId,
    this.createdAt,
    this.updatedAt,
    this.createdBy = AppDefaults.systemUserId,
    this.updatedBy = AppDefaults.systemUserId,
  });

  // PostgreSQL-compatible field mapping (V2 migration → crisis_events table)
  Map<String, dynamic> toSqlMap() => {
        'id': id,
        'organization_id': organizationId,
        'territory_id': territoryId,
        'name': name,
        'type': type,
        'status': status.name,
        'zone_name': volcanoName,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'created_by': createdBy,
        'updated_by': updatedBy,
      };

  EmergencyEventModel copyWith({
    String? id,
    String? name,
    String? type,
    EventStatus? status,
    String? volcanoName,
    DateTime? startedAt,
    DateTime? endedAt,
    bool clearEndedAt = false,
    String? updatedBy,
  }) =>
      EmergencyEventModel(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        status: status ?? this.status,
        volcanoName: volcanoName ?? this.volcanoName,
        startedAt: startedAt ?? this.startedAt,
        endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
        organizationId: organizationId,
        territoryId: territoryId,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        createdBy: createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );
}
