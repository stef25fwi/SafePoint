import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Enveloppe autour de `flutter_tts` : lit un texte à voix haute dans une
/// locale donnée. Utilisé par le traducteur pour que l'agent puisse faire
/// entendre à son interlocuteur la traduction (langue étrangère) de ce qu'il
/// vient de dire en français.
///
/// La synthèse vocale est locale à l'appareil/navigateur (aucune donnée ne
/// quitte le poste) — contrairement à la traduction texte qui, elle, passe
/// par un service configurable.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _speaking = false;

  bool get isSpeaking => _speaking;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _tts.awaitSpeakCompletion(true);
      _tts.setCompletionHandler(() => _speaking = false);
      _tts.setCancelHandler(() => _speaking = false);
      _tts.setErrorHandler((_) => _speaking = false);
    } catch (e) {
      if (kDebugMode) debugPrint('TTS init error: $e');
    }
  }

  /// Lit [text] dans la [localeId] fournie (ex. `en-US`, `es-ES`, `fr-FR`).
  /// Interrompt toute lecture en cours. Renvoie `false` si la synthèse
  /// vocale n'est pas disponible sur ce poste (l'appelant reste utilisable
  /// via le texte affiché).
  Future<bool> speak(String text, {required String localeId}) async {
    if (text.trim().isEmpty) return false;
    await _ensureInitialized();
    try {
      await _tts.stop();
      // setLanguage échoue si la locale n'est pas disponible : on tente une
      // solution de repli sur la langue de base (ex. 'en' pour 'en-US').
      final ok = await _trySetLanguage(localeId);
      if (!ok) return false;
      _speaking = true;
      await _tts.speak(text);
      return true;
    } catch (e) {
      _speaking = false;
      if (kDebugMode) debugPrint('TTS speak error: $e');
      return false;
    }
  }

  Future<bool> _trySetLanguage(String localeId) async {
    try {
      final available = await _tts.isLanguageAvailable(localeId);
      if (available == true) {
        await _tts.setLanguage(localeId);
        return true;
      }
    } catch (_) {}
    // Repli sur la langue sans région (« en-US » → « en »).
    final base = localeId.split('-').first;
    try {
      final available = await _tts.isLanguageAvailable(base);
      if (available == true) {
        await _tts.setLanguage(base);
        return true;
      }
    } catch (_) {}
    // Dernier recours : on tente quand même de fixer la locale complète.
    try {
      await _tts.setLanguage(localeId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _speaking = false;
  }
}
