import '../repositories/transfer_repository.dart';
import 'audit_service.dart';
import '../../models/transfer_model.dart';
import '../../models/enums.dart';
import '../models/audit_log_model.dart';

// Service métier transferts.
class TransferService {
  TransferService(this._repo, this._audit);

  final TransferRepository _repo;
  final AuditService _audit;

  Stream<List<TransferModel>> transfersStream({
    required String organizationId,
    required String refugeId,
  }) {
    return _repo.transfersStream(
      organizationId: organizationId,
      refugeId: refugeId,
    );
  }

  Future<TransferModel?> getById(String id) => _repo.getById(id);

  Future<void> createTransfer(
    TransferModel transfer, {
    required String createdBy,
    required String createdByRole,
  }) async {
    await _repo.save(transfer);
    await _audit.log(
      organizationId: transfer.organizationId,
      userId: createdBy,
      role: createdByRole,
      action: AuditAction.createTransfer,
      targetType: 'transfer',
      targetId: transfer.id,
      metadata: {
        'from': transfer.fromShelterName,
        'to': transfer.toShelterName,
        'persons': transfer.personCount,
      },
    );
  }

  Future<void> markDeparted(
    TransferModel transfer, {
    required String updatedBy,
    required String updatedByRole,
  }) async {
    final now = DateTime.now();
    await _repo.updateStatus(
      transfer.id,
      TransferStatus.inProgress,
      departedAt: now,
      updatedBy: updatedBy,
    );
  }

  Future<void> confirmArrival(
    TransferModel transfer, {
    required String updatedBy,
    required String updatedByRole,
  }) async {
    final now = DateTime.now();
    await _repo.updateStatus(
      transfer.id,
      TransferStatus.confirmed,
      arrivalConfirmedAt: now,
      updatedBy: updatedBy,
    );
    await _audit.log(
      organizationId: transfer.organizationId,
      userId: updatedBy,
      role: updatedByRole,
      action: AuditAction.acceptTransfer,
      targetType: 'transfer',
      targetId: transfer.id,
    );
  }

  Future<void> cancel(
    TransferModel transfer, {
    required String updatedBy,
    required String updatedByRole,
  }) async {
    await _repo.updateStatus(
      transfer.id,
      TransferStatus.cancelled,
      updatedBy: updatedBy,
    );
    await _audit.log(
      organizationId: transfer.organizationId,
      userId: updatedBy,
      role: updatedByRole,
      action: AuditAction.cancelTransfer,
      targetType: 'transfer',
      targetId: transfer.id,
    );
  }

  Future<List<TransferModel>> getAllForCrisisEvent({
    required String organizationId,
    required String crisisEventId,
    TransferStatus? status,
  }) {
    return _repo.getAllForCrisisEvent(
      organizationId: organizationId,
      crisisEventId: crisisEventId,
      status: status,
    );
  }
}
