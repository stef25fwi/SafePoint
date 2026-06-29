import '../../domain/repositories/transfer_repository.dart';
import '../../models/transfer_model.dart';
import '../../models/enums.dart';
import 'api_client.dart';

// ---------------------------------------------------------------------------
// ApiTransferRepository — V2 implémentation (NestJS + PostgreSQL)
//
// Endpoints cibles :
//   POST   /transfers
//   GET    /transfers?refugeId=
//   PATCH  /transfers/:id/accept
//   PATCH  /transfers/:id/cancel
//   PATCH  /transfers/:id/depart
//   PATCH  /transfers/:id/arrive
// ---------------------------------------------------------------------------
class ApiTransferRepository implements TransferRepository {
  const ApiTransferRepository(this._client);

  // ignore: unused_field
  final ApiClient _client;

  @override
  Stream<List<TransferModel>> transfersStream({
    required String organizationId,
    required String refugeId,
  }) =>
      throw UnimplementedError('[V2] SSE GET /transfers/stream?refugeId=$refugeId');

  @override
  Future<TransferModel?> getById(String id) =>
      throw UnimplementedError('[V2] GET /transfers/$id');

  @override
  Future<void> save(TransferModel transfer) =>
      throw UnimplementedError('[V2] POST /transfers');

  @override
  Future<void> updateStatus(
    String id,
    TransferStatus status, {
    DateTime? departedAt,
    DateTime? arrivalConfirmedAt,
    required String updatedBy,
  }) =>
      throw UnimplementedError('[V2] PATCH /transfers/$id (status: ${status.name})');

  @override
  Future<List<TransferModel>> getAllForCrisisEvent({
    required String organizationId,
    required String crisisEventId,
    TransferStatus? status,
  }) =>
      throw UnimplementedError('[V2] GET /transfers?eventId=$crisisEventId');
}
