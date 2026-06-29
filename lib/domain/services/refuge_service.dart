import '../repositories/refuge_repository.dart';
import 'audit_service.dart';
import '../../models/shelter_model.dart';
import '../../models/enums.dart';

// Service métier refuges.
class RefugeService {
  RefugeService(this._repo, this._audit);

  final RefugeRepository _repo;
  // ignore: unused_field
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
  }

  Future<void> updateStatus(
    String id,
    ShelterStatus status,
    String organizationId,
    String updatedBy,
    String updatedByRole,
  ) async {
    await _repo.updateStatus(id, status, updatedBy);
  }

  Future<void> updateStock(
    String id,
    Map<String, int> stock,
    String organizationId,
    String updatedBy,
  ) async {
    await _repo.updateStock(id, stock, updatedBy);
  }

  Future<void> updateZones(
    String id,
    List<String> zones,
    String organizationId,
    String updatedBy,
  ) async {
    await _repo.updateZones(id, zones, updatedBy);
  }

  Future<void> updateResponsable(
    String id, {
    String? name,
    String? phone,
    required String organizationId,
    required String updatedBy,
  }) async {
    await _repo.updateResponsable(id, name: name, phone: phone, updatedBy: updatedBy);
  }

  Future<void> updateAgents(
    String id,
    List<String> agentNames,
    String organizationId,
    String updatedBy,
  ) async {
    await _repo.updateAgents(id, agentNames, updatedBy);
  }

  Future<List<ShelterModel>> getAllForOrganization(String organizationId) =>
      _repo.getAllForOrganization(organizationId);
}
