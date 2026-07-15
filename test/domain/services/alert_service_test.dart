import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safepoint_app/domain/models/audit_log_model.dart';
import 'package:safepoint_app/domain/repositories/alert_repository.dart';
import 'package:safepoint_app/domain/repositories/audit_repository.dart';
import 'package:safepoint_app/domain/services/alert_service.dart';
import 'package:safepoint_app/domain/services/audit_service.dart';
import 'package:safepoint_app/models/alert_model.dart';
import 'package:safepoint_app/models/enums.dart';

class MockAlertRepository extends Mock implements AlertRepository {}

class MockAuditRepository extends Mock implements AuditRepository {}

class FakeAuditLogModel extends Fake implements AuditLogModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuditLogModel());
    registerFallbackValue(DateTime(2026));
  });

  late AlertService service;
  late MockAlertRepository repo;
  late MockAuditRepository auditRepo;

  final alert = AlertModel(
    id: 'alert_1',
    eventId: 'event_1',
    shelterId: 'refuge_1',
    type: 'medical_need',
    severity: AlertSeverity.critical,
    title: 'Besoin médical',
    description: 'Test',
    status: AlertStatus.open,
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    repo = MockAlertRepository();
    auditRepo = MockAuditRepository();
    service = AlertService(repo, AuditService(auditRepo));
    when(() => auditRepo.log(any())).thenAnswer((_) async {});
  });

  group('AlertService', () {
    test('createAlert enregistre l\'alerte et journalise', () async {
      when(() => repo.save(alert)).thenAnswer((_) async {});

      await service.createAlert(alert,
          createdBy: 'user_1', createdByRole: 'AGENT');

      verify(() => repo.save(alert)).called(1);
      verify(() => auditRepo.log(any())).called(1);
    });

    test('markInProgress assigne l\'alerte à l\'agent traitant', () async {
      when(() => repo.updateStatus(alert.id, AlertStatus.inProgress,
              assignedTo: 'user_1', updatedBy: 'user_1'))
          .thenAnswer((_) async {});

      await service.markInProgress(alert,
          updatedBy: 'user_1', updatedByRole: 'AGENT');

      verify(() => repo.updateStatus(alert.id, AlertStatus.inProgress,
          assignedTo: 'user_1', updatedBy: 'user_1')).called(1);
    });

    test('resolve clôture l\'alerte avec horodatage et journalise', () async {
      when(() => repo.updateStatus(alert.id, AlertStatus.resolved,
              resolvedAt: any(named: 'resolvedAt'), updatedBy: 'user_1'))
          .thenAnswer((_) async {});

      await service.resolve(alert,
          resolvedBy: 'user_1', resolvedByRole: 'REFUGE_MANAGER');

      verify(() => repo.updateStatus(alert.id, AlertStatus.resolved,
          resolvedAt: any(named: 'resolvedAt'),
          updatedBy: 'user_1')).called(1);
      verify(() => auditRepo.log(any())).called(1);
    });
  });
}
