import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Actions traçables dans le journal d'audit (vocabulaire contrôlé).
enum AuditAction {
  login,
  logout,
  accessNominative,
  export,
  createPerson,
  updatePerson,
  deletePerson,
  resolveAlert,
  activateCrisis,
  deactivateCrisis,
  updateShelter,
}

extension AuditActionName on AuditAction {
  String get code => name;
}

/// Journal d'audit append-only (RGS – traçabilité, NIS2 – supervision).
///
/// Chaque action sensible est consignée dans la collection `audit_logs`,
/// non modifiable et non supprimable (cf. firestore.rules). Les entrées ne
/// contiennent jamais de contenu nominatif détaillé : seulement l'auteur,
/// l'action, le type/identifiant de la cible et un horodatage serveur.
class AuditService {
  AuditService._();
  static final AuditService instance = AuditService._();

  final _db = FirebaseFirestore.instance;

  /// Consigne une action. Best-effort : un échec d'écriture du journal ne doit
  /// jamais bloquer l'action métier (mais il est remonté en debug).
  Future<void> log(
    AuditAction action, {
    String? actorCode,
    String? role,
    String? shelterId,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? meta,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return; // pas d'audit hors session authentifiée
    try {
      await _db.collection('audit_logs').add({
        'actorUid': uid,
        'actorCode': actorCode,
        'role': role,
        'shelterId': shelterId,
        'action': action.code,
        'targetType': targetType,
        'targetId': targetId,
        'meta': meta,
        'at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Audit] échec écriture journal: $e');
    }
  }
}
