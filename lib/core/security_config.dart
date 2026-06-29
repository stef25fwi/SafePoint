/// Paramètres de sécurité et de conformité centralisés (RGPD / RGS / NIS2).
///
/// Ce fichier matérialise dans le code les décisions documentées dans
/// `docs/securite/`. Il sert de référence unique pour les durées de
/// conservation, la classification des données et les contacts d'incident.
class SecurityConfig {
  SecurityConfig._();

  // ── Durées de conservation (RGPD – minimisation) ────────────────
  // À aligner avec le registre des traitements et l'AIPD.

  /// Données nominatives des personnes hébergées : purge après la fin de
  /// l'événement de crise (durée maximale de rétention active).
  static const Duration personRetention = Duration(days: 30);

  /// Pointages / présences : conservation courte (gestion opérationnelle).
  static const Duration checkinRetention = Duration(days: 30);

  /// Alertes et besoins : conservation pour retour d'expérience.
  static const Duration alertRetention = Duration(days: 90);

  /// Journal d'audit : conservation prolongée (traçabilité RGS / NIS2).
  static const Duration auditRetention = Duration(days: 365);

  // ── Classification des données ──────────────────────────────────
  /// Collections contenant des données à caractère personnel (nominatives).
  static const Set<String> nominativeCollections = {
    'persons',
    'families',
    'checkins',
    'needs',
    'alerts',
    'transfers',
  };

  /// Collections d'agrégats consultables par la préfecture (non nominatives).
  static const Set<String> aggregateCollections = {
    'shelters',
    'events',
  };

  // ── Politique d'authentification (RGS) ──────────────────────────
  static const int minPasswordLength = 12;

  /// Authentification forte (MFA) recommandée pour les profils sensibles
  /// (cellule de crise, préfecture, admin). À activer côté Firebase Auth.
  static const Set<String> mfaRecommendedRoles = {
    'celluleCrise',
    'prefectureLecture',
    'admin',
  };

  // ── Réponse à incident (NIS2) ───────────────────────────────────
  /// Délai réglementaire de notification d'un incident significatif à l'ANSSI.
  static const Duration anssiNotificationDeadline = Duration(hours: 24);

  /// Contacts à renseigner par l'entité déployante (cf. plan de réponse).
  static const String dpoContact = 'dpo@__A_RENSEIGNER__';
  static const String securityContact = 'rssi@__A_RENSEIGNER__';
  static const String anssiIncidentPortal = 'https://www.cert.ssi.gouv.fr/';

  // ── Homologation de sécurité (RGS) ──────────────────────────────
  /// Statut d'homologation du service (à mettre à jour après la décision
  /// formelle de l'autorité d'homologation).
  static const String homologationStatus = 'NON_HOMOLOGUE';
  static const String monServiceSecuriseUrl =
      'https://monservicesecurise.cyber.gouv.fr/';
}
