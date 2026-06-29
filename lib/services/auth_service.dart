// ---------------------------------------------------------------------------
// AuthService — thin adapter kept for backward compatibility.
// Delegates to ServiceLocator.instance.authService (domain service).
// Direct Firebase calls have been removed. V2: Keycloak via ApiAuthRepository.
// ---------------------------------------------------------------------------

import '../app/service_locator.dart';

class AuthResult {
  final bool success;
  final String? shelterId;
  final String? agentCode;
  final String? role;
  final String? error;

  const AuthResult({
    required this.success,
    this.shelterId,
    this.agentCode,
    this.role,
    this.error,
  });
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  bool get isSignedIn => ServiceLocator.instance.firebaseAvailable;

  Future<AuthResult> signInWithAgentCode(
    String agentCode,
    String password,
    String shelterId,
  ) async {
    try {
      final user = await ServiceLocator.instance.authService
          .signInWithAgentCode(agentCode, password, shelterId);
      if (user == null) {
        return const AuthResult(success: false, error: 'Agent introuvable.');
      }
      return AuthResult(
        success: true,
        agentCode: user.agentCode,
        shelterId: user.refugeId,
        role: user.role.name,
      );
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await ServiceLocator.instance.authService.signOut(null);
    } catch (_) {}
  }
}
