import '../repositories/alert_repository.dart';
import 'audit_service.dart';
import '../../models/alert_model.dart';
import '../../models/enums.dart';
import '../models/audit_log_model.dart';

// Service métier alertes — temps réel critique.
class AlertService {
  AlertService(this._repo, this._audit);

  final AlertRepository _repo;
  final AuditService _audit;

  // Flux temps réel (critique — doit rester en temps réel)
  Stream<List<AlertModel>> alertsStream({
    required String organizationId,
    required String refugeId,
  }) {
    return _repo.alertsStream(
      organizationId: organizationId,
      refugeId: refugeId,
    );
  }

  Future<AlertModel?> getById(String id) => _repo.getById(id);

  Future<void> createAlert(
    AlertModel alert, {
    required String createdBy,
    required String createdByRole,
  }) async {
    await _repo.save(alert);
    await _audit.log(
      organizationId: alert.organizationId,
      userId: createdBy,
      role: createdByRole,
      action: AuditAction.createAlert,
      targetType: 'alert',
      targetId: alert.id,
      metadata: {'severity': alert.severity.name, 'type': alert.type},
    );
  }

  Future<void> markInProgress(
    AlertModel alert, {
    required String updatedBy,
    required String updatedByRole,
  }) async {
    await _repo.updateStatus(
      alert.id,
      AlertStatus.inProgress,
      assignedTo: updatedBy,
      updatedBy: updatedBy,
    );
  }

  Future<void> resolve(
    AlertModel alert, {
    required String resolvedBy,
    required String resolvedByRole,
  }) async {
    final now = DateTime.now();
    await _repo.updateStatus(
      alert.id,
      AlertStatus.resolved,
      resolvedAt: now,
      updatedBy: resolvedBy,
    );
    await _audit.log(
      organizationId: alert.organizationId,
      userId: resolvedBy,
      role: resolvedByRole,
      action: AuditAction.resolveAlert,
      targetType: 'alert',
      targetId: alert.id,
      metadata: {'severity': alert.severity.name},
    );
  }

  Future<List<AlertModel>> getAllForCrisisEvent({
    required String organizationId,
    required String crisisEventId,
    AlertStatus? status,
    AlertSeverity? severity,
  }) {
    return _repo.getAllForCrisisEvent(
      organizationId: organizationId,
      crisisEventId: crisisEventId,
      status: status,
      severity: severity,
    );
  }
}
