import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/crisis_event_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../models/emergency_event_model.dart';
import '../../models/enums.dart';

class FirebaseCrisisEventRepository implements CrisisEventRepository {
  FirebaseCrisisEventRepository() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.crisisEvents);

  @override
  Stream<EmergencyEventModel?> activeEventStream(String organizationId) {
    return _col
        .where('organizationId', isEqualTo: organizationId)
        .where('status', isEqualTo: EventStatus.active.name)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : _fromDoc(s.docs.first));
  }

  @override
  Future<EmergencyEventModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? _fromDoc(doc) : null;
  }

  @override
  Future<void> save(EmergencyEventModel event) async {
    await _col.doc(event.id).set(_toMap(event), SetOptions(merge: true));
  }

  @override
  Future<void> updateStatus(
    String id,
    EventStatus status, {
    DateTime? endedAt,
    required String updatedBy,
  }) async {
    final data = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
    if (endedAt != null) data['endedAt'] = Timestamp.fromDate(endedAt);
    await _col.doc(id).update(data);
  }

  @override
  Future<List<EmergencyEventModel>> getHistory(String organizationId) async {
    final snap = await _col
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('startedAt', descending: true)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  Map<String, dynamic> _toMap(EmergencyEventModel e) => {
        'id': e.id,
        'organizationId': e.organizationId,
        'territoryId': e.territoryId,
        'name': e.name,
        'type': e.type,
        'status': e.status.name,
        'volcanoName': e.volcanoName,
        'startedAt': Timestamp.fromDate(e.startedAt),
        'endedAt': e.endedAt != null ? Timestamp.fromDate(e.endedAt!) : null,
        'createdAt': e.createdAt != null
            ? Timestamp.fromDate(e.createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': e.createdBy,
        'updatedBy': e.updatedBy,
      };

  EmergencyEventModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return EmergencyEventModel(
      id: doc.id,
      organizationId:
          d['organizationId'] as String? ?? AppDefaults.organizationId,
      territoryId: d['territoryId'] as String?,
      name: d['name'] as String? ?? '',
      type: d['type'] as String? ?? '',
      status: EventStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => EventStatus.draft,
      ),
      volcanoName: d['volcanoName'] as String? ?? '',
      startedAt: (d['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (d['endedAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: d['createdBy'] as String? ?? AppDefaults.systemUserId,
      updatedBy: d['updatedBy'] as String? ?? AppDefaults.systemUserId,
    );
  }
}
