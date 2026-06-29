import '../repositories/crisis_event_repository.dart';
import 'audit_service.dart';
import '../../models/emergency_event_model.dart';
import '../../models/enums.dart';
import '../models/audit_log_model.dart';

// Service métier événements de crise.
class CrisisEventService {
  CrisisEventService(this._repo, this._audit);

  final CrisisEventRepository _repo;
  final AuditService _audit;

  // Flux temps réel de l'événement actif (critique)
  Stream<EmergencyEventModel?> activeEventStream(String organizationId) =>
      _repo.activeEventStream(organizationId);

  Future<EmergencyEventModel?> getById(String id) => _repo.getById(id);

  Future<void> activate(
    EmergencyEventModel event, {
    required String activatedBy,
    required String activatedByRole,
  }) async {
    final updated = event.copyWith(
      status: EventStatus.active,
      updatedBy: activatedBy,
    );
    await _repo.save(updated);
    await _audit.log(
      organizationId: event.organizationId,
      userId: activatedBy,
      role: activatedByRole,
      action: AuditAction.activateCrisis,
      targetType: 'crisis_event',
      targetId: event.id,
      metadata: {'name': event.name, 'type': event.type},
    );
  }

  Future<void> deactivate(
    EmergencyEventModel event, {
    required String deactivatedBy,
    required String deactivatedByRole,
  }) async {
    final now = DateTime.now();
    await _repo.updateStatus(
      event.id,
      EventStatus.closed,
      endedAt: now,
      updatedBy: deactivatedBy,
    );
    await _audit.log(
      organizationId: event.organizationId,
      userId: deactivatedBy,
      role: deactivatedByRole,
      action: AuditAction.deactivateCrisis,
      targetType: 'crisis_event',
      targetId: event.id,
    );
  }

  Future<void> createOrUpdate(
    EmergencyEventModel event, {
    required String updatedBy,
    required String updatedByRole,
  }) async {
    await _repo.save(event);
    await _audit.log(
      organizationId: event.organizationId,
      userId: updatedBy,
      role: updatedByRole,
      action: AuditAction.updateCrisisSettings,
      targetType: 'crisis_event',
      targetId: event.id,
    );
  }

  Future<List<EmergencyEventModel>> getHistory(String organizationId) =>
      _repo.getHistory(organizationId);
}
