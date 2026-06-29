class OrganizationModel {
  final String id;
  final String name;
  final String? code;
  final String type; // prefecture, region, commune, sdis
  final String? parentId;
  final String? communeCode;
  final String? regionCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  const OrganizationModel({
    required this.id,
    required this.name,
    this.code,
    required this.type,
    this.parentId,
    this.communeCode,
    this.regionCode,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  // PostgreSQL-compatible field mapping (V2 migration)
  Map<String, dynamic> toSqlMap() => {
        'id': id,
        'name': name,
        'code': code,
        'type': type,
        'parent_id': parentId,
        'commune_code': communeCode,
        'region_code': regionCode,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'created_by': createdBy,
        'updated_by': updatedBy,
      };
}
