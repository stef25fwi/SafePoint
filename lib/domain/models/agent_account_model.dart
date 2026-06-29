import '../../models/enums.dart';

class AgentAccountModel {
  final String id;
  final String agentCode;
  final UserRole role;
  final String displayName;
  final String? communeId;
  final String? centerId;
  final String? eventId;
  final bool active;
  final bool mustChangePassword;
  final String? passwordHash;
  final String? createdByUid;
  final UserRole? createdByRole;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const AgentAccountModel({
    required this.id,
    required this.agentCode,
    required this.role,
    required this.displayName,
    this.communeId,
    this.centerId,
    this.eventId,
    required this.active,
    required this.mustChangePassword,
    this.passwordHash,
    this.createdByUid,
    this.createdByRole,
    required this.createdAt,
    this.lastLoginAt,
  });

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'agentCode': agentCode,
        'role': role.name,
        'displayName': displayName,
        'communeId': communeId,
        'centerId': centerId,
        'eventId': eventId,
        'active': active,
        'mustChangePassword': mustChangePassword,
        'passwordHash': passwordHash,
        'createdByUid': createdByUid,
        'createdByRole': createdByRole?.name,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
      };

  factory AgentAccountModel.fromFirestore(Map<String, dynamic> doc) {
    return AgentAccountModel(
      id: doc['id'] ?? '',
      agentCode: doc['agentCode'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == doc['role'],
        orElse: () => UserRole.agent,
      ),
      displayName: doc['displayName'] ?? '',
      communeId: doc['communeId'],
      centerId: doc['centerId'],
      eventId: doc['eventId'],
      active: doc['active'] ?? true,
      mustChangePassword: doc['mustChangePassword'] ?? false,
      passwordHash: doc['passwordHash'],
      createdByUid: doc['createdByUid'],
      createdByRole: doc['createdByRole'] != null
          ? UserRole.values.firstWhere(
              (r) => r.name == doc['createdByRole'],
              orElse: () => UserRole.agent,
            )
          : null,
      createdAt: DateTime.parse(doc['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: doc['lastLoginAt'] != null ? DateTime.parse(doc['lastLoginAt']) : null,
    );
  }
}
