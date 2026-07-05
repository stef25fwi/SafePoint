import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safepoint_app/domain/models/audit_log_model.dart';
import 'package:safepoint_app/domain/repositories/messaging_repository.dart';
import 'package:safepoint_app/domain/services/audit_service.dart';
import 'package:safepoint_app/domain/services/messaging_service.dart';
import 'package:safepoint_app/domain/repositories/audit_repository.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

class MockAuditRepository extends Mock implements AuditRepository {}

class FakeAuditLogModel extends Fake implements AuditLogModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuditLogModel());
  });

  group('MessagingService', () {
    late MessagingService messagingService;
    late MockMessagingRepository mockMessagingRepository;
    late MockAuditRepository mockAuditRepository;
    late AuditService auditService;

    setUp(() {
      mockMessagingRepository = MockMessagingRepository();
      mockAuditRepository = MockAuditRepository();
      auditService = AuditService(mockAuditRepository);
      messagingService = MessagingService(mockMessagingRepository, auditService);
    });

    group('requestNotificationPermission', () {
      test('requests permission and returns FCM token', () async {
        const token = 'fcm_token_xyz123';
        const organizationId = 'org_test';
        const userId = 'user_456';
        const userRole = 'AGENT';

        when(() => mockMessagingRepository.requestNotificationPermission())
            .thenAnswer((_) async => token);
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        final result = await messagingService.requestNotificationPermission(
          organizationId: organizationId,
          userId: userId,
          userRole: userRole,
        );

        expect(result, token);
        verify(() => mockMessagingRepository.requestNotificationPermission())
            .called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
      });

      test('returns null when permission is denied', () async {
        const organizationId = 'org_test';
        const userId = 'user_456';
        const userRole = 'AGENT';

        when(() => mockMessagingRepository.requestNotificationPermission())
            .thenAnswer((_) async => null);
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        final result = await messagingService.requestNotificationPermission(
          organizationId: organizationId,
          userId: userId,
          userRole: userRole,
        );

        expect(result, null);
        verify(() => mockMessagingRepository.requestNotificationPermission())
            .called(1);
      });
    });

    group('getDeviceToken', () {
      test('returns current device FCM token', () async {
        const token = 'fcm_token_xyz123';

        when(() => mockMessagingRepository.getDeviceToken())
            .thenAnswer((_) async => token);

        final result = await messagingService.getDeviceToken();

        expect(result, token);
        verify(() => mockMessagingRepository.getDeviceToken()).called(1);
      });
    });

    group('subscribeToTopic', () {
      test('subscribes to topic and logs audit', () async {
        const topic = 'alerts_org_test';
        const organizationId = 'org_test';
        const userId = 'user_456';
        const userRole = 'AGENT';

        when(() => mockMessagingRepository.subscribeToTopic(topic))
            .thenAnswer((_) async {});
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        await messagingService.subscribeToTopic(
          topic,
          organizationId: organizationId,
          userId: userId,
          userRole: userRole,
        );

        verify(() => mockMessagingRepository.subscribeToTopic(topic))
            .called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
      });
    });

    group('unsubscribeFromTopic', () {
      test('unsubscribes from topic and logs audit', () async {
        const topic = 'alerts_org_test';
        const organizationId = 'org_test';
        const userId = 'user_456';
        const userRole = 'AGENT';

        when(() => mockMessagingRepository.unsubscribeFromTopic(topic))
            .thenAnswer((_) async {});
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        await messagingService.unsubscribeFromTopic(
          topic,
          organizationId: organizationId,
          userId: userId,
          userRole: userRole,
        );

        verify(() => mockMessagingRepository.unsubscribeFromTopic(topic))
            .called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
      });
    });

    group('sendTestNotification', () {
      test('sends test notification and logs audit', () async {
        const title = 'Test Alert';
        const body = 'This is a test notification';
        const topic = 'alerts_org_test';
        const organizationId = 'org_test';
        const userId = 'user_456';
        const userRole = 'ADMINISTRATOR';

        when(() => mockMessagingRepository.sendTestNotification(
              title: title,
              body: body,
              topic: topic,
            )).thenAnswer((_) async {});
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        await messagingService.sendTestNotification(
          title: title,
          body: body,
          topic: topic,
          organizationId: organizationId,
          userId: userId,
          userRole: userRole,
        );

        verify(() => mockMessagingRepository.sendTestNotification(
              title: title,
              body: body,
              topic: topic,
            )).called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
      });
    });

    group('onMessageReceived', () {
      test('streams incoming messages', () async {
        final testData = {
          'title': 'New Alert',
          'body': 'Someone needs help',
          'data': {'alertId': 'alert_123'},
        };

        when(() => mockMessagingRepository.onMessageReceived())
            .thenAnswer((_) => Stream.value(testData));

        final stream = messagingService.onMessageReceived();

        expect(stream, emits(testData));
      });
    });

    group('onNotificationTap', () {
      test('streams notification tap events', () async {
        final testData = {
          'title': 'Alert Tapped',
          'body': 'User opened the notification',
          'data': {'alertId': 'alert_123'},
        };

        when(() => mockMessagingRepository.onNotificationTap())
            .thenAnswer((_) => Stream.value(testData));

        final stream = messagingService.onNotificationTap();

        expect(stream, emits(testData));
      });
    });
  });
}
