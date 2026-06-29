import '../repositories/person_repository.dart';
import '../repositories/checkin_repository.dart';
import 'audit_service.dart';
import '../../models/person_model.dart';
import '../../models/checkin_model.dart';
import '../../models/enums.dart';
import '../models/audit_log_model.dart';

// Service métier personnes — interface unique pour les pages.
// Ne contient aucun import Firebase direct.
class PersonService {
  PersonService(this._personRepo, this._checkinRepo, this._audit);

  final PersonRepository _personRepo;
  final CheckinRepository _checkinRepo;
  final AuditService _audit;

  // Flux temps réel des personnes d'un refuge
  Stream<List<PersonModel>> personsStream({
    required String organizationId,
    required String refugeId,
  }) {
    return _personRepo.personsStream(
      organizationId: organizationId,
      refugeId: refugeId,
    );
  }

  Future<PersonModel?> getById(String id) => _personRepo.getById(id);

  // Crée une personne et enregistre un pointage d'arrivée
  Future<void> createPerson(
    PersonModel person, {
    required String createdBy,
    required String createdByRole,
    required CheckinModel arrivalCheckin,
  }) async {
    await _personRepo.save(person);
    await _checkinRepo.save(arrivalCheckin);
    await _audit.log(
      organizationId: person.organizationId,
      userId: createdBy,
      role: createdByRole,
      action: AuditAction.createPerson,
      targetType: 'person',
      targetId: person.id,
      metadata: {
        'name': '${person.firstName} ${person.lastName}',
        'refugeId': person.shelterId,
      },
    );
  }

  // Met à jour une personne
  Future<void> updatePerson(
    PersonModel person, {
    required String updatedBy,
    required String updatedByRole,
  }) async {
    await _personRepo.save(person);
    await _audit.log(
      organizationId: person.organizationId,
      userId: updatedBy,
      role: updatedByRole,
      action: AuditAction.updatePerson,
      targetType: 'person',
      targetId: person.id,
    );
  }

  // Enregistre un pointage et met à jour le statut
  Future<void> createCheckin({
    required PersonModel person,
    required CheckinModel checkin,
    required PersonStatus newStatus,
    required String updatedBy,
    required String updatedByRole,
  }) async {
    await _checkinRepo.save(checkin);
    await _personRepo.updateStatus(
      person.id,
      newStatus,
      checkin.createdAt,
      updatedBy,
    );
    await _audit.log(
      organizationId: person.organizationId,
      userId: updatedBy,
      role: updatedByRole,
      action: AuditAction.createCheckin,
      targetType: 'checkin',
      targetId: checkin.id,
      metadata: {
        'personId': person.id,
        'type': checkin.type.name,
        'status': newStatus.name,
      },
    );
  }

  // Historique des pointages d'une personne
  Future<List<CheckinModel>> getCheckins(String personId) =>
      _checkinRepo.getForPerson(personId);

  // Suppression logique
  Future<void> softDelete(
    PersonModel person, {
    required String deletedBy,
    required String deletedByRole,
  }) async {
    await _personRepo.softDelete(person.id, deletedBy);
    await _audit.log(
      organizationId: person.organizationId,
      userId: deletedBy,
      role: deletedByRole,
      action: AuditAction.archivePerson,
      targetType: 'person',
      targetId: person.id,
    );
  }

  // Mise à jour de zone
  Future<void> updateZone(
    String personId,
    String? zone,
    String organizationId,
    String updatedBy,
  ) async {
    await _personRepo.updateZone(personId, zone, updatedBy);
  }

  // Recherche filtrée
  Future<List<PersonModel>> search({
    required String organizationId,
    String? refugeId,
    String? query,
    PersonStatus? status,
    int limit = 50,
    int offset = 0,
  }) {
    return _personRepo.search(
      organizationId: organizationId,
      refugeId: refugeId,
      query: query,
      status: status,
      limit: limit,
      offset: offset,
    );
  }

  // Export pour rapport (AUDITOR, PREFECTURE_ADMIN)
  Future<List<PersonModel>> getAllForExport({
    required String organizationId,
    required String requestedBy,
    required String requestedByRole,
    String? refugeId,
    String? crisisEventId,
  }) async {
    await _audit.log(
      organizationId: organizationId,
      userId: requestedBy,
      role: requestedByRole,
      action: AuditAction.exportCsv,
      targetType: 'person',
      metadata: {'refugeId': refugeId, 'crisisEventId': crisisEventId},
    );
    return _personRepo.getAllForExport(
      organizationId: organizationId,
      refugeId: refugeId,
      crisisEventId: crisisEventId,
    );
  }
}
