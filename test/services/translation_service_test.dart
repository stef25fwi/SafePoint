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
  });
}
