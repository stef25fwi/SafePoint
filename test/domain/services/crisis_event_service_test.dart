import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safepoint_app/domain/models/audit_log_model.dart';
import 'package:safepoint_app/domain/repositories/audit_repository.dart';
import 'package:safepoint_app/domain/repositories/crisis_event_repository.dart';
import 'package:safepoint_app/domain/services/audit_service.dart';
import 'package:safepoint_app/domain/services/crisis_event_service.dart';
import 'package:safepoint_app/models/emergency_event_model.dart';
import 'package:safepoint_app/models/enums.dart';

class MockCrisisEventRepository extends Mock implements CrisisEventRepository {}

class MockAuditRepository extends Mock implements AuditRepository {}

class FakeAuditLogModel extends Fake implements AuditLogModel {}

class FakeEmergencyEventModel extends Fake implements EmergencyEventModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuditLogModel());
    registerFallbackValue(FakeEmergencyEventModel());
    registerFallbackValue(DateTime(2026));
  });

  late CrisisEventService service;
  late MockCrisisEventRepository repo;
  late MockAuditRepository auditRepo;

  final event = EmergencyEventModel(
    id: 'event_1',
    name: 'Éruption test',
    type: 'eruption',
    status: EventStatus.draft,
    volcanoName: 'Soufrière',
    startedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    repo = MockCrisisEventRepository();
    auditRepo = MockAuditRepository();
    service = CrisisEventService(repo, AuditService(auditRepo));
    when(() => auditRepo.log(any())).thenAnswer((_) async {});
  });

  group('CrisisEventService', () {
    test('activate enregistre l\'événement avec le statut actif + audit',
        () async {
      when(() => repo.save(any())).thenAnswer((_) async {});

      await service.activate(event,
          activatedBy: 'user_1', activatedByRole: 'PREFECTURE_ADMIN');

      final saved = verify(() => repo.save(captureAny())).captured.single
          as EmergencyEventModel;
      expect(saved.status, EventStatus.active,
          reason: 'l\'activation doit forcer le statut actif');
      expect(saved.id, event.id);
      verify(() => auditRepo.log(any())).called(1);
    });

    test('deactivate clôture l\'événement avec horodatage + audit', () async {
      when(() => repo.updateStatus(event.id, EventStatus.closed,
          endedAt: any(named: 'endedAt'),
          updatedBy: 'user_1')).thenAnswer((_) async {});

      await service.deactivate(event,
          deactivatedBy: 'user_1', deactivatedByRole: 'PREFECTURE_ADMIN');

      verify(() => repo.updateStatus(event.id, EventStatus.closed,
          endedAt: any(named: 'endedAt'), updatedBy: 'user_1')).called(1);
      verify(() => auditRepo.log(any())).called(1);
    });

    test('createOrUpdate enregistre et journalise la modification', () async {
      when(() => repo.save(event)).thenAnswer((_) async {});

      await service.createOrUpdate(event,
          updatedBy: 'user_1', updatedByRole: 'PREFECTURE_ADMIN');

      verify(() => repo.save(event)).called(1);
      verify(() => auditRepo.log(any())).called(1);
    });

    test('getHistory délègue au repo sans journaliser', () async {
      when(() => repo.getHistory('org_1')).thenAnswer((_) async => [event]);

      final history = await service.getHistory('org_1');

      expect(history, [event]);
      verifyNever(() => auditRepo.log(any()));
    });
  });
}
