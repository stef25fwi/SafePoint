import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/agent_account_model.dart';
import '../../domain/repositories/agent_account_repository.dart';

class FirebaseAgentAccountRepository implements AgentAccountRepository {
  FirebaseAgentAccountRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<AgentAccountModel?> getByAgentCode(String agentCode) async {
    try {
      final query = await _firestore
          .collection('agent_accounts')
          .where('agentCode', isEqualTo: agentCode)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return AgentAccountModel.fromFirestore(query.docs.first.data());
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<AgentAccountModel>> getAllForCommune(String communeId) async {
    try {
      final query = await _firestore
          .collection('agent_accounts')
          .where('communeId', isEqualTo: communeId)
          .where('active', isEqualTo: true)
          .get();
      return query.docs
          .map((d) => AgentAccountModel.fromFirestore(d.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<AgentAccountModel>> getAllForShelter(String centerId) async {
    try {
      final query = await _firestore
          .collection('agent_accounts')
          .where('centerId', isEqualTo: centerId)
          .where('active', isEqualTo: true)
          .get();
      return query.docs
          .map((d) => AgentAccountModel.fromFirestore(d.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> create(AgentAccountModel account) async {
    await _firestore
        .collection('agent_accounts')
        .doc(account.id)
        .set(account.toFirestore());
  }

  @override
  Future<void> updatePasswordHash(String accountId, String passwordHash) async {
    await _firestore.collection('agent_accounts').doc(accountId).update({
      'passwordHash': passwordHash,
      'mustChangePassword': false,
    });
  }

  @override
  Future<void> updateLastLogin(String accountId, DateTime loginTime) async {
    await _firestore.collection('agent_accounts').doc(accountId).update({
      'lastLoginAt': loginTime.toIso8601String(),
    });
  }

  @override
  Future<void> disable(String accountId) async {
    await _firestore.collection('agent_accounts').doc(accountId).update({
      'active': false,
    });
  }

  @override
  Future<void> setMustChangePassword(String accountId, bool value) async {
    await _firestore.collection('agent_accounts').doc(accountId).update({
      'mustChangePassword': value,
    });
  }
}
