import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';
import '../models/checkin_model.dart';
import '../models/enums.dart';
import '../models/family_model.dart';
import '../models/need_model.dart';
import '../models/person_model.dart';
import '../models/transfer_model.dart';

// ---------------------------------------------------------------------------
// Firestore collection names
// ---------------------------------------------------------------------------
class _Col {
  static const persons = 'persons';
  static const families = 'families';
  static const checkins = 'checkins';
  static const alerts = 'alerts';
  static const transfers = 'transfers';
  static const needs = 'needs';
}

// ---------------------------------------------------------------------------
// FirestoreService — single façade for all Firestore access
// ---------------------------------------------------------------------------
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  // ---- Persons ----

  Stream<List<PersonModel>> personsStream(String shelterId) {
    return _db
        .collection(_Col.persons)
        .where('shelterId', isEqualTo: shelterId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('lastName')
        .snapshots()
        .map((s) => s.docs.map((d) => _personFromDoc(d)).toList());
  }

  Future<void> savePerson(PersonModel p) async {
    await _db.collection(_Col.persons).doc(p.id).set(_personToMap(p));
  }

  Future<void> updatePersonStatus(String id, PersonStatus status, DateTime? lastCheckinAt) async {
    await _db.collection(_Col.persons).doc(id).update({
      'status': status.name,
      if (lastCheckinAt != null) 'lastCheckinAt': Timestamp.fromDate(lastCheckinAt),
    });
  }

  Future<void> updatePersonZone(String id, String? zone) async {
    await _db.collection(_Col.persons).doc(id).update({'currentZone': zone});
  }

  // ---- Families ----

  Stream<List<FamilyModel>> familiesStream(String shelterId) {
    return _db
        .collection(_Col.families)
        .where('shelterId', isEqualTo: shelterId)
        .orderBy('displayName')
        .snapshots()
        .map((s) => s.docs.map((d) => _familyFromDoc(d)).toList());
  }

  Future<void> saveFamily(FamilyModel f) async {
    await _db.collection(_Col.families).doc(f.id).set(_familyToMap(f));
  }

  Future<void> updateFamilySeparated(String id, bool isSeparated) async {
    await _db.collection(_Col.families).doc(id).update({'isSeparated': isSeparated});
  }

  // ---- Checkins ----

  Future<void> saveCheckin(CheckinModel c) async {
    await _db.collection(_Col.checkins).doc(c.id).set(_checkinToMap(c));
  }

  Future<List<CheckinModel>> getPersonCheckins(String personId) async {
    final snap = await _db
        .collection(_Col.checkins)
        .where('personId', isEqualTo: personId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs.map((d) => _checkinFromDoc(d)).toList();
  }

  Stream<List<CheckinModel>> recentCheckinsStream(String shelterId) {
    final since = Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24)));
    return _db
        .collection(_Col.checkins)
        .where('shelterId', isEqualTo: shelterId)
        .where('createdAt', isGreaterThan: since)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map((d) => _checkinFromDoc(d)).toList());
  }

  // ---- Alerts ----

  Stream<List<AlertModel>> alertsStream(String shelterId) {
    return _db
        .collection(_Col.alerts)
        .where('shelterId', isEqualTo: shelterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => _alertFromDoc(d)).toList());
  }

  Future<void> saveAlert(AlertModel a) async {
    await _db.collection(_Col.alerts).doc(a.id).set(_alertToMap(a));
  }

  Future<void> updateAlertStatus(String id, AlertStatus status, {DateTime? resolvedAt}) async {
    await _db.collection(_Col.alerts).doc(id).update({
      'status': status.name,
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt),
    });
  }

  // ---- Transfers ----

  Stream<List<TransferModel>> transfersStream(String shelterId) {
    return _db
        .collection(_Col.transfers)
        .where('fromShelterId', isEqualTo: shelterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => _transferFromDoc(d)).toList());
  }

  Future<void> saveTransfer(TransferModel t) async {
    await _db.collection(_Col.transfers).doc(t.id).set(_transferToMap(t));
  }

  Future<void> updateTransferStatus(
    String id,
    TransferStatus status, {
    DateTime? departedAt,
    DateTime? arrivalConfirmedAt,
  }) async {
    await _db.collection(_Col.transfers).doc(id).update({
      'status': status.name,
      if (departedAt != null) 'departedAt': Timestamp.fromDate(departedAt),
      if (arrivalConfirmedAt != null)
        'arrivalConfirmedAt': Timestamp.fromDate(arrivalConfirmedAt),
    });
  }

  // ---- Needs ----

  Stream<List<NeedModel>> needsStream(String shelterId) {
    return _db
        .collection(_Col.needs)
        .where('shelterId', isEqualTo: shelterId)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => _needFromDoc(d)).toList());
  }

  Future<void> saveNeed(NeedModel n) async {
    await _db.collection(_Col.needs).doc(n.id).set(_needToMap(n));
  }

  // -------------------------------------------------------------------------
  // Serialization helpers
  // -------------------------------------------------------------------------

  // -- Person --
  Map<String, dynamic> _personToMap(PersonModel p) => {
        'id': p.id,
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
        'createdAt': Timestamp.fromDate(p.createdAt),
        'lastCheckinAt': p.lastCheckinAt != null ? Timestamp.fromDate(p.lastCheckinAt!) : null,
        'isDeleted': p.isDeleted,
      };

  PersonModel _personFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return PersonModel(
      id: d['id'] as String? ?? doc.id,
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
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastCheckinAt: (d['lastCheckinAt'] as Timestamp?)?.toDate(),
      isDeleted: d['isDeleted'] as bool? ?? false,
    );
  }

  // -- Family --
  Map<String, dynamic> _familyToMap(FamilyModel f) => {
        'id': f.id,
        'eventId': f.eventId,
        'shelterId': f.shelterId,
        'displayName': f.displayName,
        'originCommune': f.originCommune,
        'memberIds': f.memberIds,
        'membersCount': f.membersCount,
        'assignedZone': f.assignedZone,
        'isSeparated': f.isSeparated,
        'hasChildrenAlone': f.hasChildrenAlone,
        'createdAt': Timestamp.fromDate(f.createdAt),
      };

  FamilyModel _familyFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return FamilyModel(
      id: d['id'] as String? ?? doc.id,
      eventId: d['eventId'] as String? ?? '',
      shelterId: d['shelterId'] as String? ?? '',
      displayName: d['displayName'] as String? ?? '',
      originCommune: d['originCommune'] as String?,
      memberIds: List<String>.from(d['memberIds'] ?? []),
      membersCount: d['membersCount'] as int? ?? 0,
      assignedZone: d['assignedZone'] as String?,
      isSeparated: d['isSeparated'] as bool? ?? false,
      hasChildrenAlone: d['hasChildrenAlone'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // -- Checkin --
  Map<String, dynamic> _checkinToMap(CheckinModel c) => {
        'id': c.id,
        'eventId': c.eventId,
        'shelterId': c.shelterId,
        'personId': c.personId,
        'familyId': c.familyId,
        'type': c.type.name,
        'scannedBy': c.scannedBy,
        'createdAt': Timestamp.fromDate(c.createdAt),
        'notes': c.notes,
      };

  CheckinModel _checkinFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return CheckinModel(
      id: d['id'] as String? ?? doc.id,
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
      notes: d['notes'] as String?,
    );
  }

  // -- Alert --
  Map<String, dynamic> _alertToMap(AlertModel a) => {
        'id': a.id,
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
        'createdAt': Timestamp.fromDate(a.createdAt),
        'resolvedAt': a.resolvedAt != null ? Timestamp.fromDate(a.resolvedAt!) : null,
      };

  AlertModel _alertFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return AlertModel(
      id: d['id'] as String? ?? doc.id,
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
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  // -- Transfer --
  Map<String, dynamic> _transferToMap(TransferModel t) => {
        'id': t.id,
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
        'departurePlannedAt': t.departurePlannedAt != null ? Timestamp.fromDate(t.departurePlannedAt!) : null,
        'departedAt': t.departedAt != null ? Timestamp.fromDate(t.departedAt!) : null,
        'arrivalConfirmedAt': t.arrivalConfirmedAt != null ? Timestamp.fromDate(t.arrivalConfirmedAt!) : null,
        'notes': t.notes,
        'createdAt': Timestamp.fromDate(t.createdAt),
      };

  TransferModel _transferFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return TransferModel(
      id: d['id'] as String? ?? doc.id,
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
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // -- Need --
  Map<String, dynamic> _needToMap(NeedModel n) => {
        'id': n.id,
        'eventId': n.eventId,
        'shelterId': n.shelterId,
        'personId': n.personId,
        'familyId': n.familyId,
        'type': n.type.name,
        'urgency': n.urgency,
        'status': n.status,
        'description': n.description,
        'createdAt': Timestamp.fromDate(n.createdAt),
        'resolvedAt': n.resolvedAt != null ? Timestamp.fromDate(n.resolvedAt!) : null,
      };

  NeedModel _needFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return NeedModel(
      id: d['id'] as String? ?? doc.id,
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
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }
}
