import '../../models/need_model.dart';

abstract class NeedRepository {
  // Flux des besoins ouverts d'un refuge
  Stream<List<NeedModel>> needsStream({
    required String organizationId,
    required String refugeId,
  });

  // Crée ou met à jour un besoin
  Future<void> save(NeedModel need);

  // Résolution d'un besoin
  Future<void> resolve(String id, DateTime resolvedAt, String updatedBy);

  // Tous les besoins d'un événement de crise
  Future<List<NeedModel>> getAllForCrisisEvent({
    required String organizationId,
    required String crisisEventId,
  });
}
