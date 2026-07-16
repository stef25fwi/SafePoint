import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/messaging_repository.dart';

class FirebaseMessagingRepository implements MessagingRepository {
  FirebaseMessagingRepository() : _messaging = FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<String?> requestNotificationPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await getDeviceToken();
        debugPrint('[FCM] Permission granted. Token: $token');
        return token;
      } else {
        debugPrint('[FCM] Permission denied');
        return null;
      }
    } catch (e) {
      debugPrint('[FCM] Permission request error: $e');
      return null;
    }
  }

  @override
  Future<String?> getDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('[FCM] Device token: $token');
      return token;
    } catch (e) {
      debugPrint('[FCM] Get token error: $e');
      return null;
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('[FCM] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Subscribe error: $e');
      rethrow;
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('[FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Unsubscribe error: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendTestNotification({
    required String title,
    required String body,
    required String topic,
  }) async {
    try {
      // Note: In production, this is handled by Cloud Functions
      // This method is a placeholder for local testing
      debugPrint('[FCM] Test notification enqueued: $title - $body to $topic');
    } catch (e) {
      debugPrint('[FCM] Send test notification error: $e');
      rethrow;
    }
  }

  @override
  Stream<Map<String, dynamic>> onMessageReceived() {
    return FirebaseMessaging.onMessage.map((RemoteMessage message) {
      debugPrint(
          '[FCM] Message received in foreground: ${message.notification?.title}');
      return _extractNotificationData(message);
    });
  }

  @override
  Stream<Map<String, dynamic>> onNotificationTap() {
    return FirebaseMessaging.onMessageOpenedApp.map((RemoteMessage message) {
      debugPrint('[FCM] Notification tapped: ${message.notification?.title}');
      return _extractNotificationData(message);
    });
  }

  Map<String, dynamic> _extractNotificationData(RemoteMessage message) {
    return {
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'data': message.data,
      'messageId': message.messageId,
      'sentTime': message.sentTime,
    };
  }
}
