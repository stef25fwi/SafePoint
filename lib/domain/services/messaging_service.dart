import '../repositories/messaging_repository.dart';
import 'audit_service.dart';

class MessagingService {
  MessagingService(this._repo, this._audit);

  final MessagingRepository _repo;
  final AuditService _audit;

  Future<String?> requestNotificationPermission({
    required String organizationId,
    required String userId,
    required String userRole,
  }) async {
    final token = await _repo.requestNotificationPermission();

    await _audit.log(
      organizationId: organizationId,
      userId: userId,
      role: userRole,
      action: 'REQUEST_NOTIFICATION_PERMISSION',
      targetType: 'messaging',
      targetId: userId,
      metadata: {
        'tokenObtained': token != null,
      },
    );

    return token;
  }

  Future<String?> getDeviceToken() async {
    return _repo.getDeviceToken();
  }

  Future<void> subscribeToTopic(
    String topic, {
    required String organizationId,
    required String userId,
    required String userRole,
  }) async {
    await _repo.subscribeToTopic(topic);

    await _audit.log(
      organizationId: organizationId,
      userId: userId,
      role: userRole,
      action: 'SUBSCRIBE_TOPIC',
      targetType: 'messaging',
      targetId: topic,
      metadata: {'topic': topic},
    );
  }

  Future<void> unsubscribeFromTopic(
    String topic, {
    required String organizationId,
    required String userId,
    required String userRole,
  }) async {
    await _repo.unsubscribeFromTopic(topic);

    await _audit.log(
      organizationId: organizationId,
      userId: userId,
      role: userRole,
      action: 'UNSUBSCRIBE_TOPIC',
      targetType: 'messaging',
      targetId: topic,
      metadata: {'topic': topic},
    );
  }

  Future<void> sendTestNotification({
    required String title,
    required String body,
    required String topic,
    required String organizationId,
    required String userId,
    required String userRole,
  }) async {
    await _repo.sendTestNotification(
      title: title,
      body: body,
      topic: topic,
    );

    await _audit.log(
      organizationId: organizationId,
      userId: userId,
      role: userRole,
      action: 'SEND_TEST_NOTIFICATION',
      targetType: 'messaging',
      targetId: topic,
      metadata: {
        'title': title,
        'body': body,
        'topic': topic,
      },
    );
  }

  Stream<Map<String, dynamic>> onMessageReceived() {
    return _repo.onMessageReceived();
  }

  Stream<Map<String, dynamic>> onNotificationTap() {
    return _repo.onNotificationTap();
  }
}
