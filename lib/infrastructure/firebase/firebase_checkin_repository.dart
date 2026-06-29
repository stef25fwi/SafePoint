import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/checkin_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../models/checkin_model.dart';
import '../../models/enums.dart';

class FirebaseCheckinRepository implements CheckinRepository {
  FirebaseCheckinRepository() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.checkins);

  @override
  Future<void> save(CheckinModel checkin) async {
    await _col.doc(checkin.id).set(_toMap(checkin));
  }

  @override
  Stream<List<CheckinModel>> recentStream({
    required String organizationId,
    required String refugeId,
  }) {
    final since = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 24)),
    );
    return _col
        .where('organizationId', isEqualTo: organizationId)
        .where('shelterId', isEqualTo: refugeId)
        .where('createdAt', isGreaterThan: since)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<List<CheckinModel>> getForPerson(
    String personId, {
    int limit = 50,
  }) async {
    final snap = await _col
        .where('personId', isEqualTo: personId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<List<CheckinModel>> getAllForCrisisEvent({
    required String organizationId,
    required String crisisEventId,
    CheckinType? type,
    int limit = 1000,
    int offset = 0,
  }) async {
    var q = _col
        .where('organizationId', isEqualTo: organizationId)
        .where('eventId', isEqualTo: crisisEventId);
    if (type != null) q = q.where('type', isEqualTo: type.name);
    q = q.orderBy('createdAt', descending: true).limit(limit);
    final snap = await q.get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<Map<String, int>> countByType({
    required String refugeId,
    required String crisisEventId,
  }) async {
    final snap = await _col
        .where('shelterId', isEqualTo: refugeId)
        .where('eventId', isEqualTo: crisisEventId)
        .get();
    final counts = <String, int>{};
    for (final doc in snap.docs) {
      final type = doc.data()['type'] as String? ?? 'unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, dynamic> _toMap(CheckinModel c) => {
        'id': c.id,
        'organizationId': c.organizationId,
        'territoryId': c.territoryId,
        'eventId': c.eventId,
        'shelterId': c.shelterId,
        'personId': c.personId,
        'familyId': c.familyId,
        'type': c.type.name,
        'scannedBy': c.scannedBy,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': c.createdBy,
        'notes': c.notes,
      };

  CheckinModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return CheckinModel(
      id: doc.id,
      organizationId: d['organizationId'] as String? ?? AppDefaults.organizationId,
      territoryId: d['territoryId'] as String?,
      eventId: d['eventId'] as String? ?? '',
      shelterId: d['shelterId'] as String? ?? '',
      personId: d['personId'] as String? ?? '',
      familyId: d['familyId'] as String?,
      type: CheckinType.values.firstWhere(
        (e) => e.name == d['type'],
        orElse: () => CheckinType.presence,
      ),
      scannedBy: d['scannedBy'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: d['createdBy'] as String? ?? AppDefaults.demoUserId,
      notes: d['notes'] as String?,
    );
  }
}
