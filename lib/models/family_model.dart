import '../core/constants/app_constants.dart';

class FamilyModel {
  final String id;
  final String eventId;
  final String shelterId;
  final String displayName;
  final String? originCommune;
  final List<String> memberIds;
  final int membersCount;
  final String? assignedZone;
  final bool isSeparated;
  final bool hasChildrenAlone;
  final DateTime createdAt;

  // Champs multi-tenant (V2-ready)
  final String organizationId;
  final String? territoryId;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  FamilyModel({
    required this.id,
    required this.eventId,
    required this.shelterId,
    required this.displayName,
    this.originCommune,
    required this.memberIds,
    required this.membersCount,
    this.assignedZone,
    this.isSeparated = false,
    this.hasChildrenAlone = false,
    required this.createdAt,
    this.organizationId = AppDefaults.organizationId,
    this.territoryId,
    DateTime? updatedAt,
    this.createdBy = AppDefaults.demoUserId,
    this.updatedBy = AppDefaults.demoUserId,
  }) : updatedAt = updatedAt ?? createdAt;

  // PostgreSQL-compatible field mapping (V2 migration → families table)
  Map<String, dynamic> toSqlMap() => {
        'id': id,
        'organization_id': organizationId,
        'territory_id': territoryId,
        'crisis_event_id': eventId,
        'refuge_id': shelterId,
        'display_name': displayName,
        'origin_commune': originCommune,
        'member_ids': memberIds,
        'members_count': membersCount,
        'assigned_zone': assignedZone,
        'is_separated': isSeparated,
        'has_children_alone': hasChildrenAlone,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'created_by': createdBy,
        'updated_by': updatedBy,
      };

  FamilyModel copyWith({
    List<String>? memberIds,
    int? membersCount,
    bool? isSeparated,
    String? assignedZone,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return FamilyModel(
      id: id,
      eventId: eventId,
      shelterId: shelterId,
      displayName: displayName,
      originCommune: originCommune,
      memberIds: memberIds ?? this.memberIds,
      membersCount: membersCount ?? this.membersCount,
      assignedZone: assignedZone ?? this.assignedZone,
      isSeparated: isSeparated ?? this.isSeparated,
      hasChildrenAlone: hasChildrenAlone,
      createdAt: createdAt,
      organizationId: organizationId,
      territoryId: territoryId,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
