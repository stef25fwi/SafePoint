import 'package:flutter_test/flutter_test.dart';
import 'package:safepoint_app/models/translation_language.dart';
import 'package:safepoint_app/services/translation_service.dart';

void main() {
  group('TranslationService — garde de configuration (RGPD)', () {
    test('non configuré par défaut : aucun envoi vers un tiers', () {
      // Garde-fou central : tant qu'aucune instance de traduction n'est
      // choisie (docs/securite/09), le service doit se déclarer non
      // configuré et refuser d'envoyer du texte.
      expect(TranslationService.baseUrl, isEmpty);
      expect(TranslationService.instance.isConfigured, isFalse);
    });

    test('translate échoue explicitement quand non configuré', () async {
      expect(
        () => TranslationService.instance.translate(
          text: 'Bonjour',
          source: 'fr',
          target: 'en',
        ),
        throwsA(isA<TranslationException>().having(
          (e) => e.message,
          'message',
          contains('non configuré'),
        )),
      );
    });
  });

  group('TranslationLanguage — référentiel des langues', () {
    test('le français est disponible avec une locale vocale', () {
      expect(kFrench.code, 'fr');
      expect(kFrench.speechLocale, isNotNull);
    });

    test('les codes de langue sont uniques', () {
      final codes = kTranslationLanguages.map((l) => l.code).toSet();
      expect(codes.length, kTranslationLanguages.length);
    });

    test('le français n\'apparaît pas dans la liste interlocuteur', () {
      // La liste sert à choisir la langue de l'interlocuteur : le français
      // est géré côté agent.
      expect(kTranslationLanguages.any((l) => l.code == 'fr'), isFalse);
    });

    test('l\'égalité repose sur le code', () {
      const a = TranslationLanguage(code: 'en', label: 'A', flag: 'x');
      const b = TranslationLanguage(code: 'en', label: 'B', flag: 'y');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('voiceLocale retombe sur speechLocale quand ttsLocale est absent', () {
      const en = TranslationLanguage(
          code: 'en', label: 'Anglais', flag: '🇬🇧', speechLocale: 'en-US');
      expect(en.voiceLocale, 'en-US');
    });

    test('voiceLocale privilégie ttsLocale quand il est défini', () {
      // Le créole haïtien n'a pas de voix TTS dédiée : on lit en français.
      final ht = kTranslationLanguages.firstWhere((l) => l.code == 'ht');
      expect(ht.ttsLocale, 'fr-FR');
      expect(ht.voiceLocale, 'fr-FR');
    });

    test('voiceLocale retombe sur le code quand aucune locale n\'est fournie',
        () {
      const x = TranslationLanguage(code: 'xx', label: 'X', flag: 'x');
      expect(x.voiceLocale, 'xx');
    });

    test('chaque langue interlocuteur expose une voiceLocale non vide', () {
      for (final l in kTranslationLanguages) {
        expect(l.voiceLocale, isNotEmpty);
      }
    });
  });
}
