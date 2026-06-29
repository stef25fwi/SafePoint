import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import 'api_client.dart';

// ---------------------------------------------------------------------------
// ApiAuthRepository — V2 implémentation (Keycloak + NestJS)
//
// Remplace FirebaseAuthRepository quand Environment.useApiBackend == true.
// Authentification via OpenID Connect (Keycloak) :
//   POST /auth/login → JWT token
//   GET  /me         → profil utilisateur
// ---------------------------------------------------------------------------
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  // ignore: unused_field
  final ApiClient _client;

  @override
  Stream<String?> get authStateChanges =>
      throw UnimplementedError('[V2] authStateChanges : implémenter avec Keycloak session');

  @override
  Future<UserModel?> signInWithEmail(String email, String password) =>
      throw UnimplementedError('[V2] POST /auth/login avec Keycloak');

  @override
  Future<UserModel?> signInWithAgentCode(
    String agentCode,
    String password,
    String refugeId,
  ) =>
      throw UnimplementedError('[V2] POST /auth/login (agent code convention)');

  @override
  Future<void> signOut() =>
      throw UnimplementedError('[V2] POST /auth/logout + révocation token Keycloak');

  @override
  Future<UserModel?> getCurrentUser() =>
      throw UnimplementedError('[V2] GET /me');

  @override
  Future<UserModel> createAgent({
    required String organizationId,
    required String agentCode,
    required String password,
    required String refugeId,
    required String role,
    required String createdBy,
  }) =>
      throw UnimplementedError('[V2] POST /users (admin Keycloak)');

  @override
  Future<UserModel?> signInWithGoogle() =>
      throw UnimplementedError('[V2] Keycloak Google OAuth flow');

  @override
  Future<void> updatePassword(String newPassword) =>
      throw UnimplementedError('[V2] PUT /me/password');

  @override
  Future<void> deactivateUser(String userId, String updatedBy) =>
      throw UnimplementedError('[V2] PATCH /users/:id/deactivate');
}
