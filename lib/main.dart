import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/firebase_options.dart';
import 'app/environment.dart';
import 'app/service_locator.dart';
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

  // Initialise Firebase si les clés sont configurées
  final firebaseAvailable = await _tryInitFirebase();

  // Configure l'environnement
  Environment.configure(
    firebaseAvailable ? AppEnvironment.production : AppEnvironment.demo,
  );

  // Initialise le service locator (injection de dépendances)
  ServiceLocator.instance.initialize(firebaseAvailable: firebaseAvailable);

  runApp(const SafePointApp());
}

Future<bool> _tryInitFirebase() async {
  final opts = DefaultFirebaseOptions.currentPlatform;
  if (opts.apiKey.startsWith('REPLACE_WITH') || opts.apiKey == 'YOUR_API_KEY') {
    debugPrint('[SafePoint] Firebase non configuré – mode démo actif');
    return false;
  }
  try {
    await Firebase.initializeApp(options: opts);
    debugPrint('[SafePoint] Firebase initialisé (${opts.projectId})');
    return true;
  } catch (e) {
    debugPrint('[SafePoint] Erreur init Firebase: $e – mode démo actif');
    return false;
  }
}
