# REFUGE VOLCAN — Markdown d’implémentation complet

Application Flutter/Firebase pour le **pointage, recensement et suivi des personnes en hébergement d’urgence** dans le cadre d’une évacuation volcanique.

Ce document est prêt à être placé dans le dépôt Codespace, par exemple :

```bash
mkdir -p docs
nano docs/REFUGE_VOLCAN_IMPLEMENTATION.md
```

---

## 1. Objectif produit

**Refuge Volcan** doit permettre à une commune, une collectivité, un centre d’hébergement ou une cellule de crise de :

- créer un événement de crise ;
- ouvrir un ou plusieurs centres d’hébergement ;
- recenser les personnes accueillies ;
- rattacher les personnes à une famille ;
- générer un QR code individuel ;
- pointer les entrées, repas, nuits, sorties et transferts ;
- suivre les personnes vulnérables ;
- gérer les alertes critiques ;
- suivre les transferts inter-centres ;
- exporter des rapports CSV/PDF ;
- fonctionner en mode hors connexion avec synchronisation dès retour réseau.

---

## 2. Stack recommandée

### Frontend

- Flutter Android / iOS / Web admin léger.
- Architecture simple :
  - `pages/` pour les écrans ;
  - `models/` pour les modèles Firestore ;
  - `services/` pour Firebase/API ;
  - `controllers/` pour la logique d’écran ;
  - `widgets/` pour composants réutilisables.
- Gestion d’état possible :
  - `ChangeNotifier` simple ;
  - ou `Riverpod` si le projet l’utilise déjà.

### Backend

- Firebase Auth.
- Firestore avec persistance hors ligne.
- Firebase Cloud Functions pour les actions sensibles.
- Firebase Storage pour PDF/exports éventuels.
- Firebase Cloud Messaging pour alertes internes.
- App Check recommandé.
- Audit logs obligatoires.

### Packages Flutter utiles

```yaml
dependencies:
  firebase_core:
  firebase_auth:
  cloud_firestore:
  cloud_functions:
  firebase_storage:
  firebase_messaging:
  mobile_scanner:
  qr_flutter:
  uuid:
  intl:
  connectivity_plus:
  path_provider:
  csv:
  pdf:
  printing:
  shared_preferences:
```

---

## 3. Structure projet recommandée

```text
lib/
  main.dart
  app.dart

  core/
    app_routes.dart
    app_theme.dart
    app_constants.dart
    result.dart
    permissions.dart

  models/
    emergency_event_model.dart
    shelter_model.dart
    person_model.dart
    family_model.dart
    checkin_model.dart
    need_model.dart
    alert_model.dart
    transfer_model.dart
    app_user_model.dart
    audit_log_model.dart

  services/
    auth_service.dart
    event_service.dart
    shelter_service.dart
    person_service.dart
    family_service.dart
    checkin_service.dart
    need_service.dart
    alert_service.dart
    transfer_service.dart
    report_service.dart
    qr_service.dart
    offline_sync_service.dart
    audit_service.dart
    notification_service.dart

  controllers/
    login_controller.dart
    dashboard_controller.dart
    persons_controller.dart
    person_form_controller.dart
    scanner_controller.dart
    person_detail_controller.dart
    families_controller.dart
    alerts_controller.dart
    transfers_controller.dart
    reports_controller.dart

  pages/
    login_page.dart
    main_shell_page.dart
    dashboard_page.dart
    persons_page.dart
    person_form_page.dart
    scanner_page.dart
    person_detail_page.dart
    families_page.dart
    alerts_page.dart
    transfers_page.dart
    reports_page.dart

  widgets/
    app_header.dart
    crisis_banner.dart
    kpi_card.dart
    primary_button.dart
    secondary_button.dart
    status_badge.dart
    bottom_nav.dart
    person_card.dart
    family_card.dart
    alert_card.dart
    transfer_card.dart
    empty_state.dart
    offline_banner.dart
```

---

## 4. Routes Flutter

```dart
class AppRoutes {
  static const login = '/login';
  static const shell = '/';
  static const dashboard = '/dashboard';
  static const persons = '/persons';
  static const personForm = '/person-form';
  static const scanner = '/scanner';
  static const personDetail = '/person-detail';
  static const families = '/families';
  static const alerts = '/alerts';
  static const transfers = '/transfers';
  static const reports = '/reports';
}
```

### Navigation principale

```text
LoginPage
  -> MainShellPage
      -> DashboardPage
      -> PersonsPage
      -> ScannerPage
      -> AlertsPage
      -> ReportsPage

Pages secondaires :
  PersonsPage -> PersonFormPage
  PersonsPage -> PersonDetailPage
  FamiliesPage -> PersonDetailPage
  ScannerPage -> PersonDetailPage
  AlertsPage -> PersonDetailPage / TransferDetail / NeedDetail
  TransfersPage -> CreateTransferPage
```

---

## 5. Collections Firestore

```text
emergency_events/{eventId}
  name
  type
  status
  volcanoName
  startedAt
  endedAt
  createdBy
  createdAt
  updatedAt

shelters/{shelterId}
  eventId
  name
  commune
  address
  capacity
  currentCount
  managerUserId
  status
  zones[]
  createdAt
  updatedAt

app_users/{userId}
  displayName
  email
  role
  assignedShelterIds[]
  activeEventId
  isActive
  createdAt
  updatedAt

persons/{personId}
  eventId
  shelterId
  familyId
  qrCode
  firstName
  lastName
  birthDate
  ageApprox
  originCommune
  originSector
  phone
  emergencyContactName
  emergencyContactPhone
  currentZone
  status
  vulnerabilityFlags[]
  needFlags[]
  notes
  createdBy
  createdAt
  updatedAt
  lastCheckinAt
  isDeleted

families/{familyId}
  eventId
  shelterId
  displayName
  originCommune
  memberIds[]
  membersCount
  assignedZone
  status
  isSeparated
  createdAt
  updatedAt

checkins/{checkinId}
  eventId
  shelterId
  personId
  familyId
  type
  source
  scannedBy
  createdAt
  offlineCreatedAt
  syncStatus
  notes

needs/{needId}
  eventId
  shelterId
  personId
  familyId
  type
  urgency
  status
  assignedTo
  description
  createdAt
  resolvedAt

alerts/{alertId}
  eventId
  shelterId
  personId
  familyId
  type
  severity
  title
  description
  status
  assignedTo
  createdAt
  resolvedAt

transfers/{transferId}
  eventId
  fromShelterId
  toShelterId
  personIds[]
  familyId
  status
  transportMode
  departurePlannedAt
  departedAt
  arrivalConfirmedAt
  createdBy
  confirmedBy
  notes
  createdAt
  updatedAt

audit_logs/{logId}
  eventId
  shelterId
  userId
  action
  targetType
  targetId
  metadata
  createdAt
```

---

## 6. Enumérations nécessaires

```dart
enum UserRole {
  agentAccueil,
  responsableCentre,
  celluleCrise,
  prefectureLecture,
  admin,
}

enum EventStatus {
  draft,
  active,
  paused,
  closed,
}

enum ShelterStatus {
  preparation,
  open,
  full,
  closed,
}

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

enum AlertSeverity {
  info,
  warning,
  critical,
}

enum AlertStatus {
  open,
  inProgress,
  resolved,
}

enum TransferStatus {
  pending,
  inProgress,
  confirmed,
  cancelled,
}
```

---

## 7. Services/API internes à créer

### 7.1 AuthService

Fichier : `lib/services/auth_service.dart`

Fonctions :

```dart
Future<AppUserModel> signInAgent({
  required String agentCode,
  required String password,
  required String shelterId,
});

Future<void> signOut();

Stream<AppUserModel?> watchCurrentUser();

Future<AppUserModel?> getCurrentUserProfile();

Future<bool> canAccessShelter(String shelterId);

Future<void> enableOfflineSession({
  required String agentCode,
  required String shelterId,
});
```

Interaction données :

- lit `app_users/{userId}` ;
- vérifie le rôle ;
- rattache l’utilisateur au centre sélectionné ;
- enregistre le centre actif localement.

---

### 7.2 EventService

Fichier : `lib/services/event_service.dart`

Fonctions :

```dart
Stream<EmergencyEventModel?> watchActiveEvent();

Future<EmergencyEventModel?> getActiveEvent();

Future<String> createEvent({
  required String name,
  required String type,
  required String volcanoName,
});

Future<void> activateEvent(String eventId);

Future<void> closeEvent(String eventId);
```

Cloud Function recommandée :

```text
createEmergencyEvent
activateEmergencyEvent
closeEmergencyEvent
```

Raison : éviter qu’un simple client crée ou clôture une crise sans droit admin.

---

### 7.3 ShelterService

Fichier : `lib/services/shelter_service.dart`

Fonctions :

```dart
Stream<ShelterModel> watchShelter(String shelterId);

Stream<List<ShelterModel>> watchSheltersForEvent(String eventId);

Future<void> updateShelterCapacity({
  required String shelterId,
  required int capacity,
});

Future<void> updateShelterStatus({
  required String shelterId,
  required ShelterStatus status,
});

Future<List<String>> getShelterZones(String shelterId);
```

Interaction données :

- lit `shelters` ;
- calcule capacité disponible via `currentCount` ;
- ne laisse pas un agent simple modifier la capacité.

---

### 7.4 PersonService

Fichier : `lib/services/person_service.dart`

Fonctions :

```dart
Stream<List<PersonModel>> watchPersons({
  required String eventId,
  required String shelterId,
  PersonStatus? status,
  String? searchText,
});

Stream<PersonModel> watchPerson(String personId);

Future<PersonModel?> getPersonByQrCode(String qrCode);

Future<String> createPerson({
  required String eventId,
  required String shelterId,
  required PersonDraft draft,
});

Future<void> updatePerson({
  required String personId,
  required Map<String, dynamic> data,
});

Future<void> softDeletePerson(String personId);

Future<void> updatePersonStatus({
  required String personId,
  required PersonStatus status,
});
```

Cloud Functions recommandées :

```text
createPersonWithQr
updatePersonStatusSecure
mergeDuplicatePersons
softDeletePersonSecure
```

Raison :

- génération QR unique ;
- audit obligatoire ;
- détection doublons ;
- interdiction suppression réelle côté client.

---

### 7.5 FamilyService

Fichier : `lib/services/family_service.dart`

Fonctions :

```dart
Stream<List<FamilyModel>> watchFamilies({
  required String eventId,
  required String shelterId,
  String? searchText,
});

Stream<FamilyModel> watchFamily(String familyId);

Future<String> createFamily({
  required String eventId,
  required String shelterId,
  required String displayName,
  required List<String> memberIds,
});

Future<void> addPersonToFamily({
  required String familyId,
  required String personId,
});

Future<void> removePersonFromFamily({
  required String familyId,
  required String personId,
});

Future<void> markFamilySeparated({
  required String familyId,
  required bool isSeparated,
});
```

Cloud Functions recommandées :

```text
createFamilySecure
addPersonToFamilySecure
markFamilySeparatedSecure
```

Raison :

- maintenir `membersCount` ;
- mettre à jour `persons.familyId` ;
- créer alerte automatique si famille séparée.

---

### 7.6 CheckinService

Fichier : `lib/services/checkin_service.dart`

Fonctions :

```dart
Future<String> createCheckin({
  required String eventId,
  required String shelterId,
  required String personId,
  required CheckinType type,
  String? familyId,
  String? notes,
});

Stream<List<CheckinModel>> watchPersonCheckins(String personId);

Stream<List<CheckinModel>> watchRecentCheckins({
  required String eventId,
  required String shelterId,
  int limit = 20,
});

Future<void> createFamilyCheckin({
  required String familyId,
  required CheckinType type,
});
```

Cloud Functions recommandées :

```text
createCheckinSecure
createFamilyCheckinSecure
```

Raison :

- mettre à jour `persons.lastCheckinAt` ;
- mettre à jour `persons.status` ;
- mettre à jour compte du centre ;
- générer alertes si besoin.

---

### 7.7 NeedService

Fichier : `lib/services/need_service.dart`

Fonctions :

```dart
Stream<List<NeedModel>> watchNeeds({
  required String eventId,
  required String shelterId,
  NeedType? type,
  String? status,
});

Future<String> createNeed({
  required String eventId,
  required String shelterId,
  String? personId,
  String? familyId,
  required NeedType type,
  required String urgency,
  String? description,
});

Future<void> updateNeedStatus({
  required String needId,
  required String status,
});

Future<Map<NeedType, int>> getNeedsSummary({
  required String eventId,
  required String shelterId,
});
```

---

### 7.8 AlertService

Fichier : `lib/services/alert_service.dart`

Fonctions :

```dart
Stream<List<AlertModel>> watchAlerts({
  required String eventId,
  required String shelterId,
  AlertStatus? status,
  AlertSeverity? severity,
});

Future<void> createAlert({
  required String eventId,
  required String shelterId,
  String? personId,
  String? familyId,
  required String type,
  required AlertSeverity severity,
  required String title,
  required String description,
});

Future<void> markAlertInProgress(String alertId);

Future<void> resolveAlert({
  required String alertId,
  String? resolutionNote,
});
```

Cloud Functions recommandées :

```text
createAutomaticAlert
resolveAlertSecure
```

Alertes automatiques à générer :

- enfant sans adulte ;
- personne vulnérable sans pointage depuis X heures ;
- famille séparée ;
- centre proche saturation ;
- stock faible ;
- transfert non confirmé ;
- personne non pointée depuis X heures.

---

### 7.9 TransferService

Fichier : `lib/services/transfer_service.dart`

Fonctions :

```dart
Stream<List<TransferModel>> watchTransfers({
  required String eventId,
  String? shelterId,
  TransferStatus? status,
});

Future<String> createTransfer({
  required String eventId,
  required String fromShelterId,
  required String toShelterId,
  required List<String> personIds,
  String? familyId,
  DateTime? departurePlannedAt,
  String? transportMode,
  String? notes,
});

Future<void> markTransferDeparted(String transferId);

Future<void> confirmTransferArrival(String transferId);

Future<void> cancelTransfer(String transferId);
```

Cloud Functions recommandées :

```text
createTransferSecure
markTransferDepartedSecure
confirmTransferArrivalSecure
cancelTransferSecure
```

Raison :

- mettre à jour les statuts personnes ;
- changer `shelterId` à l’arrivée confirmée ;
- décrémenter/incrémenter `currentCount` ;
- historiser dans `checkins`.

---

### 7.10 ReportService

Fichier : `lib/services/report_service.dart`

Fonctions :

```dart
Future<ReportSummary> getGlobalSummary({
  required String eventId,
});

Future<ReportSummary> getShelterSummary({
  required String eventId,
  required String shelterId,
});

Future<String> exportCsv({
  required String eventId,
  String? shelterId,
});

Future<String> exportPdf({
  required String eventId,
  String? shelterId,
});

Future<List<PersonModel>> getVulnerablePersons({
  required String eventId,
  String? shelterId,
});

Future<List<PersonModel>> getNotCheckedPersons({
  required String eventId,
  String? shelterId,
});
```

Cloud Functions recommandées :

```text
generateCrisisCsvReport
generateCrisisPdfReport
generateDailySummary
```

Raison :

- limiter l’accès aux exports ;
- éviter qu’un agent simple exporte toutes les données nominatives ;
- garder un audit des exports.

---

### 7.11 QrService

Fichier : `lib/services/qr_service.dart`

Fonctions :

```dart
String generateQrPayload({
  required String eventId,
  required String personId,
});

Future<PersonModel?> resolveQrPayload(String payload);

bool isValidQrPayload(String payload);
```

Format QR recommandé :

```text
rv://event/{eventId}/person/{personId}/token/{shortToken}
```

Le `shortToken` doit être généré côté serveur pour éviter les QR falsifiés.

---

### 7.12 AuditService

Fichier : `lib/services/audit_service.dart`

Fonctions :

```dart
Future<void> logAction({
  required String eventId,
  String? shelterId,
  required String action,
  required String targetType,
  required String targetId,
  Map<String, dynamic>? metadata,
});
```

Actions à historiser :

```text
login
offline_login
create_person
update_person
delete_person
create_checkin
create_family
update_family
create_need
create_alert
resolve_alert
create_transfer
confirm_transfer
export_csv
export_pdf
```

---

## 8. Pages et boutons

---

# PAGE 1 — Connexion agent

Fichier : `lib/pages/login_page.dart`

## Objectif

Permettre à un agent autorisé d’accéder à l’application et de choisir son centre d’affectation.

## Données affichées

- Logo Refuge Volcan.
- Nom application.
- Événement actif.
- Champ code agent.
- Champ mot de passe.
- Centre affecté.
- Option mode hors connexion.

## Boutons

| Bouton | Type | Action |
|---|---|---|
| `Se connecter` | primaire | appelle `LoginController.signIn()` |
| `Mode hors connexion` | secondaire | appelle `LoginController.enableOfflineMode()` |
| `Mot de passe oublié ?` | lien | ouvre procédure de récupération |
| `Se souvenir de moi` | checkbox | stocke l’agent localement |
| Dropdown centre | sélection | charge les centres disponibles |

## Fonctions contrôleur

```dart
class LoginController extends ChangeNotifier {
  Future<void> loadActiveEvent();
  Future<void> loadAvailableShelters();
  Future<void> signIn();
  Future<void> enableOfflineMode();
  void updateAgentCode(String value);
  void updatePassword(String value);
  void updateSelectedShelter(String shelterId);
  void toggleRememberMe(bool value);
}
```

## API / Services appelés

```text
EventService.getActiveEvent()
ShelterService.watchSheltersForEvent(eventId)
AuthService.signInAgent(agentCode, password, shelterId)
AuthService.enableOfflineSession(agentCode, shelterId)
AuditService.logAction(action: login/offline_login)
```

## Navigation

```text
Succès connexion -> MainShellPage / DashboardPage
Échec connexion -> afficher SnackBar erreur
Mode hors ligne -> MainShellPage avec OfflineBanner
```

## États UI

```text
loadingActiveEvent
loadingShelters
signingIn
offlineModeAvailable
errorMessage
```

---

# PAGE 2 — Accueil / Tableau de bord centre

Fichier : `lib/pages/dashboard_page.dart`

## Objectif

Donner au responsable du centre une vue immédiate de la situation.

## Données affichées

- événement actif ;
- centre courant ;
- présents ;
- places restantes ;
- familles ;
- alertes ;
- besoins urgents ;
- activité récente ;
- capacité du centre.

## Boutons

| Bouton | Type | Action |
|---|---|---|
| `Scanner QR` | raccourci | `Navigator.pushNamed(scanner)` |
| `Ajouter une personne` | raccourci | `Navigator.pushNamed(personForm)` |
| `Pointer un groupe` | raccourci | ouvre `FamiliesPage` avec mode pointage |
| `Voir tout` besoins | lien | ouvre `AlertsPage` ou `NeedsPage` |
| `Voir tout` activité | lien | ouvre historique des checkins |
| Cloche notification | icône | ouvre `AlertsPage` |
| Carte `Présents` | KPI cliquable | filtre personnes présentes |
| Carte `Places restantes` | KPI | détail capacité |
| Carte `Familles` | KPI | ouvre `FamiliesPage` |
| Carte `Alertes` | KPI | ouvre `AlertsPage` |

## Fonctions contrôleur

```dart
class DashboardController extends ChangeNotifier {
  Future<void> init();
  Stream<DashboardMetrics> watchMetrics();
  Stream<List<NeedSummaryItem>> watchNeedsSummary();
  Stream<List<CheckinModel>> watchRecentActivity();
  Future<void> refresh();
  void openScanner();
  void openPersonForm();
  void openFamilyCheckin();
  void openAlerts();
  void openReports();
}
```

## API / Services appelés

```text
EventService.watchActiveEvent()
ShelterService.watchShelter(shelterId)
PersonService.watchPersons(eventId, shelterId)
FamilyService.watchFamilies(eventId, shelterId)
AlertService.watchAlerts(eventId, shelterId, status: open)
NeedService.getNeedsSummary(eventId, shelterId)
CheckinService.watchRecentCheckins(eventId, shelterId)
```

## Calculs locaux

```dart
placesRestantes = shelter.capacity - metrics.presentCount;
capacityPercent = metrics.presentCount / shelter.capacity;
```

## Navigation

```text
Scanner QR -> ScannerPage
Ajouter une personne -> PersonFormPage
Pointer un groupe -> FamiliesPage
Alertes -> AlertsPage
Rapports -> ReportsPage
```

---

# PAGE 3 — Personnes recensées

Fichier : `lib/pages/persons_page.dart`

## Objectif

Lister, rechercher et filtrer les personnes enregistrées.

## Données affichées

- champ recherche ;
- filtres ;
- liste des personnes ;
- statut de chaque personne ;
- bouton ajout personne.

## Boutons

| Bouton | Type | Action |
|---|---|---|
| `Tous` | chip filtre | affiche toutes les personnes |
| `Présents` | chip filtre | filtre `status == present` |
| `Vulnérables` | chip filtre | filtre flags vulnérabilité |
| `Familles` | chip filtre | filtre personnes avec `familyId` |
| `Non pointés` | chip filtre | filtre `status == nonPointee` |
| Carte personne | card | ouvre `PersonDetailPage` |
| `+` | floating button | ouvre `PersonFormPage` |
| Recherche | input | applique filtre texte |
| Icône cloche | icône | ouvre `AlertsPage` |

## Fonctions contrôleur

```dart
class PersonsController extends ChangeNotifier {
  Future<void> init();
  void updateSearchText(String value);
  void setFilter(PersonFilter filter);
  Stream<List<PersonModel>> watchFilteredPersons();
  void openPersonDetail(String personId);
  void openCreatePerson();
}
```

## API / Services appelés

```text
PersonService.watchPersons(eventId, shelterId, status, searchText)
AlertService.watchAlerts(eventId, shelterId)
```

## Filtres recommandés

```dart
enum PersonFilter {
  all,
  present,
  vulnerable,
  families,
  notChecked,
}
```

## Navigation

```text
Carte personne -> PersonDetailPage(personId)
Bouton + -> PersonFormPage
```

---

# PAGE 4 — Nouvelle fiche personne

Fichier : `lib/pages/person_form_page.dart`

## Objectif

Créer rapidement une fiche personne, lui affecter un statut, une zone et générer un QR code.

## Données saisies

- nom ;
- prénom ;
- âge/date de naissance ;
- commune d’origine ;
- secteur/quartier ;
- téléphone ;
- groupe familial ;
- besoins/vulnérabilités ;
- zone du centre ;
- statut initial.

## Boutons

| Bouton | Type | Action |
|---|---|---|
| `Enregistrer et générer le QR` | primaire | valide formulaire + crée personne |
| `Annuler` | secondaire | retour page précédente |
| `Enfant` | chip | active/désactive flag enfant |
| `Personne âgée` | chip | active/désactive flag âgé |
| `PMR` | chip | active/désactive PMR |
| `Traitement médical` | chip | crée besoin médical |
| `Grossesse` | chip | active flag grossesse |
| `Animal` | chip | active besoin animal |
| Dropdown `Commune d'origine` | sélection | choisit commune |
| Dropdown `Groupe familial` | sélection | rattache famille existante |
| Dropdown `Zone du centre` | sélection | affecte zone |
| Dropdown `Statut initial` | sélection | choisit statut |

## Fonctions contrôleur

```dart
class PersonFormController extends ChangeNotifier {
  Future<void> init();
  void updateLastName(String value);
  void updateFirstName(String value);
  void updateBirthDateOrAge(String value);
  void updateOriginCommune(String value);
  void updateOriginSector(String value);
  void updatePhone(String value);
  void updateFamilyId(String? familyId);
  void toggleVulnerability(String flag);
  void toggleNeed(NeedType type);
  void updateZone(String zone);
  void updateInitialStatus(PersonStatus status);
  bool validate();
  Future<String> submit();
}
```

## API / Services appelés

```text
ShelterService.getShelterZones(shelterId)
FamilyService.watchFamilies(eventId, shelterId)
PersonService.createPerson(eventId, shelterId, draft)
NeedService.createNeed(...) si besoins cochés
AlertService.createAlert(...) si vulnérabilité critique
CheckinService.createCheckin(type: arrival) après création
AuditService.logAction(action: create_person)
```

## Cloud Function prioritaire

```text
createPersonWithQr
```

Entrée :

```json
{
  "eventId": "...",
  "shelterId": "...",
  "draft": {
    "firstName": "...",
    "lastName": "...",
    "originCommune": "...",
    "vulnerabilityFlags": ["elderly", "pmr"],
    "needFlags": ["medical"]
  }
}
```

Sortie :

```json
{
  "personId": "...",
  "qrCode": "rv://event/xxx/person/yyy/token/zzz"
}
```

## Navigation

```text
Création réussie -> PersonDetailPage(personId)
Échec validation -> rester sur page + message champ manquant
Annuler -> retour PersonsPage
```

---

# PAGE 5 — Scanner QR / Pointage rapide

Fichier : `lib/pages/scanner_page.dart`

## Objectif

Scanner un QR code et exécuter une action immédiate : entrée, repas, sortie, transfert.

## Données affichées

- caméra ;
- état scan ;
- personne reconnue ;
- actions rapides ;
- derniers scans.

## Boutons

| Bouton | Type | Action |
|---|---|---|
| `Flash` | icône | active/désactive lampe |
| `Galerie` | icône | lit QR depuis image |
| `Valider l'entrée` | action | crée checkin `arrival` |
| `Valider repas` | action | ouvre choix repas ou checkin repas |
| `Sortie` | action rouge | ouvre confirmation sortie |
| `Transfert` | action bleue | ouvre création transfert |
| `Voir tout` derniers scans | lien | ouvre historique pointage |
| Carte personne reconnue | card | ouvre fiche personne |

## Fonctions contrôleur

```dart
class ScannerController extends ChangeNotifier {
  Future<void> init();
  void onQrDetected(String payload);
  Future<void> resolveQr(String payload);
  Future<void> validateArrival();
  Future<void> validateMeal(CheckinType mealType);
  Future<void> validateExit({required bool finalExit});
  Future<void> startTransfer();
  Stream<List<CheckinModel>> watchRecentScans();
  void openPersonDetail();
  void toggleFlash();
  Future<void> scanFromGallery();
}
```

## API / Services appelés

```text
QrService.isValidQrPayload(payload)
QrService.resolveQrPayload(payload)
PersonService.getPersonByQrCode(qrCode)
CheckinService.createCheckin(type: arrival / meal / exit)
PersonService.updatePersonStatus(...)
TransferService.createTransfer(...) si transfert
AuditService.logAction(action: create_checkin)
```

## Gestion anti-doublon

Règle :

```text
Si même personne + même type de pointage + moins de 2 minutes :
  afficher "Pointage déjà enregistré"
  ne pas recréer de checkin
```

## États UI

```text
waitingScan
resolvingQr
personFound
personNotFound
invalidQr
checkinSuccess
checkinError
```

---

# PAGE 6 — Fiche personne

Fichier : `lib/pages/person_detail_page.dart`

## Objectif

Afficher le détail d’une personne, son statut, ses besoins et son historique.

## Données affichées

- nom/prénom ;
- âge ;
- zone ;
- statut ;
- commune d’origine ;
- contact ;
- groupe familial ;
- besoins ;
- historique de pointage ;
- actions rapides.

## Boutons

| Bouton | Type | Action |
|---|---|---|
| `Pointer présence` | action | crée checkin `presence` |
| `Transférer` | action | ouvre transfert prérempli |
| `Ajouter un besoin` | action | ouvre modal besoin |
| `Contacter famille` | action | lance appel si téléphone |
| Badge `Suivi requis` | info/action | ouvre alertes liées |
| Back | navigation | retour |
| Modifier | option | ouvre édition fiche |
| Supprimer/archiver | option admin | soft delete |

## Fonctions contrôleur

```dart
class PersonDetailController extends ChangeNotifier {
  Future<void> init(String personId);
  Stream<PersonModel> watchPerson();
  Stream<List<CheckinModel>> watchCheckins();
  Stream<List<NeedModel>> watchNeeds();
  Stream<List<AlertModel>> watchAlerts();
  Future<void> createPresenceCheckin();
  Future<void> addNeed(NeedType type, String description);
  Future<void> openTransfer();
  Future<void> callEmergencyContact();
  Future<void> markAsVerified();
}
```

## API / Services appelés

```text
PersonService.watchPerson(personId)
CheckinService.watchPersonCheckins(personId)
NeedService.watchNeeds(personId)
AlertService.watchAlerts(personId)
CheckinService.createCheckin(type: presence)
NeedService.createNeed(...)
TransferService.createTransfer(...)
AuditService.logAction(...)
```

## Navigation

```text
Transférer -> TransfersPage/CreateTransferPage avec personId prérempli
Ajouter besoin -> modal AddNeed
Famille -> FamiliesPage ou FamilyDetailPage
```

---

# PAGE 7 — Familles et regroupement

Fichier : `lib/pages/families_page.dart`

## Objectif

Visualiser les groupes familiaux, repérer les familles séparées et pointer un groupe entier.

## Données affichées

- nombre de familles complètes ;
- familles séparées ;
- enfants seuls ;
- liste des familles ;
- membres ;
- zone assignée.

## Boutons

| Bouton | Type | Action |
|---|---|---|
| `Complètes` | filtre | affiche familles complètes |
| `Séparées` | filtre | affiche familles séparées |
| `Enfants seuls` | filtre | affiche enfants sans adulte |
| Recherche famille | input | filtre texte |
| Carte famille | card | ouvre détail famille |
| `Pointer groupe` | action | crée checkin pour tous les membres |
| `Créer famille` | action | crée nouveau groupe |
| `Ajouter membre` | action | rattache personne |
| `Marquer séparée` | action | crée alerte famille séparée |
| `Regrouper famille` | action | enlève statut séparée |

## Fonctions contrôleur

```dart
class FamiliesController extends ChangeNotifier {
  Future<void> init();
  void updateSearch(String value);
  void setFilter(FamilyFilter filter);
  Stream<List<FamilyModel>> watchFamilies();
  Future<void> createFamily(String displayName);
  Future<void> addMember(String familyId, String personId);
  Future<void> removeMember(String familyId, String personId);
  Future<void> createFamilyCheckin(String familyId, CheckinType type);
  Future<void> markSeparated(String familyId);
  Future<void> markRegrouped(String familyId);
}
```

## API / Services appelés

```text
FamilyService.watchFamilies(eventId, shelterId)
FamilyService.createFamily(...)
FamilyService.addPersonToFamily(...)
FamilyService.markFamilySeparated(...)
CheckinService.createFamilyCheckin(...)
AlertService.createAlert(type: family_separated)
PersonService.watchPersons(...)
AuditService.logAction(...)
```

## Navigation

```text
Carte famille -> FamilyDetailPage ou PersonDetailPage membre
Créer famille -> modal CreateFamily
Ajouter membre -> modal SearchPerson
```

---

# PAGE 8 — Alertes et besoins urgents

Fichier : `lib/pages/alerts_page.dart`

## Objectif

Traiter les situations critiques et suivre les besoins urgents.

## Données affichées

- nombre d’alertes ;
- onglets critiques / à traiter / résolues ;
- cartes alertes ;
- localisation ;
- heure ;
- bouton traiter.

## Boutons

| Bouton | Type | Action |
|---|---|---|
| `Critiques` | tab | filtre severity critical |
| `À traiter` | tab | filtre status open/inProgress |
| `Résolues` | tab | filtre status resolved |
| `Traiter` | action | passe alerte en `inProgress` |
| `Voir` | action | ouvre détail besoin/alerte |
| `Résoudre` | action | clôture alerte |
| Carte alerte | card | ouvre détail personne/famille |
| Badge `12 alertes` | info | aucun ou filtre toutes alertes |

## Fonctions contrôleur

```dart
class AlertsController extends ChangeNotifier {
  Future<void> init();
  void setTab(AlertTab tab);
  Stream<List<AlertModel>> watchFilteredAlerts();
  Future<void> markInProgress(String alertId);
  Future<void> resolveAlert(String alertId, String note);
  void openRelatedTarget(AlertModel alert);
}
```

## API / Services appelés

```text
AlertService.watchAlerts(eventId, shelterId, status, severity)
AlertService.markAlertInProgress(alertId)
AlertService.resolveAlert(alertId, note)
PersonService.watchPerson(personId)
FamilyService.watchFamily(familyId)
NeedService.watchNeeds(...)
AuditService.logAction(action: resolve_alert)
```

## Alertes automatiques recommandées

```text
auto_child_without_adult
auto_vulnerable_without_recent_checkin
auto_family_separated
auto_transfer_not_confirmed
auto_shelter_capacity_high
auto_stock_low
auto_person_not_checked
```

## Navigation

```text
Alerte personne -> PersonDetailPage
Alerte famille -> FamiliesPage / FamilyDetailPage
Alerte transfert -> TransfersPage
Alerte stock -> NeedsPage ou modal stock
```

---

# PAGE 9 — Transferts inter-centres

Fichier : `lib/pages/transfers_page.dart`

## Objectif

Créer, suivre et confirmer les transferts entre centres.

## Données affichées

- transferts en attente ;
- transferts en cours ;
- transferts confirmés ;
- origine ;
- destination ;
- personnes concernées ;
- horaire de départ ;
- état d’arrivée.

## Boutons

| Bouton | Type | Action |
|---|---|---|
| `Créer un transfert` | primaire | ouvre formulaire transfert |
| `Confirmer l’arrivée` | action | confirme arrivée centre destination |
| Badge `En attente` | filtre/info | filtre transferts attente |
| Badge `En cours` | filtre/info | filtre transferts cours |
| Badge `Confirmés` | filtre/info | filtre transferts confirmés |
| Carte transfert | card | ouvre détail transfert |
| `Annuler transfert` | action admin | annule transfert |
| `Marquer départ` | action | passe transfert en cours |

## Fonctions contrôleur

```dart
class TransfersController extends ChangeNotifier {
  Future<void> init();
  void setFilter(TransferStatus? status);
  Stream<List<TransferModel>> watchTransfers();
  Future<void> createTransfer(TransferDraft draft);
  Future<void> markDeparted(String transferId);
  Future<void> confirmArrival(String transferId);
  Future<void> cancelTransfer(String transferId);
  void openCreateTransfer({List<String>? personIds, String? familyId});
}
```

## API / Services appelés

```text
TransferService.watchTransfers(eventId, shelterId)
TransferService.createTransfer(...)
TransferService.markTransferDeparted(...)
TransferService.confirmTransferArrival(...)
TransferService.cancelTransfer(...)
ShelterService.watchSheltersForEvent(eventId)
PersonService.updatePersonStatus(...)
CheckinService.createCheckin(type: transferDeparture/transferArrival)
AlertService.resolveAlert(...) si alerte transfert
AuditService.logAction(...)
```

## Formulaire de création transfert

Champs :

```text
Personnes / famille
Centre de départ
Centre d’arrivée
Heure prévue
Moyen de transport
Agent responsable
Notes
```

Validation :

```text
- destination différente de l’origine ;
- au moins une personne ;
- personnes présentes ou transférables ;
- centre destination non fermé ;
- capacité destination suffisante ou avertissement responsable.
```

---

# PAGE 10 — Rapports et exports

Fichier : `lib/pages/reports_page.dart`

## Objectif

Permettre à la cellule de crise d’avoir une synthèse exploitable et d’exporter les données.

## Données affichées

- total recensés ;
- présents ;
- transférés ;
- non pointés ;
- synthèse par centre ;
- exports rapides ;
- rapports disponibles.

## Boutons

| Bouton | Type | Action |
|---|---|---|
| `Exporter CSV` | export | appelle export CSV |
| `Exporter PDF` | export | appelle export PDF |
| `Synthèse jour` | export | génère synthèse quotidienne |
| `Bilan par centre` | ligne | ouvre rapport centre |
| `Liste personnes vulnérables` | ligne | ouvre rapport filtré |
| `Historique des pointages` | ligne | ouvre historique |
| Carte KPI | card | ouvre liste filtrée |
| Graphique centre | card | ouvre détail centre |

## Fonctions contrôleur

```dart
class ReportsController extends ChangeNotifier {
  Future<void> init();
  Stream<ReportSummary> watchGlobalSummary();
  Future<void> exportCsv();
  Future<void> exportPdf();
  Future<void> generateDailySummary();
  Future<void> openShelterReport(String shelterId);
  Future<void> openVulnerablePersonsReport();
  Future<void> openCheckinsHistory();
}
```

## API / Services appelés

```text
ReportService.getGlobalSummary(eventId)
ReportService.getShelterSummary(eventId, shelterId)
ReportService.exportCsv(eventId, shelterId)
ReportService.exportPdf(eventId, shelterId)
ReportService.getVulnerablePersons(eventId, shelterId)
ReportService.getNotCheckedPersons(eventId, shelterId)
AuditService.logAction(action: export_csv/export_pdf)
```

## Permissions

```text
agentAccueil:
  aucun export nominatif

responsableCentre:
  export centre uniquement

celluleCrise:
  export global autorisé

prefectureLecture:
  lecture agrégée, export selon configuration

admin:
  tout
```

---

## 9. MainShellPage et BottomNavigation

Fichier : `lib/pages/main_shell_page.dart`

## Objectif

Encapsuler les cinq onglets principaux.

## Onglets

```dart
final tabs = [
  DashboardPage(),
  PersonsPage(),
  ScannerPage(),
  AlertsPage(),
  ReportsPage(),
];
```

## Boutons bottom nav

| Onglet | Icône | Page |
|---|---|---|
| Accueil | home | DashboardPage |
| Personnes | group | PersonsPage |
| Scanner | qr_code_scanner | ScannerPage |
| Alertes | notifications | AlertsPage |
| Rapports | assessment | ReportsPage |

## Fonctions

```dart
class MainShellController extends ChangeNotifier {
  int currentIndex = 0;
  void setTab(int index);
  void openScanner();
  Stream<int> watchOpenAlertsCount();
}
```

## Badge alertes

```text
AlertService.watchAlerts(status: open)
  -> count
  -> afficher badge rouge sur onglet Alertes
```

---

## 10. Widgets communs

### PrimaryButton

```dart
PrimaryButton(
  label: 'Se connecter',
  icon: Icons.login,
  isLoading: controller.isLoading,
  onPressed: controller.signIn,
)
```

### StatusBadge

```dart
StatusBadge(
  label: 'Présent',
  color: AppColors.success,
)
```

### KpiCard

```dart
KpiCard(
  title: 'Présents',
  value: '217',
  icon: Icons.groups,
  color: AppColors.primaryBlue,
  onTap: controller.openPresentPersons,
)
```

### CrisisBanner

```dart
CrisisBanner(
  label: 'Événement actif : Éruption volcanique – Soufrière',
  severity: AlertSeverity.critical,
)
```

### OfflineBanner

```dart
OfflineBanner(
  isOffline: controller.isOffline,
  pendingSyncCount: controller.pendingSyncCount,
)
```

---

## 11. Cloud Functions à prévoir

Dossier : `functions/src/index.ts`

### Fonctions sensibles

```text
createPersonWithQr
createCheckinSecure
createFamilyCheckinSecure
createTransferSecure
markTransferDepartedSecure
confirmTransferArrivalSecure
resolveAlertSecure
generateCrisisCsvReport
generateCrisisPdfReport
generateDailySummary
```

### Exemple logique `createCheckinSecure`

Entrée :

```json
{
  "eventId": "event_1",
  "shelterId": "shelter_1",
  "personId": "person_1",
  "type": "arrival"
}
```

Traitement :

```text
1. vérifier utilisateur connecté ;
2. vérifier rôle et accès au shelter ;
3. vérifier event actif ;
4. vérifier personne existe ;
5. éviter doublon récent ;
6. créer checkin ;
7. mettre à jour person.lastCheckinAt ;
8. mettre à jour person.status ;
9. mettre à jour shelter.currentCount si entrée/sortie ;
10. créer audit log ;
11. retourner succès.
```

Sortie :

```json
{
  "success": true,
  "checkinId": "checkin_123",
  "newStatus": "present"
}
```

---

## 12. Sécurité Firestore recommandée

Principe :

```text
- lecture limitée aux utilisateurs connectés ;
- agent lit seulement son centre ;
- responsable lit et modifie son centre ;
- cellule de crise lit tous les centres de l’événement ;
- exports via Cloud Functions uniquement ;
- suppression réelle interdite côté client ;
- audit logs en création seulement via backend.
```

Exemple simplifié :

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() {
      return request.auth != null;
    }

    function userDoc() {
      return get(/databases/$(database)/documents/app_users/$(request.auth.uid));
    }

    function role() {
      return userDoc().data.role;
    }

    function assignedShelters() {
      return userDoc().data.assignedShelterIds;
    }

    function canReadShelter(shelterId) {
      return signedIn() &&
        (
          role() in ['admin', 'celluleCrise', 'prefectureLecture'] ||
          shelterId in assignedShelters()
        );
    }

    match /persons/{personId} {
      allow read: if canReadShelter(resource.data.shelterId);
      allow create: if signedIn() && role() in ['admin', 'responsableCentre', 'agentAccueil'];
      allow update: if signedIn() && role() in ['admin', 'responsableCentre', 'agentAccueil'];
      allow delete: if false;
    }

    match /checkins/{checkinId} {
      allow read: if canReadShelter(resource.data.shelterId);
      allow create: if signedIn();
      allow update, delete: if false;
    }

    match /alerts/{alertId} {
      allow read: if canReadShelter(resource.data.shelterId);
      allow create: if signedIn();
      allow update: if signedIn() && role() in ['admin', 'responsableCentre', 'celluleCrise'];
      allow delete: if false;
    }

    match /audit_logs/{logId} {
      allow read: if signedIn() && role() in ['admin', 'celluleCrise'];
      allow create, update, delete: if false;
    }
  }
}
```

---

## 13. Gestion hors ligne

### Objectif

Permettre le recensement et le pointage même sans réseau.

### Côté Flutter

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
);
```

### Données autorisées hors ligne

```text
- création fiche personne brouillon ;
- pointage ;
- besoin simple ;
- alerte locale ;
- consultation des données déjà synchronisées.
```

### File d’attente locale

Créer une collection locale ou un stockage `shared_preferences`/Hive :

```text
offline_queue/
  actionId
  actionType
  payload
  createdAt
  retryCount
  status
```

### OfflineSyncService

```dart
class OfflineSyncService {
  Stream<bool> watchConnectivity();
  Future<void> enqueueAction(OfflineAction action);
  Future<void> syncPendingActions();
  Future<int> getPendingCount();
  Future<void> markSynced(String actionId);
  Future<void> markFailed(String actionId, String error);
}
```

### Règle UX

```text
Si hors connexion :
  - afficher bandeau "Mode hors connexion"
  - autoriser création locale
  - badge "X actions en attente"
  - synchroniser automatiquement dès retour réseau
```

---

## 14. Workflow complet des interactions

### Création personne

```text
DashboardPage
  -> bouton Ajouter une personne
  -> PersonFormPage
  -> submit()
  -> PersonService.createPerson()
  -> Cloud Function createPersonWithQr
  -> crée persons/{personId}
  -> crée QR
  -> crée checkin arrival
  -> crée audit log
  -> retour PersonDetailPage
```

### Pointage QR

```text
DashboardPage ou BottomNav
  -> ScannerPage
  -> scan QR
  -> QrService.resolveQrPayload()
  -> PersonService.getPersonByQrCode()
  -> afficher carte personne
  -> bouton Valider repas
  -> CheckinService.createCheckin()
  -> update lastCheckinAt/status
  -> afficher succès
```

### Traitement alerte

```text
AlertsPage
  -> bouton Traiter
  -> AlertService.markAlertInProgress()
  -> utilisateur ouvre fiche liée
  -> action corrective
  -> bouton Résoudre
  -> AlertService.resolveAlert()
  -> audit log
```

### Transfert

```text
PersonDetailPage
  -> Transférer
  -> TransfersPage/CreateTransfer
  -> TransferService.createTransfer()
  -> status person = transfertEnAttente
  -> bouton Marquer départ
  -> status person = transfertEnCours
  -> centre destination confirme arrivée
  -> status person = present
  -> shelterId mis à jour
  -> checkin transferArrival
```

### Export

```text
ReportsPage
  -> Exporter PDF
  -> ReportService.exportPdf()
  -> Cloud Function generateCrisisPdfReport
  -> fichier Storage sécurisé
  -> lien temporaire
  -> audit log export_pdf
```

---

## 15. Données de démonstration

À créer dans un seed dev :

```text
Event:
  Éruption volcanique – Soufrière

Shelters:
  Gymnase de Baie-Mahault, capacité 350
  Centre de Capesterre, capacité 280
  Salle de Basse-Terre, capacité 400

Persons:
  Marie JEAN-BAPTISTE, 42 ans, Dortoir A, Présente
  Lucas MARTIAL, 8 ans, Espace familles, Présent
  Élise FÉLIX, 76 ans, Zone PMR, Suivi requis
  Jean PIERRE, 31 ans, Transfert en attente
  Sophie LUREL, 28 ans, Dortoir B, Présente
  Alain NESTOR, 63 ans, Dortoir C, Non pointé

Families:
  Famille MARTIAL, 4 personnes, complète
  Famille PIERRE, 5 personnes, séparée
  Famille BERNARD, 3 personnes, complète
  Famille FÉLIX, 2 personnes, à vérifier

Alerts:
  Enfant non rattaché à un adulte – Lucas, 8 ans
  Besoin médical prioritaire – Élise FÉLIX
  Famille séparée – Famille PIERRE
  Stock faible – Couvertures

Transfers:
  Famille PIERRE -> Centre de Capesterre
  12 personnes -> Salle de Basse-Terre
  Élise FÉLIX -> Infirmerie
```

---

## 16. Checklist d’implémentation Codespace

### Étape 1 — Base projet

```bash
flutter create refuge_volcan
cd refuge_volcan
flutter pub add firebase_core firebase_auth cloud_firestore cloud_functions firebase_storage firebase_messaging mobile_scanner qr_flutter uuid intl connectivity_plus path_provider csv pdf printing shared_preferences
```

### Étape 2 — Firebase

```bash
firebase login
firebase init
flutterfire configure
```

### Étape 3 — Créer l’arborescence

```bash
mkdir -p lib/core lib/models lib/services lib/controllers lib/pages lib/widgets
```

### Étape 4 — Ajouter les modèles

Créer :

```text
person_model.dart
family_model.dart
shelter_model.dart
checkin_model.dart
alert_model.dart
transfer_model.dart
need_model.dart
```

### Étape 5 — Ajouter les services

Créer les services listés en section 7.

### Étape 6 — Ajouter les pages

Créer les pages listées en section 8.

### Étape 7 — Brancher la navigation

Créer `app_routes.dart` et `main_shell_page.dart`.

### Étape 8 — Seed données dev

Créer un script ou une page admin temporaire pour injecter les données de démonstration.

### Étape 9 — Tester les flows

```text
- connexion agent ;
- création personne ;
- génération QR ;
- scan QR ;
- pointage repas ;
- ajout besoin ;
- création alerte ;
- traitement alerte ;
- création transfert ;
- confirmation arrivée ;
- export rapport.
```

---

## 17. Priorité MVP

### MVP 1 — Indispensable

```text
1. Connexion agent
2. Tableau de bord centre
3. Liste personnes
4. Création personne
5. QR code
6. Scanner QR
7. Pointage entrée/repas/sortie
8. Alertes simples
9. Exports CSV
```

### MVP 2 — Gestion avancée

```text
1. Familles
2. Personnes vulnérables
3. Transferts inter-centres
4. PDF
5. Mode hors ligne robuste
6. Notifications internes
```

### MVP 3 — Cellule de crise

```text
1. Vue multi-centres
2. Exports globaux
3. Graphiques
4. Historique complet
5. Gestion des rôles avancée
6. Audit consultable
```

---

## 18. Nommage des boutons à utiliser dans le code

```dart
class ButtonKeys {
  static const loginSubmit = 'btn_login_submit';
  static const loginOffline = 'btn_login_offline';
  static const dashboardScanQr = 'btn_dashboard_scan_qr';
  static const dashboardAddPerson = 'btn_dashboard_add_person';
  static const dashboardFamilyCheckin = 'btn_dashboard_family_checkin';
  static const personCreateSubmit = 'btn_person_create_submit';
  static const personCreateCancel = 'btn_person_create_cancel';
  static const scannerValidateArrival = 'btn_scanner_validate_arrival';
  static const scannerValidateMeal = 'btn_scanner_validate_meal';
  static const scannerExit = 'btn_scanner_exit';
  static const scannerTransfer = 'btn_scanner_transfer';
  static const personDetailPresence = 'btn_person_detail_presence';
  static const personDetailTransfer = 'btn_person_detail_transfer';
  static const personDetailAddNeed = 'btn_person_detail_add_need';
  static const personDetailCallFamily = 'btn_person_detail_call_family';
  static const familyCreate = 'btn_family_create';
  static const familyCheckin = 'btn_family_checkin';
  static const alertTreat = 'btn_alert_treat';
  static const alertResolve = 'btn_alert_resolve';
  static const transferCreate = 'btn_transfer_create';
  static const transferMarkDeparted = 'btn_transfer_mark_departed';
  static const transferConfirmArrival = 'btn_transfer_confirm_arrival';
  static const reportExportCsv = 'btn_report_export_csv';
  static const reportExportPdf = 'btn_report_export_pdf';
  static const reportDailySummary = 'btn_report_daily_summary';
}
```

---

## 19. Prompts de développement pour Codespace

### Prompt général

```text
Implémente l’application Flutter Refuge Volcan en suivant docs/REFUGE_VOLCAN_IMPLEMENTATION.md.
Respecte l’architecture lib/models, lib/services, lib/controllers, lib/pages, lib/widgets.
Commence par créer les modèles Firestore, les services Firebase, puis les pages MVP.
Ne supprime aucune logique existante sans sauvegarde.
Ajoute des commentaires clairs et des TODO si une Cloud Function doit être créée.
```

### Prompt page par page

```text
Implémente uniquement la page [NOM_PAGE] décrite dans docs/REFUGE_VOLCAN_IMPLEMENTATION.md.
Crée le controller associé, branche les services nécessaires et utilise les widgets communs.
Tous les boutons doivent appeler une méthode du controller.
Ajoute les routes nécessaires dans app_routes.dart.
```

### Prompt services

```text
Implémente les services Firebase décrits dans docs/REFUGE_VOLCAN_IMPLEMENTATION.md.
Chaque méthode doit gérer try/catch, logs debug, erreurs lisibles et retour typé.
Ne mets aucune logique sensible côté client si elle est marquée Cloud Function recommandée.
```

---

## 20. Résultat attendu

À la fin de l’implémentation MVP, l’application doit permettre :

```text
- un agent se connecte ;
- il choisit son centre ;
- il voit le tableau de bord ;
- il crée une fiche personne ;
- un QR code est généré ;
- il scanne ce QR ;
- il valide une entrée ou un repas ;
- il consulte les personnes recensées ;
- il voit les alertes ;
- il exporte un CSV si son rôle l’autorise.
```

