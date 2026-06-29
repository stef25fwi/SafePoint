abstract class MessagingRepository {
  /// Request user permission for notifications and return FCM token
  Future<String?> requestNotificationPermission();

  /// Get the current FCM device token
  Future<String?> getDeviceToken();

  /// Subscribe to a topic for broadcast notifications
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic);

  /// Send a test notification (admin only)
  Future<void> sendTestNotification({
    required String title,
    required String body,
    required String topic,
  });

  /// Handle incoming notification (returns notification data)
  Stream<Map<String, dynamic>> onMessageReceived();

  /// Handle notification tap when app was in background
  Stream<Map<String, dynamic>> onNotificationTap();
}
