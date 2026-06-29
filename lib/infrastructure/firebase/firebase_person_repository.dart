import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/person_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../models/person_model.dart';
import '../../models/enums.dart';

class FirebasePersonRepository implements PersonRepository {
  FirebasePersonRepository() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.persons);

  @override
  Stream<List<PersonModel>> personsStream({
    required String organizationId,
    required String refugeId,
  }) {
    return _col
        .where('organizationId', isEqualTo: organizationId)
        .where('shelterId', isEqualTo: refugeId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('lastName')
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<PersonModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? _fromDoc(doc) : null;
  }

  @override
  Future<void> save(PersonModel person) async {
    await _col.doc(person.id).set(_toMap(person), SetOptions(merge: true));
  }

  @override
  Future<void> updateStatus(
    String id,
    PersonStatus status,
    DateTime lastCheckinAt,
    String updatedBy,
  ) async {
    await _col.doc(id).update({
      'status': status.name,
      'lastCheckinAt': Timestamp.fromDate(lastCheckinAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    });
  }

  @override
  Future<void> updateZone(String id, String? zone, String updatedBy) async {
    await _col.doc(id).update({
      'currentZone': zone,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    });
  }

  @override
  Future<void> softDelete(String id, String deletedBy) async {
    await _col.doc(id).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedBy': deletedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> archive(String id, String archivedBy) async {
    await _col.doc(id).update({
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedBy': archivedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<PersonModel>> search({
    required String organizationId,
    String? refugeId,
    String? query,
    PersonStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var q = _col.where('organizationId', isEqualTo: organizationId);
    if (refugeId != null) q = q.where('shelterId', isEqualTo: refugeId);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    q = q.where('isDeleted', isEqualTo: false).limit(limit);
    final snap = await q.get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<List<PersonModel>> getAllForExport({
    required String organizationId,
    String? refugeId,
    String? crisisEventId,
  }) async {
    var q = _col
        .where('organizationId', isEqualTo: organizationId)
        .where('isDeleted', isEqualTo: false);
    if (refugeId != null) q = q.where('shelterId', isEqualTo: refugeId);
    if (crisisEventId != null) q = q.where('eventId', isEqualTo: crisisEventId);
    final snap = await q.get();
    return snap.docs.map(_fromDoc).toList();
  }

  // -------------------------------------------------------------------------
  // Serialization
  // -------------------------------------------------------------------------

  Map<String, dynamic> _toMap(PersonModel p) => {
        'id': p.id,
        'organizationId': p.organizationId,
        'territoryId': p.territoryId,
        'eventId': p.eventId,
        'shelterId': p.shelterId,
        'familyId': p.familyId,
        'qrCode': p.qrCode,
        'firstName': p.firstName,
        'lastName': p.lastName,
        'birthDate': p.birthDate != null ? Timestamp.fromDate(p.birthDate!) : null,
        'ageApprox': p.ageApprox,
        'originCommune': p.originCommune,
        'originSector': p.originSector,
        'phone': p.phone,
        'emergencyContactName': p.emergencyContactName,
        'emergencyContactPhone': p.emergencyContactPhone,
        'currentZone': p.currentZone,
        'status': p.status.name,
        'vulnerabilityFlags': p.vulnerabilityFlags,
        'needFlags': p.needFlags.map((n) => n.name).toList(),
        'notes': p.notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': p.createdBy,
        'updatedBy': p.updatedBy,
        'lastCheckinAt':
            p.lastCheckinAt != null ? Timestamp.fromDate(p.lastCheckinAt!) : null,
        'isDeleted': p.isDeleted,
        'visibilityLevel': p.visibilityLevel,
        'retentionPolicy': p.retentionPolicy,
      };

  PersonModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final now = DateTime.now();
    return PersonModel(
      id: doc.id,
      organizationId: d['organizationId'] as String? ?? AppDefaults.organizationId,
      territoryId: d['territoryId'] as String?,
      eventId: d['eventId'] as String? ?? '',
      shelterId: d['shelterId'] as String? ?? '',
      familyId: d['familyId'] as String?,
      qrCode: d['qrCode'] as String? ?? '',
      firstName: d['firstName'] as String? ?? '',
      lastName: d['lastName'] as String? ?? '',
      birthDate: (d['birthDate'] as Timestamp?)?.toDate(),
      ageApprox: d['ageApprox'] as int?,
      originCommune: d['originCommune'] as String?,
      originSector: d['originSector'] as String?,
      phone: d['phone'] as String?,
      emergencyContactName: d['emergencyContactName'] as String?,
      emergencyContactPhone: d['emergencyContactPhone'] as String?,
      currentZone: d['currentZone'] as String?,
      status: PersonStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => PersonStatus.nonPointee,
      ),
      vulnerabilityFlags: List<String>.from(d['vulnerabilityFlags'] ?? []),
      needFlags: (d['needFlags'] as List<dynamic>?)
              ?.map((e) => NeedType.values.firstWhere(
                    (n) => n.name == e,
                    orElse: () => NeedType.other,
                  ))
              .toList() ??
          [],
      notes: d['notes'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: d['createdBy'] as String? ?? AppDefaults.demoUserId,
      updatedBy: d['updatedBy'] as String? ?? AppDefaults.demoUserId,
      lastCheckinAt: (d['lastCheckinAt'] as Timestamp?)?.toDate(),
      isDeleted: d['isDeleted'] as bool? ?? false,
      visibilityLevel: d['visibilityLevel'] as String? ?? 'internal',
      retentionPolicy: d['retentionPolicy'] as String?,
    );
  }
}
