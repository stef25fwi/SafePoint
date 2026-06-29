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

  // Android — configuré le 2026-06-29
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyATFHDeH5DctPI0pWE2-NLZzEHZQ66LtCk',
    appId: '1:779368619357:android:b0e2f469f0ca82492fdcb4',
    messagingSenderId: '779368619357',
    projectId: 'safepoint-b36fd',
    storageBucket: 'safepoint-b36fd.firebasestorage.app',
    androidClientId: '779368619357-c2gbmtiralba9rtuvumj59ta62posn7l.apps.googleusercontent.com',
  );

  // iOS — configuré le 2026-06-29
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCk442ZwOHr6AewN7eO578l_-65wRll5lI',
    appId: '1:779368619357:ios:c0fd93121f1f519f2fdcb4',
    messagingSenderId: '779368619357',
    projectId: 'safepoint-b36fd',
    storageBucket: 'safepoint-b36fd.firebasestorage.app',
    iosBundleId: 'com.safepoint.app',
  );
}
