import '../../models/enums.dart';

class UserModel {
  final String id;
  final String organizationId;
  final String? territoryId;
  final String email;
  final String? agentCode;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? refugeId;
  final String? communeId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final DateTime? lastLoginAt;
  final DateTime? deletedAt;

  const UserModel({
    required this.id,
    required this.organizationId,
    this.territoryId,
    required this.email,
    this.agentCode,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.refugeId,
    this.communeId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    this.lastLoginAt,
    this.deletedAt,
  });

  String get fullName => '$firstName $lastName';

  UserModel copyWith({
    UserRole? role,
    String? refugeId,
    bool? isActive,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id,
      organizationId: organizationId,
      territoryId: territoryId,
      email: email,
      agentCode: agentCode,
      firstName: firstName,
      lastName: lastName,
      role: role ?? this.role,
      refugeId: refugeId ?? this.refugeId,
      communeId: communeId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      deletedAt: deletedAt,
    );
  }

  // PostgreSQL-compatible field mapping (V2 migration)
  // Maps to: users, user_roles tables
  Map<String, dynamic> toSqlMap() => {
        'id': id,
        'organization_id': organizationId,
        'territory_id': territoryId,
        'email': email,
        'agent_code': agentCode,
        'first_name': firstName,
        'last_name': lastName,
        'role': role.keycloakName,
        'refuge_id': refugeId,
        'commune_id': communeId,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'created_by': createdBy,
        'updated_by': updatedBy,
        'last_login_at': lastLoginAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };
}
