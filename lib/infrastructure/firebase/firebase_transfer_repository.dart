import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/transfer_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../models/transfer_model.dart';
import '../../models/enums.dart';

class FirebaseTransferRepository implements TransferRepository {
  FirebaseTransferRepository() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.transfers);

  @override
  Stream<List<TransferModel>> transfersStream({
    required String organizationId,
    required String refugeId,
  }) {
    return _col
        .where('organizationId', isEqualTo: organizationId)
        .where('fromShelterId', isEqualTo: refugeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<TransferModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? _fromDoc(doc) : null;
  }

  @override
  Future<void> save(TransferModel transfer) async {
    await _col.doc(transfer.id).set(_toMap(transfer), SetOptions(merge: true));
  }

  @override
  Future<void> updateStatus(
    String id,
    TransferStatus status, {
    DateTime? departedAt,
    DateTime? arrivalConfirmedAt,
    required String updatedBy,
  }) async {
    final data = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
    if (departedAt != null) data['departedAt'] = Timestamp.fromDate(departedAt);
    if (arrivalConfirmedAt != null) {
      data['arrivalConfirmedAt'] = Timestamp.fromDate(arrivalConfirmedAt);
    }
    await _col.doc(id).update(data);
  }

  @override
  Future<List<TransferModel>> getAllForCrisisEvent({
    required String organizationId,
    required String crisisEventId,
    TransferStatus? status,
  }) async {
    var q = _col
        .where('organizationId', isEqualTo: organizationId)
        .where('eventId', isEqualTo: crisisEventId);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    final snap = await q.orderBy('createdAt', descending: true).get();
    return snap.docs.map(_fromDoc).toList();
  }

  Map<String, dynamic> _toMap(TransferModel t) => {
        'id': t.id,
        'organizationId': t.organizationId,
        'territoryId': t.territoryId,
        'eventId': t.eventId,
        'fromShelterId': t.fromShelterId,
        'fromShelterName': t.fromShelterName,
        'toShelterId': t.toShelterId,
        'toShelterName': t.toShelterName,
        'personIds': t.personIds,
        'familyId': t.familyId,
        'familyName': t.familyName,
        'status': t.status.name,
        'transportMode': t.transportMode,
        'departurePlannedAt': t.departurePlannedAt != null
            ? Timestamp.fromDate(t.departurePlannedAt!)
            : null,
        'departedAt':
            t.departedAt != null ? Timestamp.fromDate(t.departedAt!) : null,
        'arrivalConfirmedAt': t.arrivalConfirmedAt != null
            ? Timestamp.fromDate(t.arrivalConfirmedAt!)
            : null,
        'notes': t.notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': t.createdBy,
        'updatedBy': t.updatedBy,
      };

  TransferModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final now = DateTime.now();
    return TransferModel(
      id: doc.id,
      organizationId: d['organizationId'] as String? ?? AppDefaults.organizationId,
      territoryId: d['territoryId'] as String?,
      eventId: d['eventId'] as String? ?? '',
      fromShelterId: d['fromShelterId'] as String? ?? '',
      fromShelterName: d['fromShelterName'] as String? ?? '',
      toShelterId: d['toShelterId'] as String? ?? '',
      toShelterName: d['toShelterName'] as String? ?? '',
      personIds: List<String>.from(d['personIds'] ?? []),
      familyId: d['familyId'] as String?,
      familyName: d['familyName'] as String?,
      status: TransferStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => TransferStatus.pending,
      ),
      transportMode: d['transportMode'] as String?,
      departurePlannedAt: (d['departurePlannedAt'] as Timestamp?)?.toDate(),
      departedAt: (d['departedAt'] as Timestamp?)?.toDate(),
      arrivalConfirmedAt: (d['arrivalConfirmedAt'] as Timestamp?)?.toDate(),
      notes: d['notes'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: d['createdBy'] as String? ?? AppDefaults.demoUserId,
      updatedBy: d['updatedBy'] as String? ?? AppDefaults.demoUserId,
    );
  }
}
