import '../../domain/models/agent_account_model.dart';
import '../../domain/repositories/agent_account_repository.dart';
import 'api_client.dart';

// V2 API stub — LoginAgent Cloud Function
class ApiAgentAccountRepository implements AgentAccountRepository {
  ApiAgentAccountRepository(this._client);

  // ignore: unused_field
  final ApiClient _client;

  @override
  Future<AgentAccountModel?> getByAgentCode(String agentCode) =>
      throw UnimplementedError('[V2] GET /agent-accounts?agentCode=$agentCode');

  @override
  Future<List<AgentAccountModel>> getAllForCommune(String communeId) =>
      throw UnimplementedError('[V2] GET /agent-accounts?communeId=$communeId');

  @override
  Future<List<AgentAccountModel>> getAllForShelter(String centerId) =>
      throw UnimplementedError('[V2] GET /agent-accounts?centerId=$centerId');

  @override
  Future<void> create(AgentAccountModel account) => throw UnimplementedError(
      '[V2] POST /agent-accounts/create (Cloud Function)');

  @override
  Future<void> updatePasswordHash(String accountId, String passwordHash) =>
      throw UnimplementedError('[V2] POST /agent-accounts/change-password');

  @override
  Future<void> updateLastLogin(String accountId, DateTime loginTime) =>
      throw UnimplementedError(
          '[V2] PATCH /agent-accounts/$accountId/last-login');

  @override
  Future<void> disable(String accountId) =>
      throw UnimplementedError('[V2] PATCH /agent-accounts/$accountId/disable');

  @override
  Future<void> setMustChangePassword(String accountId, bool value) =>
      throw UnimplementedError(
          '[V2] PATCH /agent-accounts/$accountId/must-change-password');
}
