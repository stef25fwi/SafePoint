import '../../domain/repositories/person_repository.dart';
import '../../models/person_model.dart';
import '../../models/enums.dart';
import 'api_client.dart';

// ---------------------------------------------------------------------------
// ApiPersonRepository — V2 implémentation (NestJS + PostgreSQL)
//
// Endpoints cibles :
//   GET    /persons?refugeId=&status=&limit=&offset=
//   POST   /persons
//   GET    /persons/:id
//   PATCH  /persons/:id
//   DELETE /persons/:id  (soft delete)
// ---------------------------------------------------------------------------
class ApiPersonRepository implements PersonRepository {
  ApiPersonRepository(this._client);

  // ignore: unused_field
  final ApiClient _client;

  @override
  Stream<List<PersonModel>> personsStream({
    required String organizationId,
    required String refugeId,
  }) =>
      throw UnimplementedError('[V2] SSE ou polling GET /persons?refugeId=$refugeId');

  @override
  Future<PersonModel?> getById(String id) =>
      throw UnimplementedError('[V2] GET /persons/$id');

  @override
  Future<void> save(PersonModel person) =>
      throw UnimplementedError('[V2] POST /persons ou PATCH /persons/${person.id}');

  @override
  Future<void> updateStatus(
    String id,
    PersonStatus status,
    DateTime lastCheckinAt,
    String updatedBy,
  ) =>
      throw UnimplementedError('[V2] PATCH /persons/$id (status update)');

  @override
  Future<void> updateZone(String id, String? zone, String updatedBy) =>
      throw UnimplementedError('[V2] PATCH /persons/$id (zone update)');

  @override
  Future<void> softDelete(String id, String deletedBy) =>
      throw UnimplementedError('[V2] DELETE /persons/$id');

  @override
  Future<void> archive(String id, String archivedBy) =>
      throw UnimplementedError('[V2] PATCH /persons/$id/archive');

  @override
  Future<List<PersonModel>> search({
    required String organizationId,
    String? refugeId,
    String? query,
    PersonStatus? status,
    int limit = 50,
    int offset = 0,
  }) =>
      throw UnimplementedError('[V2] GET /persons?q=$query&limit=$limit&offset=$offset');

  @override
  Future<List<PersonModel>> getAllForExport({
    required String organizationId,
    String? refugeId,
    String? crisisEventId,
  }) =>
      throw UnimplementedError('[V2] GET /exports/persons.csv');
}
