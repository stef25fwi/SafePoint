class AuditLogModel {
  final String id;
  final String organizationId;
  final String userId;
  final String role;
  final String action;
  final String targetType;
  final String? targetId;
  final DateTime timestamp;
  final String? ipAddress;
  final String? deviceInfo;
  final String result; // success | failure
  final Map<String, dynamic>? metadata;

  const AuditLogModel({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.role,
    required this.action,
    required this.targetType,
    this.targetId,
    required this.timestamp,
    this.ipAddress,
    this.deviceInfo,
    required this.result,
    this.metadata,
  });

  // PostgreSQL-compatible field mapping (V2 migration)
  Map<String, dynamic> toSqlMap() => {
        'id': id,
        'organization_id': organizationId,
        'user_id': userId,
        'role': role,
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'timestamp': timestamp.toIso8601String(),
        'ip_address': ipAddress,
        'device_info': deviceInfo,
        'result': result,
        'metadata': metadata,
      };
}

// Enumeration of auditable actions
class AuditAction {
  static const login = 'LOGIN';
  static const loginFailure = 'LOGIN_FAILURE';
  static const logout = 'LOGOUT';
  static const createPerson = 'CREATE_PERSON';
  static const updatePerson = 'UPDATE_PERSON';
  static const archivePerson = 'ARCHIVE_PERSON';
  static const createCheckin = 'CREATE_CHECKIN';
  static const createTransfer = 'CREATE_TRANSFER';
  static const acceptTransfer = 'ACCEPT_TRANSFER';
  static const cancelTransfer = 'CANCEL_TRANSFER';
  static const createAlert = 'CREATE_ALERT';
  static const resolveAlert = 'RESOLVE_ALERT';
  static const closeAlert = 'CLOSE_ALERT';
  static const activateCrisis = 'ACTIVATE_CRISIS';
  static const deactivateCrisis = 'DEACTIVATE_CRISIS';
  static const exportCsv = 'EXPORT_CSV';
  static const exportPdf = 'EXPORT_PDF';
  static const viewPersonRecord = 'VIEW_PERSON_RECORD';
  static const changeRole = 'CHANGE_ROLE';
  static const createAgent = 'CREATE_AGENT';
  static const updateCrisisSettings = 'UPDATE_CRISIS_SETTINGS';
  static const uploadFile = 'UPLOAD_FILE';
  static const updateShelter = 'UPDATE_SHELTER';
  static const updateShelterStatus = 'UPDATE_SHELTER_STATUS';
  static const updateShelterStock = 'UPDATE_SHELTER_STOCK';
}
