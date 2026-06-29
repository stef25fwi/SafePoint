import '../models/audit_log_model.dart';

abstract class AuditRepository {
  // Enregistre une action auditée (fire-and-forget en V1)
  Future<void> log(AuditLogModel entry);

  // Consultation des logs (AUDITOR uniquement)
  Future<List<AuditLogModel>> getLogs({
    required String organizationId,
    String? userId,
    String? action,
    String? targetType,
    DateTime? from,
    DateTime? to,
    int limit = 100,
    int offset = 0,
  });

  // Export des logs pour audit réglementaire
  Future<List<AuditLogModel>> exportLogs({
    required String organizationId,
    required DateTime from,
    required DateTime to,
  });
}
