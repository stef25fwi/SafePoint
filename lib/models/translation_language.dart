/// Langue prise en charge par le traducteur intégré (fiche personne).
///
/// [code] : code ISO 639-1 utilisé par le service de traduction.
/// [speechLocale] : identifiant de locale pour la reconnaissance vocale
/// (`speech_to_text` / Web Speech API). Peut être `null` si aucune langue
/// vocale fiable n'est disponible pour ce code (l'utilisateur bascule alors
/// sur la saisie manuelle).
class TranslationLanguage {
  final String code;
  final String label;
  final String flag;
  final String? speechLocale;

  /// Locale de synthèse vocale (flutter_tts / Web Speech Synthesis). Par
  /// défaut identique à [speechLocale] ; pour le créole haïtien on parle en
  /// français faute de voix dédiée fiable.
  final String? ttsLocale;

  const TranslationLanguage({
    required this.code,
    required this.label,
    required this.flag,
    this.speechLocale,
    this.ttsLocale,
  });

  /// Locale à utiliser pour lire ce texte à voix haute (ttsLocale sinon
  /// speechLocale sinon le code brut).
  String get voiceLocale => ttsLocale ?? speechLocale ?? code;

  @override
  bool operator ==(Object other) =>
      other is TranslationLanguage && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// Langues courantes en contexte de crise aux Antilles/Guyane (personnes
/// évacuées, familles, travailleurs). Liste volontairement resserrée pour
/// rester lisible dans le sélecteur ; extensible selon les besoins réels.
const kTranslationLanguages = <TranslationLanguage>[
  TranslationLanguage(
      code: 'ht',
      label: 'Créole haïtien',
      flag: '🇭🇹',
      speechLocale: 'fr-HT',
      // Pas de voix TTS créole fiable : on lit en français.
      ttsLocale: 'fr-FR'),
  TranslationLanguage(
      code: 'en', label: 'Anglais', flag: '🇬🇧', speechLocale: 'en-US'),
  TranslationLanguage(
      code: 'es', label: 'Espagnol', flag: '🇪🇸', speechLocale: 'es-ES'),
  TranslationLanguage(
      code: 'pt', label: 'Portugais', flag: '🇵🇹', speechLocale: 'pt-PT'),
  TranslationLanguage(
      code: 'ar', label: 'Arabe', flag: '🇸🇦', speechLocale: 'ar-SA'),
  TranslationLanguage(
      code: 'zh',
      label: 'Chinois (mandarin)',
      flag: '🇨🇳',
      speechLocale: 'zh-CN'),
  TranslationLanguage(
      code: 'it', label: 'Italien', flag: '🇮🇹', speechLocale: 'it-IT'),
  TranslationLanguage(
      code: 'de', label: 'Allemand', flag: '🇩🇪', speechLocale: 'de-DE'),
  TranslationLanguage(
      code: 'nl', label: 'Néerlandais', flag: '🇳🇱', speechLocale: 'nl-NL'),
];

const kFrench = TranslationLanguage(
    code: 'fr', label: 'Français', flag: '🇫🇷', speechLocale: 'fr-FR');
