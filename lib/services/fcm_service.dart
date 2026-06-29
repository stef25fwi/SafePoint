import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handler des messages reçus en arrière-plan (app fermée / background).
/// Doit être une fonction top-level annotée @pragma pour la compilation AOT.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Le traitement lourd (ex : maj base locale) irait ici.
  debugPrint('[FCM] Message background: ${message.messageId}');
}

/// Service de notifications push (Firebase Cloud Messaging).
///
/// Gère la permission, la récupération/persistance du token dans
/// /agents/{uid}, l'abonnement aux topics (par centre et par événement) et
/// les handlers de réception. Tout est conditionné à l'initialisation de
/// Firebase : en mode démo, `init()` est simplement ignoré.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;

  bool _initialized = false;
  String? _token;
  String? get token => _token;

  /// Initialise FCM : permission + handlers + token. À appeler une fois
  /// Firebase initialisé (après login de préférence, pour disposer de l'uid).
  Future<void> init({
    void Function(RemoteMessage message)? onForegroundMessage,
    void Function(RemoteMessage message)? onMessageOpenedApp,
  }) async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Notifications refusées par l\'utilisateur');
      return;
    }

    _token = await _messaging.getToken();
    debugPrint('[FCM] Token: $_token');

    _messaging.onTokenRefresh.listen((t) {
      _token = t;
      _persistToken(t);
    });

    if (onForegroundMessage != null) {
      FirebaseMessaging.onMessage.listen(onForegroundMessage);
    }
    if (onMessageOpenedApp != null) {
      FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
    }
  }

  /// Enregistre le token dans le profil agent pour l'envoi ciblé.
  Future<void> registerTokenForAgent(String uid) async {
    final t = _token ?? await _messaging.getToken();
    if (t == null) return;
    _token = t;
    await _persistToken(t, uid: uid);
  }

  Future<void> _persistToken(String token, {String? uid}) async {
    if (uid == null) return;
    try {
      await _db.collection('agents').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FCM] Échec persistance token: $e');
    }
  }

  /// Abonnement aux notifications d'un centre (ex : alertes locales).
  Future<void> subscribeToShelter(String shelterId) =>
      _messaging.subscribeToTopic('shelter_$shelterId');

  Future<void> unsubscribeFromShelter(String shelterId) =>
      _messaging.unsubscribeFromTopic('shelter_$shelterId');

  /// Abonnement aux notifications d'un événement de crise (broadcast préfecture).
  Future<void> subscribeToEvent(String eventId) =>
      _messaging.subscribeToTopic('event_$eventId');

  Future<void> unsubscribeFromEvent(String eventId) =>
      _messaging.unsubscribeFromTopic('event_$eventId');
}
