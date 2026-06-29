// Firebase configuration — projet safepoint-b36fd
// API keys et App IDs : Firebase Console → Paramètres → Vos applications

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // Web — configuré le 2026-06-29
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC-BLwoHwFOlKh6MDczydQknUlf6c_EFa0',
    appId: '1:779368619357:web:5d62fbaa7f49f74f2fdcb4',
    messagingSenderId: '779368619357',
    projectId: 'safepoint-b36fd',
    authDomain: 'safepoint-b36fd.firebaseapp.com',
    storageBucket: 'safepoint-b36fd.firebasestorage.app',
    measurementId: 'G-JNF8JDBE8F',
  );

  // Android — Ajouter app Android → copier apiKey et appId ici
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_ANDROID_API_KEY',
    appId: 'REPLACE_WITH_ANDROID_APP_ID',
    messagingSenderId: '779368619357',
    projectId: 'safepoint-b36fd',
    storageBucket: 'safepoint-b36fd.firebasestorage.app',
  );

  // iOS — Ajouter app iOS → copier apiKey et appId ici
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '779368619357',
    projectId: 'safepoint-b36fd',
    storageBucket: 'safepoint-b36fd.firebasestorage.app',
    iosBundleId: 'com.safepoint.app',
  );
}
