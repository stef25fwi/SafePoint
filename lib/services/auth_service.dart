import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Résultat de connexion
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

// ---------------------------------------------------------------------------
// AuthService — gère Firebase Auth + profil agent dans Firestore
//
// Structure Firestore attendue :
//   /agents/{uid}
//     agentCode  : String   (ex: "agent01")
//     shelterId  : String   (ex: "shelter_1")
//     role       : String   (ex: "responsableCentre")
//     email      : String
//
// Pour créer un agent : Firebase Console → Authentication → Email/password
// puis créer le document /agents/{uid} correspondant.
// ---------------------------------------------------------------------------
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Connexion par email/mot de passe (convention : email = agentCode@safepoint.app)
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final profile = await _getAgentProfile(cred.user!.uid);
      return AuthResult(
        success: true,
        shelterId: profile?['shelterId'] as String?,
        agentCode: profile?['agentCode'] as String?,
        role: profile?['role'] as String?,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Connexion par code agent (recherche dans Firestore par agentCode)
  /// L'email est construit comme : agentCode@safepoint.app
  Future<AuthResult> signInWithAgentCode(
    String agentCode,
    String password,
    String shelterId,
  ) async {
    final email = '${agentCode.toLowerCase().trim()}@safepoint.app';
    return signInWithEmail(email, password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>?> _getAgentProfile(String uid) async {
    try {
      final doc = await _db.collection('agents').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }

  /// Crée un compte agent (admin only)
  Future<AuthResult> createAgent({
    required String agentCode,
    required String password,
    required String shelterId,
    required String role,
  }) async {
    try {
      final email = '${agentCode.toLowerCase()}@safepoint.app';
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _db.collection('agents').doc(cred.user!.uid).set({
        'agentCode': agentCode,
        'email': email,
        'shelterId': shelterId,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Agent introuvable.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-email':
        return 'Identifiant invalide.';
      case 'user-disabled':
        return 'Ce compte est désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion.';
      default:
        return 'Erreur de connexion ($code).';
    }
  }
}
