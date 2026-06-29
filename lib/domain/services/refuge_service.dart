import '../repositories/refuge_repository.dart';
import 'audit_service.dart';
import '../models/audit_log_model.dart';
import '../../models/shelter_model.dart';
import '../../models/enums.dart';

// Service métier refuges.
class RefugeService {
  RefugeService(this._repo, this._audit);

  final RefugeRepository _repo;
  final AuditService _audit;

  Stream<List<ShelterModel>> refugesStream(String organizationId) =>
      _repo.refugesStream(organizationId);

  Future<ShelterModel?> getById(String id) => _repo.getById(id);

  Future<void> save(
    ShelterModel refuge, {
    required String updatedBy,
    required String updatedByRole,
  }) async {
    await _repo.save(refuge);
    await _audit.log(
      organizationId: refuge.organizationId,
      userId: updatedBy,
      role: updatedByRole,
      action: AuditAction.updateShelter,
      targetType: 'shelter',
      targetId: refuge.id,
    );
  }

  Future<void> updateStatus(
    String id,
    ShelterStatus status,
    String organizationId,
    String updatedBy,
    String updatedByRole,
  ) async {
    await _repo.updateStatus(id, status, updatedBy);
    await _audit.log(
      organizationId: organizationId,
      userId: updatedBy,
      role: updatedByRole,
      action: AuditAction.updateShelterStatus,
      targetType: 'shelter',
      targetId: id,
      metadata: {'status': status.name},
    );
  }

  Future<void> updateStock(
    String id,
    Map<String, int> stock,
    String organizationId,
    String updatedBy,
    String updatedByRole,
  ) async {
    await _repo.updateStock(id, stock, updatedBy);
    await _audit.log(
      organizationId: organizationId,
      userId: updatedBy,
      role: updatedByRole,
      action: AuditAction.updateShelterStock,
      targetType: 'shelter',
      targetId: id,
    );
  }

  Future<void> updateZones(
    String id,
    List<String> zones,
    String organizationId,
    String updatedBy,
    String updatedByRole,
  ) async {
    await _repo.updateZones(id, zones, updatedBy);
    await _audit.log(
      organizationId: organizationId,
      userId: updatedBy,
      role: updatedByRole,
      action: AuditAction.updateShelter,
      targetType: 'shelter',
      targetId: id,
      metadata: {'field': 'zones'},
    );
  }

  Future<void> updateResponsable(
    String id, {
    String? name,
    String? phone,
    required String organizationId,
    required String updatedBy,
    required String updatedByRole,
  }) async {
    await _repo.updateResponsable(id, name: name, phone: phone, updatedBy: updatedBy);
    await _audit.log(
      organizationId: organizationId,
      userId: updatedBy,
      role: updatedByRole,
      action: AuditAction.updateShelter,
      targetType: 'shelter',
      targetId: id,
      metadata: {'field': 'responsable'},
    );
  }

  Future<void> updateAgents(
    String id,
    List<String> agentNames,
    String organizationId,
    String updatedBy,
    String updatedByRole,
  ) async {
    await _repo.updateAgents(id, agentNames, updatedBy);
    await _audit.log(
      organizationId: organizationId,
      userId: updatedBy,
      role: updatedByRole,
      action: AuditAction.updateShelter,
      targetType: 'shelter',
      targetId: id,
      metadata: {'field': 'agents'},
    );
  }

  Future<List<ShelterModel>> getAllForOrganization(String organizationId) =>
      _repo.getAllForOrganization(organizationId);
}
