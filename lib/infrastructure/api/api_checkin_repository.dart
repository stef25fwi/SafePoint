import '../../domain/repositories/checkin_repository.dart';
import '../../models/checkin_model.dart';
import '../../models/enums.dart';
import 'api_client.dart';

// ---------------------------------------------------------------------------
// ApiCheckinRepository — V2 implémentation (NestJS + PostgreSQL)
//
// Endpoints cibles :
//   POST   /checkins
//   GET    /checkins?refugeId=&personId=&limit=
//   GET    /checkins/count?refugeId=&eventId=
// ---------------------------------------------------------------------------
class ApiCheckinRepository implements CheckinRepository {
  ApiCheckinRepository(this._client);

  // ignore: unused_field
  final ApiClient _client;

  @override
  Future<void> save(CheckinModel checkin) =>
      throw UnimplementedError('[V2] POST /checkins');

  @override
  Stream<List<CheckinModel>> recentStream({
    required String organizationId,
    required String refugeId,
  }) =>
      throw UnimplementedError(
          '[V2] SSE GET /checkins/stream?refugeId=$refugeId');

  @override
  Future<List<CheckinModel>> getForPerson(String personId, {int limit = 50}) =>
      throw UnimplementedError(
          '[V2] GET /checkins?personId=$personId&limit=$limit');

  @override
  Future<List<CheckinModel>> getAllForCrisisEvent({
    required String organizationId,
    required String crisisEventId,
    CheckinType? type,
    int limit = 1000,
    int offset = 0,
  }) =>
      throw UnimplementedError(
          '[V2] GET /checkins?eventId=$crisisEventId&limit=$limit&offset=$offset');

  @override
  Future<Map<String, int>> countByType({
    required String refugeId,
    required String crisisEventId,
  }) =>
      throw UnimplementedError(
          '[V2] GET /checkins/count?refugeId=$refugeId&eventId=$crisisEventId');
}
