import '../../domain/repositories/refuge_repository.dart';
import '../../models/shelter_model.dart';
import '../../models/enums.dart';
import 'api_client.dart';

// ---------------------------------------------------------------------------
// ApiRefugeRepository — V2 implémentation (NestJS + PostgreSQL)
//
// Endpoints cibles :
//   GET    /refuges
//   POST   /refuges
//   GET    /refuges/:id
//   PATCH  /refuges/:id/status
//   PATCH  /refuges/:id/stock
//   PATCH  /refuges/:id/zones
// ---------------------------------------------------------------------------
class ApiRefugeRepository implements RefugeRepository {
  ApiRefugeRepository(this._client);

  // ignore: unused_field
  final ApiClient _client;

  @override
  Stream<List<ShelterModel>> refugesStream(String organizationId) =>
      throw UnimplementedError('[V2] SSE ou polling GET /refuges (30s interval suffisant)');

  @override
  Future<ShelterModel?> getById(String id) =>
      throw UnimplementedError('[V2] GET /refuges/$id');

  @override
  Future<void> save(ShelterModel refuge) =>
      throw UnimplementedError('[V2] POST /refuges ou PATCH /refuges/${refuge.id}');

  @override
  Future<void> updateStatus(String id, ShelterStatus status, String updatedBy) =>
      throw UnimplementedError('[V2] PATCH /refuges/$id/status');

  @override
  Future<void> updateStock(String id, Map<String, int> stock, String updatedBy) =>
      throw UnimplementedError('[V2] PATCH /refuges/$id/stock');

  @override
  Future<void> updateZones(String id, List<String> zones, String updatedBy) =>
      throw UnimplementedError('[V2] PATCH /refuges/$id/zones');

  @override
  Future<void> updateResponsable(String id, {String? name, String? phone, required String updatedBy}) =>
      throw UnimplementedError('[V2] PATCH /refuges/$id/responsable');

  @override
  Future<void> updateAgents(String id, List<String> agentNames, String updatedBy) =>
      throw UnimplementedError('[V2] PATCH /refuges/$id/agents');

  @override
  Future<List<ShelterModel>> getAllForOrganization(String organizationId) =>
      throw UnimplementedError('[V2] GET /refuges');
}
