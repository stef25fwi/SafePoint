import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/alert_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../models/alert_model.dart';
import '../../models/enums.dart';

class FirebaseAlertRepository implements AlertRepository {
  FirebaseAlertRepository() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.alerts);

  @override
  Stream<List<AlertModel>> alertsStream({
    required String organizationId,
    required String refugeId,
  }) {
    return _col
        .where('organizationId', isEqualTo: organizationId)
        .where('shelterId', isEqualTo: refugeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<AlertModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? _fromDoc(doc) : null;
  }

  @override
  Future<void> save(AlertModel alert) async {
    await _col.doc(alert.id).set(_toMap(alert), SetOptions(merge: true));
  }

  @override
  Future<void> updateStatus(
    String id,
    AlertStatus status, {
    DateTime? resolvedAt,
    String? assignedTo,
    required String updatedBy,
  }) async {
    final data = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
    if (resolvedAt != null) data['resolvedAt'] = Timestamp.fromDate(resolvedAt);
    if (assignedTo != null) data['assignedTo'] = assignedTo;
    await _col.doc(id).update(data);
  }

  @override
  Future<List<AlertModel>> getAllForCrisisEvent({
    required String organizationId,
    required String crisisEventId,
    AlertStatus? status,
    AlertSeverity? severity,
  }) async {
    var q = _col
        .where('organizationId', isEqualTo: organizationId)
        .where('eventId', isEqualTo: crisisEventId);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    if (severity != null) q = q.where('severity', isEqualTo: severity.name);
    final snap = await q.orderBy('createdAt', descending: true).get();
    return snap.docs.map(_fromDoc).toList();
  }

  Map<String, dynamic> _toMap(AlertModel a) => {
        'id': a.id,
        'organizationId': a.organizationId,
        'territoryId': a.territoryId,
        'eventId': a.eventId,
        'shelterId': a.shelterId,
        'personId': a.personId,
        'familyId': a.familyId,
        'type': a.type,
        'severity': a.severity.name,
        'title': a.title,
        'description': a.description,
        'status': a.status.name,
        'assignedTo': a.assignedTo,
        'location': a.location,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': a.createdBy,
        'updatedBy': a.updatedBy,
        'resolvedAt':
            a.resolvedAt != null ? Timestamp.fromDate(a.resolvedAt!) : null,
      };

  AlertModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final now = DateTime.now();
    return AlertModel(
      id: doc.id,
      organizationId: d['organizationId'] as String? ?? AppDefaults.organizationId,
      territoryId: d['territoryId'] as String?,
      eventId: d['eventId'] as String? ?? '',
      shelterId: d['shelterId'] as String? ?? '',
      personId: d['personId'] as String?,
      familyId: d['familyId'] as String?,
      type: d['type'] as String? ?? 'unknown',
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == d['severity'],
        orElse: () => AlertSeverity.info,
      ),
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      status: AlertStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => AlertStatus.open,
      ),
      assignedTo: d['assignedTo'] as String?,
      location: d['location'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: d['createdBy'] as String? ?? AppDefaults.systemUserId,
      updatedBy: d['updatedBy'] as String? ?? AppDefaults.systemUserId,
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }
}
