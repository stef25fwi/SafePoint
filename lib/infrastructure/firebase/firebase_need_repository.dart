import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/need_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../models/need_model.dart';
import '../../models/enums.dart';

class FirebaseNeedRepository implements NeedRepository {
  FirebaseNeedRepository() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.needs);

  @override
  Stream<List<NeedModel>> needsStream({
    required String organizationId,
    required String refugeId,
  }) {
    return _col
        .where('organizationId', isEqualTo: organizationId)
        .where('shelterId', isEqualTo: refugeId)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<void> save(NeedModel need) async {
    await _col.doc(need.id).set(_toMap(need), SetOptions(merge: true));
  }

  @override
  Future<void> resolve(String id, DateTime resolvedAt, String updatedBy) async {
    await _col.doc(id).update({
      'status': 'resolved',
      'resolvedAt': Timestamp.fromDate(resolvedAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    });
  }

  @override
  Future<List<NeedModel>> getAllForCrisisEvent({
    required String organizationId,
    required String crisisEventId,
  }) async {
    final snap = await _col
        .where('organizationId', isEqualTo: organizationId)
        .where('eventId', isEqualTo: crisisEventId)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  Map<String, dynamic> _toMap(NeedModel n) => {
        'id': n.id,
        'organizationId': n.organizationId,
        'territoryId': n.territoryId,
        'eventId': n.eventId,
        'shelterId': n.shelterId,
        'personId': n.personId,
        'familyId': n.familyId,
        'type': n.type.name,
        'urgency': n.urgency,
        'status': n.status,
        'description': n.description,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': n.createdBy,
        'updatedBy': n.updatedBy,
        'resolvedAt':
            n.resolvedAt != null ? Timestamp.fromDate(n.resolvedAt!) : null,
      };

  NeedModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final now = DateTime.now();
    return NeedModel(
      id: doc.id,
      organizationId:
          d['organizationId'] as String? ?? AppDefaults.organizationId,
      territoryId: d['territoryId'] as String?,
      eventId: d['eventId'] as String? ?? '',
      shelterId: d['shelterId'] as String? ?? '',
      personId: d['personId'] as String?,
      familyId: d['familyId'] as String?,
      type: NeedType.values.firstWhere(
        (e) => e.name == d['type'],
        orElse: () => NeedType.other,
      ),
      urgency: d['urgency'] as String? ?? 'medium',
      status: d['status'] as String? ?? 'open',
      description: d['description'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: d['createdBy'] as String? ?? AppDefaults.demoUserId,
      updatedBy: d['updatedBy'] as String? ?? AppDefaults.demoUserId,
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }
}
