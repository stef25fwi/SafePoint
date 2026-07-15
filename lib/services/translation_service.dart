import 'dart:convert';
import 'package:http/http.dart' as http;

/// Résultat d'une traduction : texte traduit + langue source (utile quand
/// elle est détectée automatiquement plutôt que choisie par l'utilisateur).
class TranslationResult {
  final String translatedText;
  final String detectedSourceLanguage;

  const TranslationResult({
    required this.translatedText,
    required this.detectedSourceLanguage,
  });
}

/// Erreur de traduction (réseau, service non configuré, réponse invalide).
class TranslationException implements Exception {
  final String message;
  const TranslationException(this.message);
  @override
  String toString() => message;
}

/// Service de traduction texte, bâti sur un contrat compatible LibreTranslate
/// (`POST {q, source, target, format}` → `{translatedText, detectedLanguage}`).
///
/// ⚠️ Sécurité / RGPD — les textes envoyés à ce service (paroles retranscrites
/// ou saisies, potentiellement sensibles : état de santé, vulnérabilités,
/// situation familiale) quittent l'appareil vers un service tiers. Avant mise
/// en service réelle :
///   1. Choisir un instance de traduction hébergée sous contrôle de l'entité
///      (auto-hébergement LibreTranslate recommandé — cf. doctrine
///      « Cloud au centre » / SecNumCloud, docs/securite/08) ou un
///      fournisseur sous DPA (RGPD art. 28) — jamais un point non contractualisé.
///   2. Configurer [TranslationService.baseUrl] (et [apiKey] si l'instance
///      choisie en exige un) via une configuration d'environnement, jamais
///      en dur dans le code versionné.
///   3. Documenter ce traitement dans le registre (docs/securite/03) et
///      l'AIPD (docs/securite/02) : nouvelle catégorie de destinataire.
///
/// Tant que [baseUrl] n'est pas configuré, le service échoue explicitement
/// (aucun envoi silencieux vers un tiers par défaut).
class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  /// URL de l'instance de traduction (compatible LibreTranslate).
  /// ⚠️ À REMPLACER par une instance auto-hébergée ou sous contrat avant
  /// tout usage avec des données réelles. Laisser vide désactive la fonction
  /// (échec explicite plutôt qu'envoi silencieux vers un tiers par défaut).
  static const String baseUrl = '';

  /// Clé API éventuelle de l'instance de traduction (si elle en exige une).
  static const String? apiKey = null;

  bool get isConfigured => baseUrl.isNotEmpty;

  final http.Client _client = http.Client();

  /// Traduit [text] de [source] vers [target].
  /// [source] peut être `'auto'` pour laisser le service détecter la langue
  /// (utilisé côté interlocuteur : on ne présuppose pas la langue parlée).
  Future<TranslationResult> translate({
    required String text,
    required String source,
    required String target,
  }) async {
    if (!isConfigured) {
      throw const TranslationException(
          'Service de traduction non configuré (TranslationService.baseUrl). '
          'Voir docs/securite pour le choix d\'un fournisseur.');
    }
    if (text.trim().isEmpty) {
      throw const TranslationException('Texte vide.');
    }
    try {
      final uri = Uri.parse('$baseUrl/translate');
      final res = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'q': text,
              'source': source,
              'target': target,
              'format': 'text',
              if (apiKey != null) 'api_key': apiKey,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw TranslationException(
            'Échec de la traduction (HTTP ${res.statusCode}).');
      }
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final translated = decoded['translatedText'] as String?;
      if (translated == null) {
        throw const TranslationException('Réponse de traduction invalide.');
      }
      final detected =
          decoded['detectedLanguage']?['language'] as String? ?? source;
      return TranslationResult(
        translatedText: translated,
        detectedSourceLanguage: detected,
      );
    } on TranslationException {
      rethrow;
    } catch (e) {
      throw TranslationException('Traduction indisponible : $e');
    }
  }

  void dispose() => _client.close();
}
