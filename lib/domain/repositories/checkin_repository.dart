import '../../models/checkin_model.dart';
import '../../models/enums.dart';

abstract class CheckinRepository {
  // Enregistre un pointage
  Future<void> save(CheckinModel checkin);

  // Flux des pointages récents d'un refuge (24h, limité à 100)
  Stream<List<CheckinModel>> recentStream({
    required String organizationId,
    required String refugeId,
  });

  // Historique des pointages d'une personne (paginé)
  Future<List<CheckinModel>> getForPerson(
    String personId, {
    int limit = 50,
  });

  // Tous les pointages d'un événement de crise (pour export)
  Future<List<CheckinModel>> getAllForCrisisEvent({
    required String organizationId,
    required String crisisEventId,
    CheckinType? type,
    int limit = 1000,
    int offset = 0,
  });

  // Compte de pointages par type pour un refuge
  Future<Map<String, int>> countByType({
    required String refugeId,
    required String crisisEventId,
  });
}
