import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safepoint_app/domain/models/audit_log_model.dart';
import 'package:safepoint_app/domain/repositories/audit_repository.dart';
import 'package:safepoint_app/domain/repositories/transfer_repository.dart';
import 'package:safepoint_app/domain/services/audit_service.dart';
import 'package:safepoint_app/domain/services/transfer_service.dart';
import 'package:safepoint_app/models/enums.dart';
import 'package:safepoint_app/models/transfer_model.dart';

class MockTransferRepository extends Mock implements TransferRepository {}

class MockAuditRepository extends Mock implements AuditRepository {}

class FakeAuditLogModel extends Fake implements AuditLogModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuditLogModel());
    registerFallbackValue(DateTime(2026));
  });

  late TransferService service;
  late MockTransferRepository repo;
  late MockAuditRepository auditRepo;

  final transfer = TransferModel(
    id: 'transfer_1',
    eventId: 'event_1',
    fromShelterId: 'refuge_1',
    fromShelterName: 'Gymnase A',
    toShelterId: 'refuge_2',
    toShelterName: 'Centre B',
    personIds: const ['person_1', 'person_2'],
    status: TransferStatus.pending,
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    repo = MockTransferRepository();
    auditRepo = MockAuditRepository();
    service = TransferService(repo, AuditService(auditRepo));
    when(() => auditRepo.log(any())).thenAnswer((_) async {});
  });

  group('TransferService', () {
    test('createTransfer enregistre le transfert et journalise', () async {
      when(() => repo.save(transfer)).thenAnswer((_) async {});

      await service.createTransfer(transfer,
          createdBy: 'user_1', createdByRole: 'REFUGE_MANAGER');

      verify(() => repo.save(transfer)).called(1);
      verify(() => auditRepo.log(any())).called(1);
    });

    test('markDeparted passe le transfert en cours avec horodatage', () async {
      when(() => repo.updateStatus(transfer.id, TransferStatus.inProgress,
          departedAt: any(named: 'departedAt'),
          updatedBy: 'user_1')).thenAnswer((_) async {});

      await service.markDeparted(transfer,
          updatedBy: 'user_1', updatedByRole: 'REFUGE_MANAGER');

      verify(() => repo.updateStatus(transfer.id, TransferStatus.inProgress,
          departedAt: any(named: 'departedAt'), updatedBy: 'user_1')).called(1);
    });

    test('confirmArrival confirme l\'arrivée et journalise', () async {
      when(() => repo.updateStatus(transfer.id, TransferStatus.confirmed,
          arrivalConfirmedAt: any(named: 'arrivalConfirmedAt'),
          updatedBy: 'user_1')).thenAnswer((_) async {});

      await service.confirmArrival(transfer,
          updatedBy: 'user_1', updatedByRole: 'REFUGE_MANAGER');

      verify(() => repo.updateStatus(transfer.id, TransferStatus.confirmed,
          arrivalConfirmedAt: any(named: 'arrivalConfirmedAt'),
          updatedBy: 'user_1')).called(1);
      verify(() => auditRepo.log(any())).called(1);
    });

    test('cancel annule le transfert et journalise', () async {
      when(() => repo.updateStatus(transfer.id, TransferStatus.cancelled,
          updatedBy: 'user_1')).thenAnswer((_) async {});

      await service.cancel(transfer,
          updatedBy: 'user_1', updatedByRole: 'REFUGE_MANAGER');

      verify(() => repo.updateStatus(transfer.id, TransferStatus.cancelled,
          updatedBy: 'user_1')).called(1);
      verify(() => auditRepo.log(any())).called(1);
    });
  });
}
