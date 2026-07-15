import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safepoint_app/domain/models/audit_log_model.dart';
import 'package:safepoint_app/domain/repositories/audit_repository.dart';
import 'package:safepoint_app/domain/repositories/refuge_repository.dart';
import 'package:safepoint_app/domain/services/audit_service.dart';
import 'package:safepoint_app/domain/services/refuge_service.dart';
import 'package:safepoint_app/models/enums.dart';
import 'package:safepoint_app/models/shelter_model.dart';

class MockRefugeRepository extends Mock implements RefugeRepository {}

class MockAuditRepository extends Mock implements AuditRepository {}

class FakeAuditLogModel extends Fake implements AuditLogModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuditLogModel());
  });

  late RefugeService service;
  late MockRefugeRepository repo;
  late MockAuditRepository auditRepo;

  const shelter = ShelterModel(
    id: 'refuge_1',
    eventId: 'event_1',
    name: 'Gymnase Test',
    commune: 'Baie-Mahault',
    address: 'Rue test',
    capacity: 100,
    currentCount: 0,
    status: ShelterStatus.open,
    zones: ['Zone A'],
  );

  setUp(() {
    repo = MockRefugeRepository();
    auditRepo = MockAuditRepository();
    service = RefugeService(repo, AuditService(auditRepo));
    when(() => auditRepo.log(any())).thenAnswer((_) async {});
  });

  group('RefugeService', () {
    test('save enregistre le refuge et journalise', () async {
      when(() => repo.save(shelter)).thenAnswer((_) async {});

      await service.save(shelter,
          updatedBy: 'user_1', updatedByRole: 'REFUGE_MANAGER');

      verify(() => repo.save(shelter)).called(1);
      verify(() => auditRepo.log(any())).called(1);
    });

    test('updateStatus délègue au repo et journalise', () async {
      when(() => repo.updateStatus('refuge_1', ShelterStatus.full, 'user_1'))
          .thenAnswer((_) async {});

      await service.updateStatus(
          'refuge_1', ShelterStatus.full, 'org_1', 'user_1', 'REFUGE_MANAGER');

      verify(() =>
              repo.updateStatus('refuge_1', ShelterStatus.full, 'user_1'))
          .called(1);
      verify(() => auditRepo.log(any())).called(1);
    });

    test('updateStock délègue au repo et journalise', () async {
      final stock = {'eau': 100, 'repas': 50};
      when(() => repo.updateStock('refuge_1', stock, 'user_1'))
          .thenAnswer((_) async {});

      await service.updateStock(
          'refuge_1', stock, 'org_1', 'user_1', 'REFUGE_MANAGER');

      verify(() => repo.updateStock('refuge_1', stock, 'user_1')).called(1);
      verify(() => auditRepo.log(any())).called(1);
    });

    test('updateZones délègue au repo et journalise', () async {
      final zones = ['Zone A', 'Zone B'];
      when(() => repo.updateZones('refuge_1', zones, 'user_1'))
          .thenAnswer((_) async {});

      await service.updateZones(
          'refuge_1', zones, 'org_1', 'user_1', 'REFUGE_MANAGER');

      verify(() => repo.updateZones('refuge_1', zones, 'user_1')).called(1);
      verify(() => auditRepo.log(any())).called(1);
    });

    test('updateAgents délègue au repo et journalise', () async {
      final agents = ['Agent A'];
      when(() => repo.updateAgents('refuge_1', agents, 'user_1'))
          .thenAnswer((_) async {});

      await service.updateAgents(
          'refuge_1', agents, 'org_1', 'user_1', 'REFUGE_MANAGER');

      verify(() => repo.updateAgents('refuge_1', agents, 'user_1')).called(1);
      verify(() => auditRepo.log(any())).called(1);
    });

    test('updateResponsable délègue au repo et journalise', () async {
      when(() => repo.updateResponsable('refuge_1',
              name: 'Marc', phone: '0690', updatedBy: 'user_1'))
          .thenAnswer((_) async {});

      await service.updateResponsable(
        'refuge_1',
        name: 'Marc',
        phone: '0690',
        organizationId: 'org_1',
        updatedBy: 'user_1',
        updatedByRole: 'REFUGE_MANAGER',
      );

      verify(() => repo.updateResponsable('refuge_1',
          name: 'Marc', phone: '0690', updatedBy: 'user_1')).called(1);
      verify(() => auditRepo.log(any())).called(1);
    });
  });
}
