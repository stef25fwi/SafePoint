import '../../models/alert_model.dart';
import '../../models/enums.dart';

abstract class AlertRepository {
  // Flux temps réel des alertes d'un refuge (critique : temps réel obligatoire)
  Stream<List<AlertModel>> alertsStream({
    required String organizationId,
    required String refugeId,
  });

  // Récupère une alerte par ID
  Future<AlertModel?> getById(String id);

  // Crée ou met à jour une alerte
  Future<void> save(AlertModel alert);

  // Mise à jour du statut
  Future<void> updateStatus(
    String id,
    AlertStatus status, {
    DateTime? resolvedAt,
    String? assignedTo,
    required String updatedBy,
  });

  // Toutes les alertes d'un événement de crise (pour rapport)
  Future<List<AlertModel>> getAllForCrisisEvent({
    required String organizationId,
    required String crisisEventId,
    AlertStatus? status,
    AlertSeverity? severity,
  });
}
