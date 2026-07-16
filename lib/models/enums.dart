// ---------------------------------------------------------------------------
// V1 enums — compatible V2 Keycloak migration
// Les rôles sont les rôles canoniques cibles.
// ---------------------------------------------------------------------------

enum UserRole {
  // Rôles canoniques V2 (Keycloak-ready)
  superAdmin, // Administration globale
  prefectureAdmin, // Vue régionale, activation crise, supervision
  regionAdmin, // Vue régionale et reporting
  communeAdmin, // Gestion des refuges de sa commune
  refugeManager, // Gestion d'un refuge (anciennement: responsableCentre)
  agent, // Pointage, consultation limitée (anciennement: agentAccueil)
  readOnlyObserver, // Lecture seule (anciennement: prefectureLecture)
  crisisCell, // Accès cellule de crise (anciennement: celluleCrise)
  auditor, // Consultation des logs et rapports
}

enum EventStatus { draft, active, paused, closed }

enum ShelterStatus { preparation, open, full, closed }

enum PersonStatus {
  present,
  nonPointee,
  sortieTemporaire,
  sortieDefinitive,
  transfertEnAttente,
  transfertEnCours,
  transferee,
  hospitalisee,
  aVerifier,
}

enum CheckinType {
  arrival,
  presence,
  mealBreakfast,
  mealLunch,
  mealDinner,
  night,
  exitTemporary,
  exitFinal,
  transferDeparture,
  transferArrival,
  medical,
  douche,
  activite,
}

enum NeedType {
  medical,
  babyKit,
  blanket,
  water,
  food,
  clothes,
  phoneCharge,
  transport,
  animal,
  psychologicalSupport,
  other,
}

enum AlertSeverity { info, warning, critical }

enum AlertStatus { open, inProgress, resolved }

enum TransferStatus { pending, inProgress, confirmed, cancelled }

enum PersonFilter { all, present, vulnerable, families, notChecked }

enum FamilyFilter { all, complete, separated, childrenAlone }

enum AlertTab { critical, toTreat, resolved }

// ---------------------------------------------------------------------------
// Extensions
// ---------------------------------------------------------------------------

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Administrateur';
      case UserRole.prefectureAdmin:
        return 'Préfecture / COD';
      case UserRole.regionAdmin:
        return 'Région';
      case UserRole.communeAdmin:
        return 'Mairie / Commune';
      case UserRole.refugeManager:
        return 'Responsable de centre';
      case UserRole.agent:
        return 'Agent d\'accueil';
      case UserRole.readOnlyObserver:
        return 'Observateur lecture seule';
      case UserRole.crisisCell:
        return 'Cellule de crise';
      case UserRole.auditor:
        return 'Auditeur';
    }
  }

  // Keycloak role name (V2 migration)
  String get keycloakName {
    switch (this) {
      case UserRole.superAdmin:
        return 'SUPER_ADMIN';
      case UserRole.prefectureAdmin:
        return 'PREFECTURE_ADMIN';
      case UserRole.regionAdmin:
        return 'REGION_ADMIN';
      case UserRole.communeAdmin:
        return 'COMMUNE_ADMIN';
      case UserRole.refugeManager:
        return 'REFUGE_MANAGER';
      case UserRole.agent:
        return 'AGENT';
      case UserRole.readOnlyObserver:
        return 'READ_ONLY_OBSERVER';
      case UserRole.crisisCell:
        return 'CRISIS_CELL';
      case UserRole.auditor:
        return 'AUDITOR';
    }
  }
}

extension PersonStatusLabel on PersonStatus {
  String get label {
    switch (this) {
      case PersonStatus.present:
        return 'Présent(e)';
      case PersonStatus.nonPointee:
        return 'Non pointé(e)';
      case PersonStatus.sortieTemporaire:
        return 'Sortie temp.';
      case PersonStatus.sortieDefinitive:
        return 'Sorti(e)';
      case PersonStatus.transfertEnAttente:
        return 'Transfert en attente';
      case PersonStatus.transfertEnCours:
        return 'Transfert en cours';
      case PersonStatus.transferee:
        return 'Transféré(e)';
      case PersonStatus.hospitalisee:
        return 'Hospitalisé(e)';
      case PersonStatus.aVerifier:
        return 'Suivi requis';
    }
  }
}

extension CheckinTypeLabel on CheckinType {
  String get label {
    switch (this) {
      case CheckinType.arrival:
        return 'Arrivée';
      case CheckinType.presence:
        return 'Présence';
      case CheckinType.mealBreakfast:
        return 'Petit-déjeuner';
      case CheckinType.mealLunch:
        return 'Déjeuner';
      case CheckinType.mealDinner:
        return 'Dîner';
      case CheckinType.night:
        return 'Nuit';
      case CheckinType.exitTemporary:
        return 'Sortie temporaire';
      case CheckinType.exitFinal:
        return 'Sortie définitive';
      case CheckinType.transferDeparture:
        return 'Départ transfert';
      case CheckinType.transferArrival:
        return 'Arrivée transfert';
      case CheckinType.medical:
        return 'Passage infirmerie';
      case CheckinType.douche:
        return 'Douche';
      case CheckinType.activite:
        return 'Activité';
    }
  }
}

extension NeedTypeLabel on NeedType {
  String get label {
    switch (this) {
      case NeedType.medical:
        return 'Médical';
      case NeedType.babyKit:
        return 'Kit bébé';
      case NeedType.blanket:
        return 'Couverture';
      case NeedType.water:
        return 'Eau';
      case NeedType.food:
        return 'Alimentation';
      case NeedType.clothes:
        return 'Vêtements';
      case NeedType.phoneCharge:
        return 'Charge téléphone';
      case NeedType.transport:
        return 'Transport';
      case NeedType.animal:
        return 'Animal';
      case NeedType.psychologicalSupport:
        return 'Soutien psy';
      case NeedType.other:
        return 'Autre';
    }
  }
}
