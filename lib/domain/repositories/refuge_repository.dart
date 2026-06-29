import '../../models/shelter_model.dart';
import '../../models/enums.dart';

abstract class RefugeRepository {
  // Flux temps réel (quasi temps réel suffisant pour le tableau de bord)
  Stream<List<ShelterModel>> refugesStream(String organizationId);

  // Récupère un refuge par ID
  Future<ShelterModel?> getById(String id);

  // Crée ou met à jour un refuge
  Future<void> save(ShelterModel refuge);

  // Mise à jour du statut
  Future<void> updateStatus(
    String id,
    ShelterStatus status,
    String updatedBy,
  );

  // Mise à jour du stock
  Future<void> updateStock(
    String id,
    Map<String, int> stock,
    String updatedBy,
  );

  // Mise à jour des zones
  Future<void> updateZones(
    String id,
    List<String> zones,
    String updatedBy,
  );

  // Mise à jour du responsable
  Future<void> updateResponsable(
    String id, {
    String? name,
    String? phone,
    required String updatedBy,
  });

  // Mise à jour des agents
  Future<void> updateAgents(
    String id,
    List<String> agentNames,
    String updatedBy,
  );

  // Tous les refuges d'une organisation (pour export et supervision)
  Future<List<ShelterModel>> getAllForOrganization(String organizationId);
}
