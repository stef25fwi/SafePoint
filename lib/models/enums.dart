enum UserRole {
  agentAccueil,
  responsableCentre,
  celluleCrise,
  prefectureLecture,
  admin,
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
