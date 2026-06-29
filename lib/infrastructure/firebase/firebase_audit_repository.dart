import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/audit_repository.dart';
import '../../domain/models/audit_log_model.dart';
import '../../core/constants/app_constants.dart';

class FirebaseAuditRepository implements AuditRepository {
  FirebaseAuditRepository() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.auditLogs);

  @override
  Future<void> log(AuditLogModel entry) async {
    await _col.doc(entry.id).set(_toMap(entry));
  }

  @override
  Future<List<AuditLogModel>> getLogs({
    required String organizationId,
    String? userId,
    String? action,
    String? targetType,
    DateTime? from,
    DateTime? to,
    int limit = 100,
    int offset = 0,
  }) async {
    var q = _col.where('organizationId', isEqualTo: organizationId);
    if (userId != null) q = q.where('userId', isEqualTo: userId);
    if (action != null) q = q.where('action', isEqualTo: action);
    if (targetType != null) q = q.where('targetType', isEqualTo: targetType);
    if (from != null) {
      q = q.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      q = q.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    q = q.orderBy('timestamp', descending: true).limit(limit);
    final snap = await q.get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<List<AuditLogModel>> exportLogs({
    required String organizationId,
    required DateTime from,
    required DateTime to,
  }) async {
    final snap = await _col
        .where('organizationId', isEqualTo: organizationId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('timestamp', descending: false)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  Map<String, dynamic> _toMap(AuditLogModel e) => {
        'organizationId': e.organizationId,
        'userId': e.userId,
        'role': e.role,
        'action': e.action,
        'targetType': e.targetType,
        'targetId': e.targetId,
        'timestamp': Timestamp.fromDate(e.timestamp),
        'ipAddress': e.ipAddress,
        'deviceInfo': e.deviceInfo,
        'result': e.result,
        'metadata': e.metadata,
      };

  AuditLogModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AuditLogModel(
      id: doc.id,
      organizationId: d['organizationId'] as String? ?? AppDefaults.organizationId,
      userId: d['userId'] as String? ?? '',
      role: d['role'] as String? ?? '',
      action: d['action'] as String? ?? '',
      targetType: d['targetType'] as String? ?? '',
      targetId: d['targetId'] as String?,
      timestamp:
          (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ipAddress: d['ipAddress'] as String?,
      deviceInfo: d['deviceInfo'] as String?,
      result: d['result'] as String? ?? 'success',
      metadata: d['metadata'] as Map<String, dynamic>?,
    );
  }
}
