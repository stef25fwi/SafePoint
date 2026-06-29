import 'package:uuid/uuid.dart';
import '../repositories/audit_repository.dart';
import '../models/audit_log_model.dart';

// Service d'audit — trace toutes les actions sensibles.
// En V1 Firebase, les logs vont dans audit_logs/.
// En V2, le backend valide et stocke les logs côté serveur.
class AuditService {
  AuditService(this._repo);

  final AuditRepository _repo;
  final _uuid = const Uuid();

  Future<void> log({
    required String organizationId,
    required String userId,
    required String role,
    required String action,
    required String targetType,
    String? targetId,
    String result = 'success',
    Map<String, dynamic>? metadata,
    String? deviceInfo,
  }) async {
    final entry = AuditLogModel(
      id: _uuid.v4(),
      organizationId: organizationId,
      userId: userId,
      role: role,
      action: action,
      targetType: targetType,
      targetId: targetId,
      timestamp: DateTime.now(),
      deviceInfo: deviceInfo,
      result: result,
      metadata: metadata,
    );
    // Fire-and-forget : ne pas bloquer l'action principale si l'audit échoue
    _repo.log(entry).catchError((e) {
      // ignore: avoid_print
      // ignore: unnecessary_null_comparison
      if (e != null) {
      }
    });
  }

  Future<List<AuditLogModel>> getLogs({
    required String organizationId,
    String? userId,
    String? action,
    DateTime? from,
    DateTime? to,
    int limit = 100,
    int offset = 0,
  }) {
    return _repo.getLogs(
      organizationId: organizationId,
      userId: userId,
      action: action,
      from: from,
      to: to,
      limit: limit,
      offset: offset,
    );
  }
}
