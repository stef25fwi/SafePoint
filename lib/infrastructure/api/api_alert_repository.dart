import '../../domain/repositories/alert_repository.dart';
import '../../models/alert_model.dart';
import '../../models/enums.dart';
import 'api_client.dart';

// ---------------------------------------------------------------------------
// ApiAlertRepository — V2 implémentation (NestJS + PostgreSQL)
//
// Endpoints cibles :
//   POST   /alerts
//   GET    /alerts?refugeId=&status=
//   PATCH  /alerts/:id/close
//   PATCH  /alerts/:id/assign
// ---------------------------------------------------------------------------
class ApiAlertRepository implements AlertRepository {
  const ApiAlertRepository(this._client);

  final ApiClient _client;

  @override
  Stream<List<AlertModel>> alertsStream({
    required String organizationId,
    required String refugeId,
  }) =>
      throw UnimplementedError('[V2] SSE GET /alerts/stream?refugeId=$refugeId (temps réel critique)');

  @override
  Future<AlertModel?> getById(String id) =>
      throw UnimplementedError('[V2] GET /alerts/$id');

  @override
  Future<void> save(AlertModel alert) =>
      throw UnimplementedError('[V2] POST /alerts');

  @override
  Future<void> updateStatus(
    String id,
    AlertStatus status, {
    DateTime? resolvedAt,
    String? assignedTo,
    required String updatedBy,
  }) =>
      throw UnimplementedError('[V2] PATCH /alerts/$id (status: ${status.name})');

  @override
  Future<List<AlertModel>> getAllForCrisisEvent({
    required String organizationId,
    required String crisisEventId,
    AlertStatus? status,
    AlertSeverity? severity,
  }) =>
      throw UnimplementedError('[V2] GET /alerts?eventId=$crisisEventId');
}
