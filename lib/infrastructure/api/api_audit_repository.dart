import '../../domain/repositories/audit_repository.dart';
import '../../domain/models/audit_log_model.dart';
import 'api_client.dart';

// ---------------------------------------------------------------------------
// ApiAuditRepository — V2 implémentation (NestJS + PostgreSQL)
//
// Endpoints cibles :
//   POST   /audit   (internal, appelé depuis le service)
//   GET    /audit-logs?userId=&action=&from=&to=&limit=&offset=
//   GET    /audit-logs/export?from=&to=
// ---------------------------------------------------------------------------
class ApiAuditRepository implements AuditRepository {
  const ApiAuditRepository(this._client);

  // ignore: unused_field
  final ApiClient _client;

  @override
  Future<void> log(AuditLogModel entry) =>
      throw UnimplementedError('[V2] POST /audit (interne au backend)');

  @override
  Future<List<AuditLogModel>> getLogs({
    required String organizationId,
    String? userId,
    String? action,
    String? targetType,
    DateTime? from,
    DateTime? to,
    int limit = 100,
    int offset = 0,
  }) =>
      throw UnimplementedError('[V2] GET /audit-logs');

  @override
  Future<List<AuditLogModel>> exportLogs({
    required String organizationId,
    required DateTime from,
    required DateTime to,
  }) =>
      throw UnimplementedError('[V2] GET /audit-logs/export');
}
