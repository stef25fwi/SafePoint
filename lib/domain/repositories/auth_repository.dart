import '../models/user_model.dart';

abstract class AuthRepository {
  // Connexion par email / mot de passe
  Future<UserModel?> signInWithEmail(String email, String password);

  // Connexion par code agent (convention email V1)
  Future<UserModel?> signInWithAgentCode(
    String agentCode,
    String password,
    String refugeId,
  );

  // Déconnexion
  Future<void> signOut();

  // Récupère le profil de l'utilisateur connecté
  Future<UserModel?> getCurrentUser();

  // Stream d'état d'authentification
  Stream<String?> get authStateChanges; // null = déconnecté, uid = connecté

  // Crée un compte agent (super_admin, commune_admin uniquement)
  Future<UserModel> createAgent({
    required String organizationId,
    required String agentCode,
    required String password,
    required String refugeId,
    required String role,
    required String createdBy,
  });

  // Mise à jour du mot de passe
  Future<void> updatePassword(String newPassword);

  // Révocation de compte (désactivation logique)
  Future<void> deactivateUser(String userId, String updatedBy);
}
