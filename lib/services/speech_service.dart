import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Résultat d'une session d'écoute vocale.
class SpeechResult {
  final String text;
  final bool isFinal;
  const SpeechResult(this.text, this.isFinal);
}

/// Enveloppe autour de `speech_to_text` : initialisation, écoute sur une
/// locale donnée, disponibilité (micro/permissions/plateforme).
///
/// Utilisé par le traducteur de la fiche personne pour capter la parole de
/// l'agent (français) et de l'interlocuteur (langue sélectionnée), en
/// complément de la saisie manuelle (toujours disponible, y compris quand la
/// reconnaissance vocale échoue ou n'est pas supportée par le navigateur).
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _available = false;

  bool get isListening => _speech.isListening;

  Future<bool> _ensureInitialized() async {
    if (_initialized) return _available;
    _initialized = true;
    try {
      _available = await _speech.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
    } catch (_) {
      _available = false;
    }
    return _available;
  }

  /// Démarre l'écoute sur la [localeId] donnée (ex. `fr-FR`, `en-US`).
  /// [onResult] est appelé à chaque mise à jour (résultats partiels puis
  /// final). Renvoie `false` si la reconnaissance vocale n'est pas
  /// disponible (permissions refusées, navigateur non supporté…) : l'appelant
  /// doit alors proposer la saisie manuelle.
  Future<bool> listen({
    required String localeId,
    required void Function(SpeechResult) onResult,
  }) async {
    final available = await _ensureInitialized();
    if (!available) return false;
    if (_speech.isListening) await _speech.stop();

    await _speech.listen(
      onResult: (r) => onResult(SpeechResult(r.recognizedWords, r.finalResult)),
      listenOptions: stt.SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        cancelOnError: true,
      ),
    );
    return true;
  }

  Future<void> stop() async {
    if (_speech.isListening) await _speech.stop();
  }
}
