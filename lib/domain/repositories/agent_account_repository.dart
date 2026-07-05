import '../models/agent_account_model.dart';

abstract class AgentAccountRepository {
  Future<AgentAccountModel?> getByAgentCode(String agentCode);

  Future<List<AgentAccountModel>> getAllForCommune(String communeId);

  Future<List<AgentAccountModel>> getAllForShelter(String centerId);

  Future<void> create(AgentAccountModel account);

  Future<void> updatePasswordHash(String accountId, String passwordHash);

  Future<void> updateLastLogin(String accountId, DateTime loginTime);

  Future<void> disable(String accountId);

  Future<void> setMustChangePassword(String accountId, bool value);
}
