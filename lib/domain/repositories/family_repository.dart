import '../../models/family_model.dart';

abstract class FamilyRepository {
  // Flux temps réel des familles d'un refuge
  Stream<List<FamilyModel>> familiesStream({
    required String organizationId,
    required String refugeId,
  });

  // Récupère une famille par ID
  Future<FamilyModel?> getById(String id);

  // Crée ou met à jour une famille
  Future<void> save(FamilyModel family);

  // Mise à jour du statut de séparation
  Future<void> updateSeparated(
    String id,
    bool isSeparated,
    String updatedBy,
  );

  // Toutes les familles d'un événement de crise (export)
  Future<List<FamilyModel>> getAllForCrisisEvent({
    required String organizationId,
    required String crisisEventId,
  });
}
