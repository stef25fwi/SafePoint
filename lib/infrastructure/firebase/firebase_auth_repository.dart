import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../models/enums.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository()
      : _auth = FirebaseAuth.instance,
        _db = FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  @override
  Stream<String?> get authStateChanges =>
      _auth.authStateChanges().map((u) => u?.uid);

  @override
  Future<UserModel?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchProfile(cred.user!.uid);
  }

  @override
  Future<UserModel?> signInWithAgentCode(
    String agentCode,
    String password,
    String refugeId,
  ) async {
    final email = '${agentCode.toLowerCase().trim()}@safepoint.app';
    return signInWithEmail(email, password);
  }

  @override
  Future<void> signOut() async => _auth.signOut();

  @override
  Future<UserModel?> getCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _fetchProfile(uid);
  }

  @override
  Future<UserModel> createAgent({
    required String organizationId,
    required String agentCode,
    required String password,
    required String refugeId,
    required String role,
    required String createdBy,
  }) async {
    final email = '${agentCode.toLowerCase()}@safepoint.app';
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final now = DateTime.now();
    final user = UserModel(
      id: cred.user!.uid,
      organizationId: organizationId,
      email: email,
      agentCode: agentCode,
      firstName: agentCode,
      lastName: '',
      role: UserRole.values.firstWhere(
        (r) => r.keycloakName == role,
        orElse: () => UserRole.agent,
      ),
      refugeId: refugeId,
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy,
      updatedBy: createdBy,
    );
    await _db
        .collection(FirestoreCollections.users)
        .doc(cred.user!.uid)
        .set(_userToMap(user));
    return user;
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      late GoogleSignInAccount? googleUser;
      if (kIsWeb) {
        googleUser = await GoogleSignIn(
          clientId: '779368619357-c2gbmtiralba9rtuvumj59ta62posn7l.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        ).signIn();
      } else {
        googleUser = await GoogleSignIn().signIn();
      }

      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final uid = userCred.user!.uid;

      var userDoc = await _db
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        final now = DateTime.now();
        final newUser = UserModel(
          id: uid,
          organizationId: AppDefaults.organizationId,
          email: userCred.user!.email ?? '',
          firstName: userCred.user!.displayName?.split(' ').first ?? '',
          lastName: userCred.user!.displayName?.split(' ').skip(1).join(' ') ?? '',
          role: UserRole.agent,
          isActive: true,
          createdAt: now,
          updatedAt: now,
          createdBy: AppDefaults.systemUserId,
          updatedBy: AppDefaults.systemUserId,
        );
        await _db
            .collection(FirestoreCollections.users)
            .doc(uid)
            .set(_userToMap(newUser));
        return newUser;
      }

      return _userFromDoc(userDoc);
    } catch (e) {
      debugPrint('[GoogleSignIn] Error: $e');
      return null;
    }
  }

  @override
  Future<void> deactivateUser(String userId, String updatedBy) async {
    await _db.collection(FirestoreCollections.users).doc(userId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    });
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  Future<UserModel?> _fetchProfile(String uid) async {
    final doc = await _db
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return _userFromDoc(doc);
  }

  UserModel _userFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final now = DateTime.now();
    return UserModel(
      id: doc.id,
      organizationId: d['organizationId'] as String? ?? AppDefaults.organizationId,
      territoryId: d['territoryId'] as String?,
      email: d['email'] as String? ?? '',
      agentCode: d['agentCode'] as String?,
      firstName: d['firstName'] as String? ?? '',
      lastName: d['lastName'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.keycloakName == d['role'],
        orElse: () => UserRole.agent,
      ),
      refugeId: d['refugeId'] as String?,
      communeId: d['communeId'] as String?,
      isActive: d['isActive'] as bool? ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? now,
      createdBy: d['createdBy'] as String? ?? AppDefaults.systemUserId,
      updatedBy: d['updatedBy'] as String? ?? AppDefaults.systemUserId,
      lastLoginAt: (d['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> _userToMap(UserModel u) => {
        'organizationId': u.organizationId,
        'territoryId': u.territoryId,
        'email': u.email,
        'agentCode': u.agentCode,
        'firstName': u.firstName,
        'lastName': u.lastName,
        'role': u.role.keycloakName,
        'refugeId': u.refugeId,
        'communeId': u.communeId,
        'isActive': u.isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': u.createdBy,
        'updatedBy': u.updatedBy,
      };
}
