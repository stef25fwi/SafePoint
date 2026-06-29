import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialise Firebase si les clés sont configurées (non placeholder)
  await _tryInitFirebase();

  runApp(const SafePointApp());
}

Future<void> _tryInitFirebase() async {
  if (DefaultFirebaseOptions.web.apiKey == 'YOUR_API_KEY') {
    // Clés Firebase non configurées → mode démo avec données locales
    debugPrint('[SafePoint] Firebase non configuré – mode démo actif');
    return;
  }
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('[SafePoint] Firebase initialisé');
  } catch (e) {
    debugPrint('[SafePoint] Erreur init Firebase: $e – mode démo actif');
  }
}
