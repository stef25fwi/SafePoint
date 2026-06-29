import '../../models/transfer_model.dart';
import '../../models/enums.dart';

abstract class TransferRepository {
  // Flux temps réel des transferts d'un refuge
  Stream<List<TransferModel>> transfersStream({
    required String organizationId,
    required String refugeId,
  });

  // Récupère un transfert par ID
  Future<TransferModel?> getById(String id);

  // Crée ou met à jour un transfert
  Future<void> save(TransferModel transfer);

  // Mise à jour du statut
  Future<void> updateStatus(
    String id,
    TransferStatus status, {
    DateTime? departedAt,
    DateTime? arrivalConfirmedAt,
    required String updatedBy,
  });

  // Tous les transferts d'un événement (pour export et supervision)
  Future<List<TransferModel>> getAllForCrisisEvent({
    required String organizationId,
    required String crisisEventId,
    TransferStatus? status,
  });
}
