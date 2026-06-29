import '../../models/person_model.dart';
import '../../models/enums.dart';

abstract class PersonRepository {
  // Flux temps réel des personnes d'un refuge
  Stream<List<PersonModel>> personsStream({
    required String organizationId,
    required String refugeId,
  });

  // Récupère une personne par ID
  Future<PersonModel?> getById(String id);

  // Crée ou met à jour une personne (upsert)
  Future<void> save(PersonModel person);

  // Mise à jour du statut
  Future<void> updateStatus(
    String id,
    PersonStatus status,
    DateTime lastCheckinAt,
    String updatedBy,
  );

  // Mise à jour de la zone
  Future<void> updateZone(String id, String? zone, String updatedBy);

  // Suppression logique
  Future<void> softDelete(String id, String deletedBy);

  // Archivage après crise
  Future<void> archive(String id, String archivedBy);

  // Recherche filtrée (pour pagination V2)
  Future<List<PersonModel>> search({
    required String organizationId,
    String? refugeId,
    String? query,
    PersonStatus? status,
    int limit = 50,
    int offset = 0,
  });

  // Export des données (CSV/PDF via URL pré-signée en V2)
  Future<List<PersonModel>> getAllForExport({
    required String organizationId,
    String? refugeId,
    String? crisisEventId,
  });
}
