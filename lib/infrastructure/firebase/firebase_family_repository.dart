import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/family_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../models/family_model.dart';

class FirebaseFamilyRepository implements FamilyRepository {
  FirebaseFamilyRepository() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.families);

  @override
  Stream<List<FamilyModel>> familiesStream({
    required String organizationId,
    required String refugeId,
  }) {
    return _col
        .where('organizationId', isEqualTo: organizationId)
        .where('shelterId', isEqualTo: refugeId)
        .orderBy('displayName')
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<FamilyModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? _fromDoc(doc) : null;
  }

  @override
  Future<void> save(FamilyModel family) async {
    await _col.doc(family.id).set(_toMap(family), SetOptions(merge: true));
  }

  @override
  Future<void> updateSeparated(
    String id,
    bool isSeparated,
    String updatedBy,
  ) async {
    await _col.doc(id).update({
      'isSeparated': isSeparated,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    });
  }

  @override
  Future<List<FamilyModel>> getAllForCrisisEvent({
    required String organizationId,
    required String crisisEventId,
  }) async {
    final snap = await _col
        .where('organizationId', isEqualTo: organizationId)
        .where('eventId', isEqualTo: crisisEventId)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  Map<String, dynamic> _toMap(FamilyModel f) => {
        'id': f.id,
        'organizationId': f.organizationId,
        'territoryId': f.territoryId,
        'eventId': f.eventId,
        'shelterId': f.shelterId,
        'displayName': f.displayName,
        'originCommune': f.originCommune,
        'memberIds': f.memberIds,
        'membersCount': f.membersCount,
        'assignedZone': f.assignedZone,
        'isSeparated': f.isSeparated,
        'hasChildrenAlone': f.hasChildrenAlone,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': f.createdBy,
        'updatedBy': f.updatedBy,
      };

  FamilyModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final now = DateTime.now();
    return FamilyModel(
      id: doc.id,
      organizationId:
          d['organizationId'] as String? ?? AppDefaults.organizationId,
      territoryId: d['territoryId'] as String?,
      eventId: d['eventId'] as String? ?? '',
      shelterId: d['shelterId'] as String? ?? '',
      displayName: d['displayName'] as String? ?? '',
      originCommune: d['originCommune'] as String?,
      memberIds: List<String>.from(d['memberIds'] ?? []),
      membersCount: d['membersCount'] as int? ?? 0,
      assignedZone: d['assignedZone'] as String?,
      isSeparated: d['isSeparated'] as bool? ?? false,
      hasChildrenAlone: d['hasChildrenAlone'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: d['createdBy'] as String? ?? AppDefaults.demoUserId,
      updatedBy: d['updatedBy'] as String? ?? AppDefaults.demoUserId,
    );
  }
}
