import '../repositories/auth_repository.dart';
import '../models/user_model.dart';
import 'audit_service.dart';
import '../models/audit_log_model.dart';

// Service d'authentification.
// Délègue à AuthRepository (Firebase V1 / Keycloak V2).
// Journalise les connexions et échecs via AuditService.
class AuthDomainService {
  AuthDomainService(this._repo, this._audit);

  final AuthRepository _repo;
  final AuditService _audit;

  Stream<String?> get authStateChanges => _repo.authStateChanges;

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final user = await _repo.signInWithEmail(email, password);
      if (user != null) {
        await _audit.log(
          organizationId: user.organizationId,
          userId: user.id,
          role: user.role.keycloakName,
          action: AuditAction.login,
          targetType: 'user',
          targetId: user.id,
        );
      }
      return user;
    } catch (e) {
      await _audit.log(
        organizationId: 'unknown',
        userId: 'unknown',
        role: 'unknown',
        action: AuditAction.loginFailure,
        targetType: 'user',
        result: 'failure',
        metadata: {'email': email, 'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<UserModel?> signInWithAgentCode(
    String agentCode,
    String password,
    String refugeId,
  ) async {
    try {
      final user = await _repo.signInWithAgentCode(agentCode, password, refugeId);
      if (user != null) {
        await _audit.log(
          organizationId: user.organizationId,
          userId: user.id,
          role: user.role.keycloakName,
          action: AuditAction.login,
          targetType: 'user',
          targetId: user.id,
        );
      }
      return user;
    } catch (e) {
      await _audit.log(
        organizationId: 'unknown',
        userId: 'unknown',
        role: 'unknown',
        action: AuditAction.loginFailure,
        targetType: 'user',
        result: 'failure',
        metadata: {'agentCode': agentCode, 'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<void> signOut(UserModel? user) async {
    if (user != null) {
      await _audit.log(
        organizationId: user.organizationId,
        userId: user.id,
        role: user.role.keycloakName,
        action: AuditAction.logout,
        targetType: 'user',
        targetId: user.id,
      );
    }
    await _repo.signOut();
  }

  Future<UserModel?> signInWithGoogle() async {
    final user = await _repo.signInWithGoogle();
    if (user != null) {
      await _audit.log(
        organizationId: user.organizationId,
        userId: user.id,
        role: user.role.keycloakName,
        action: AuditAction.login,
        targetType: 'user',
        targetId: user.id,
        metadata: {'method': 'google'},
      );
    }
    return user;
  }

  Future<UserModel?> getCurrentUser() => _repo.getCurrentUser();

  Future<UserModel> createAgent({
    required String organizationId,
    required String agentCode,
    required String password,
    required String refugeId,
    required String role,
    required String createdBy,
    required String createdByRole,
  }) async {
    final user = await _repo.createAgent(
      organizationId: organizationId,
      agentCode: agentCode,
      password: password,
      refugeId: refugeId,
      role: role,
      createdBy: createdBy,
    );
    await _audit.log(
      organizationId: organizationId,
      userId: createdBy,
      role: createdByRole,
      action: AuditAction.createAgent,
      targetType: 'user',
      targetId: user.id,
      metadata: {'agentCode': agentCode, 'role': role},
    );
    return user;
  }

  Future<void> deactivateUser(
    String userId,
    String updatedBy,
    String updatedByRole,
    String organizationId,
  ) async {
    await _repo.deactivateUser(userId, updatedBy);
    await _audit.log(
      organizationId: organizationId,
      userId: updatedBy,
      role: updatedByRole,
      action: AuditAction.changeRole,
      targetType: 'user',
      targetId: userId,
      metadata: {'action': 'deactivate'},
    );
  }
}
