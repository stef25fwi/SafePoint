import '../../models/emergency_event_model.dart';
import '../../models/enums.dart';

abstract class CrisisEventRepository {
  // Flux de l'événement actif pour une organisation
  Stream<EmergencyEventModel?> activeEventStream(String organizationId);

  // Récupère un événement par ID
  Future<EmergencyEventModel?> getById(String id);

  // Crée ou met à jour un événement de crise
  Future<void> save(EmergencyEventModel event);

  // Mise à jour du statut (activation / désactivation)
  Future<void> updateStatus(
    String id,
    EventStatus status, {
    DateTime? endedAt,
    required String updatedBy,
  });

  // Historique des événements d'une organisation
  Future<List<EmergencyEventModel>> getHistory(String organizationId);
}
