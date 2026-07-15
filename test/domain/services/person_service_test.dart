import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safepoint_app/domain/models/audit_log_model.dart';
import 'package:safepoint_app/domain/repositories/audit_repository.dart';
import 'package:safepoint_app/domain/repositories/checkin_repository.dart';
import 'package:safepoint_app/domain/repositories/person_repository.dart';
import 'package:safepoint_app/domain/services/audit_service.dart';
import 'package:safepoint_app/domain/services/person_service.dart';
import 'package:safepoint_app/models/checkin_model.dart';
import 'package:safepoint_app/models/enums.dart';
import 'package:safepoint_app/models/person_model.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

class MockCheckinRepository extends Mock implements CheckinRepository {}

class MockAuditRepository extends Mock implements AuditRepository {}

class FakeAuditLogModel extends Fake implements AuditLogModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuditLogModel());
  });

  late PersonService service;
  late MockPersonRepository personRepo;
  late MockCheckinRepository checkinRepo;
  late MockAuditRepository auditRepo;

  final person = PersonModel(
    id: 'person_1',
    eventId: 'event_1',
    shelterId: 'refuge_1',
    qrCode: 'sp://p1',
    firstName: 'Marie',
    lastName: 'TEST',
    status: PersonStatus.present,
    createdAt: DateTime(2026, 1, 1),
  );

  final checkin = CheckinModel(
    id: 'checkin_1',
    eventId: 'event_1',
    shelterId: 'refuge_1',
    personId: 'person_1',
    type: CheckinType.arrival,
    createdAt: DateTime(2026, 1, 1, 10),
  );

  setUp(() {
    personRepo = MockPersonRepository();
    checkinRepo = MockCheckinRepository();
    auditRepo = MockAuditRepository();
    service = PersonService(
        personRepo, checkinRepo, AuditService(auditRepo));
    when(() => auditRepo.log(any())).thenAnswer((_) async {});
  });

  group('PersonService', () {
    test('createPerson enregistre personne + pointage d\'arrivée + audit',
        () async {
      when(() => personRepo.save(person)).thenAnswer((_) async {});
      when(() => checkinRepo.save(checkin)).thenAnswer((_) async {});

      await service.createPerson(
        person,
        createdBy: 'user_1',
        createdByRole: 'AGENT',
        arrivalCheckin: checkin,
      );

      verify(() => personRepo.save(person)).called(1);
      verify(() => checkinRepo.save(checkin)).called(1);
      verify(() => auditRepo.log(any())).called(1);
    });

    test('createCheckin enregistre le pointage et met à jour le statut',
        () async {
      when(() => checkinRepo.save(checkin)).thenAnswer((_) async {});
      when(() => personRepo.updateStatus(
              person.id, PersonStatus.present, checkin.createdAt, 'user_1'))
          .thenAnswer((_) async {});

      await service.createCheckin(
        person: person,
        checkin: checkin,
        newStatus: PersonStatus.present,
        updatedBy: 'user_1',
        updatedByRole: 'AGENT',
      );

      verify(() => checkinRepo.save(checkin)).called(1);
      verify(() => personRepo.updateStatus(
          person.id, PersonStatus.present, checkin.createdAt, 'user_1'))
          .called(1);
      verify(() => auditRepo.log(any())).called(1);
    });

    test('softDelete délègue au repo et journalise l\'archivage', () async {
      when(() => personRepo.softDelete(person.id, 'user_1'))
          .thenAnswer((_) async {});

      await service.softDelete(person,
          deletedBy: 'user_1', deletedByRole: 'REFUGE_MANAGER');

      verify(() => personRepo.softDelete(person.id, 'user_1')).called(1);
      verify(() => auditRepo.log(any())).called(1);
    });

    test('getAllForExport journalise l\'export (traçabilité RGPD)', () async {
      when(() => personRepo.getAllForExport(
            organizationId: 'org_1',
            refugeId: null,
            crisisEventId: null,
          )).thenAnswer((_) async => [person]);

      final result = await service.getAllForExport(
        organizationId: 'org_1',
        requestedBy: 'user_1',
        requestedByRole: 'AUDITOR',
      );

      expect(result, [person]);
      verify(() => auditRepo.log(any())).called(1);
    });

    test('updateZone délègue au repo sans journaliser', () async {
      when(() => personRepo.updateZone(person.id, 'Zone A', 'user_1'))
          .thenAnswer((_) async {});

      await service.updateZone(person.id, 'Zone A', 'org_1', 'user_1');

      verify(() => personRepo.updateZone(person.id, 'Zone A', 'user_1'))
          .called(1);
      verifyNever(() => auditRepo.log(any()));
    });
  });
}
