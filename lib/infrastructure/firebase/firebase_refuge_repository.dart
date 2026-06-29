import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/refuge_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../models/shelter_model.dart';
import '../../models/enums.dart';

class FirebaseRefugeRepository implements RefugeRepository {
  FirebaseRefugeRepository() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.refuges);

  @override
  Stream<List<ShelterModel>> refugesStream(String organizationId) {
    return _col
        .where('organizationId', isEqualTo: organizationId)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<ShelterModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? _fromDoc(doc) : null;
  }

  @override
  Future<void> save(ShelterModel refuge) async {
    await _col.doc(refuge.id).set(_toMap(refuge), SetOptions(merge: true));
  }

  @override
  Future<void> updateStatus(
    String id,
    ShelterStatus status,
    String updatedBy,
  ) async {
    await _col.doc(id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    });
  }

  @override
  Future<void> updateStock(
    String id,
    Map<String, int> stock,
    String updatedBy,
  ) async {
    await _col.doc(id).update({
      'stock': stock,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    });
  }

  @override
  Future<void> updateZones(
    String id,
    List<String> zones,
    String updatedBy,
  ) async {
    await _col.doc(id).update({
      'zones': zones,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    });
  }

  @override
  Future<void> updateResponsable(
    String id, {
    String? name,
    String? phone,
    required String updatedBy,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
    if (name != null) data['responsableName'] = name;
    if (phone != null) data['responsablePhone'] = phone;
    await _col.doc(id).update(data);
  }

  @override
  Future<void> updateAgents(
    String id,
    List<String> agentNames,
    String updatedBy,
  ) async {
    await _col.doc(id).update({
      'agentNames': agentNames,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    });
  }

  @override
  Future<List<ShelterModel>> getAllForOrganization(String organizationId) async {
    final snap = await _col
        .where('organizationId', isEqualTo: organizationId)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  Map<String, dynamic> _toMap(ShelterModel s) => {
        'id': s.id,
        'organizationId': s.organizationId,
        'territoryId': s.territoryId,
        'eventId': s.eventId,
        'name': s.name,
        'commune': s.commune,
        'address': s.address,
        'capacity': s.capacity,
        'currentCount': s.currentCount,
        'status': s.status.name,
        'zones': s.zones,
        'responsableName': s.responsableName,
        'responsablePhone': s.responsablePhone,
        'agentNames': s.agentNames,
        'stock': s.stock,
        'createdAt': s.createdAt != null
            ? Timestamp.fromDate(s.createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': s.createdBy,
        'updatedBy': s.updatedBy,
      };

  ShelterModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ShelterModel(
      id: doc.id,
      organizationId: d['organizationId'] as String? ?? AppDefaults.organizationId,
      territoryId: d['territoryId'] as String?,
      eventId: d['eventId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      commune: d['commune'] as String? ?? '',
      address: d['address'] as String? ?? '',
      capacity: d['capacity'] as int? ?? 0,
      currentCount: d['currentCount'] as int? ?? 0,
      status: ShelterStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => ShelterStatus.open,
      ),
      zones: List<String>.from(d['zones'] ?? []),
      responsableName: d['responsableName'] as String?,
      responsablePhone: d['responsablePhone'] as String?,
      agentNames: List<String>.from(d['agentNames'] ?? []),
      stock: (d['stock'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: d['createdBy'] as String? ?? AppDefaults.systemUserId,
      updatedBy: d['updatedBy'] as String? ?? AppDefaults.systemUserId,
    );
  }
}
