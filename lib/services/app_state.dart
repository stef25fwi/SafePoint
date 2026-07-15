import 'package:flutter/foundation.dart';
import '../models/emergency_event_model.dart';
import '../models/shelter_model.dart';
import '../models/person_model.dart';
import '../models/family_model.dart';
import '../models/checkin_model.dart';
import '../models/alert_model.dart';
import '../models/transfer_model.dart';
import '../models/need_model.dart';
import '../models/enums.dart';
import '../core/constants/app_constants.dart';
import '../app/service_locator.dart';
import '../domain/services/person_service.dart';
import '../domain/services/alert_service.dart';
import '../domain/services/transfer_service.dart';
import '../domain/services/refuge_service.dart';
import '../domain/services/crisis_event_service.dart';
import '../domain/services/audit_service.dart';

// ---------------------------------------------------------------------------
// AppState — couche de coordination entre les pages Flutter et les services
// métier. Les pages appellent uniquement AppState ; AppState délègue aux
// services qui délèguent aux repositories.
//
// Pattern : Pages → AppState → Services → Repositories → Firebase / API
// ---------------------------------------------------------------------------
class AppState extends ChangeNotifier {
  AppState() {
    _initMockData();
  }

  // ---------------------------------------------------------------------------
  // Auth state
  // ---------------------------------------------------------------------------
  bool isLoggedIn = false;
  String currentAgentCode = '';
  String currentUserId = AppDefaults.demoUserId;
  String currentShelterId = 'shelter_1';
  UserRole currentRole = UserRole.refugeManager;
  bool isOffline = false;
  String get currentOrganizationId => AppDefaults.organizationId;

  // ---------------------------------------------------------------------------
  // Services (injectés depuis ServiceLocator — null si mode démo)
  // ---------------------------------------------------------------------------
  PersonService? get _personService =>
      ServiceLocator.instance.firebaseAvailable
          ? ServiceLocator.instance.personService
          : null;

  AlertService? get _alertService =>
      ServiceLocator.instance.firebaseAvailable
          ? ServiceLocator.instance.alertService
          : null;

  TransferService? get _transferService =>
      ServiceLocator.instance.firebaseAvailable
          ? ServiceLocator.instance.transferService
          : null;

  RefugeService? get _refugeService =>
      ServiceLocator.instance.firebaseAvailable
          ? ServiceLocator.instance.refugeService
          : null;

  CrisisEventService? get _crisisService =>
      ServiceLocator.instance.firebaseAvailable
          ? ServiceLocator.instance.crisisEventService
          : null;

  AuditService? get _auditService =>
      ServiceLocator.instance.firebaseAvailable
          ? ServiceLocator.instance.auditService
          : null;

  // ---------------------------------------------------------------------------
  // Permission helpers (basés sur les 9 rôles canoniques V2)
  // ---------------------------------------------------------------------------
  bool get canCreatePerson =>
      currentRole != UserRole.readOnlyObserver &&
      currentRole != UserRole.auditor;
  bool get canCheckIn =>
      currentRole != UserRole.readOnlyObserver &&
      currentRole != UserRole.auditor;
  bool get canSeeNominativeData =>
      currentRole != UserRole.readOnlyObserver;
  bool get canResolveAlerts =>
      currentRole == UserRole.refugeManager ||
      currentRole == UserRole.crisisCell ||
      currentRole == UserRole.superAdmin ||
      currentRole == UserRole.prefectureAdmin ||
      currentRole == UserRole.communeAdmin;
  bool get canValidateTransfers =>
      currentRole == UserRole.refugeManager ||
      currentRole == UserRole.superAdmin ||
      currentRole == UserRole.communeAdmin;
  bool get canExportData =>
      currentRole == UserRole.crisisCell ||
      currentRole == UserRole.superAdmin ||
      currentRole == UserRole.prefectureAdmin ||
      currentRole == UserRole.regionAdmin ||
      currentRole == UserRole.auditor;
  bool get isAdmin => currentRole == UserRole.superAdmin;
  bool get canActivateCrisis =>
      currentRole == UserRole.prefectureAdmin ||
      currentRole == UserRole.superAdmin ||
      currentRole == UserRole.crisisCell;
  bool get isCrisisActive => activeEvent.status == EventStatus.active;
  bool get canEditShelter =>
      currentRole == UserRole.refugeManager ||
      currentRole == UserRole.superAdmin ||
      currentRole == UserRole.communeAdmin;
  bool get canViewAuditLogs =>
      currentRole == UserRole.auditor ||
      currentRole == UserRole.superAdmin;
  bool get canCreateAgentAccount =>
      currentRole == UserRole.superAdmin ||
      currentRole == UserRole.prefectureAdmin ||
      currentRole == UserRole.regionAdmin ||
      currentRole == UserRole.communeAdmin ||
      currentRole == UserRole.refugeManager;

  // ---------------------------------------------------------------------------
  // Données en mémoire (mock + cache local)
  // ---------------------------------------------------------------------------
  EmergencyEventModel activeEvent = EmergencyEventModel(
    id: 'event_1',
    name: 'Éruption volcanique – Soufrière',
    type: 'eruption',
    status: EventStatus.active,
    volcanoName: 'Soufrière',
    startedAt: DateTime.now().subtract(const Duration(hours: 6)),
    organizationId: AppDefaults.organizationId,
  );

  final List<ShelterModel> shelters = [
    const ShelterModel(
      id: 'shelter_1',
      eventId: 'event_1',
      name: 'Gymnase de Baie-Mahault',
      commune: 'Baie-Mahault',
      address: 'Rue du Gymnase, Baie-Mahault',
      capacity: 350,
      currentCount: 217,
      status: ShelterStatus.open,
      zones: [
        'Dortoir A',
        'Dortoir B',
        'Dortoir C',
        'Espace familles',
        'Zone PMR',
        'Infirmerie',
        'Zone repas',
        'Zone animaux',
      ],
      responsableName: 'Marc THÉODORE',
      responsablePhone: '0690 11 22 33',
      agentNames: ['Agent LUREL', 'Agent NESTOR', 'Agent BAPTISTE'],
      stock: {
        'eau': 650,
        'repas': 230,
        'couvertures': 180,
        'lits': 120,
        'masques': 85,
        'couches': 48,
        'medicaments': 12,
      },
    ),
    const ShelterModel(
      id: 'shelter_2',
      eventId: 'event_1',
      name: 'Centre de Capesterre',
      commune: 'Capesterre-Belle-Eau',
      address: 'Avenue Général de Gaulle, Capesterre',
      capacity: 280,
      currentCount: 324,
      status: ShelterStatus.full,
      zones: ['Salle A', 'Salle B', 'Espace familles', 'Zone médicale', 'Zone repas'],
      responsableName: 'Sophie JEAN-MARIE',
      responsablePhone: '0690 44 55 66',
      agentNames: ['Agent FELIX', 'Agent PIERRE'],
      stock: {
        'eau': 200,
        'repas': 290,
        'couvertures': 210,
        'lits': 75,
        'masques': 0,
        'couches': 15,
        'medicaments': 8,
      },
    ),
    const ShelterModel(
      id: 'shelter_3',
      eventId: 'event_1',
      name: 'Salle de Basse-Terre',
      commune: 'Basse-Terre',
      address: "Place du Champ d'Arbaud, Basse-Terre",
      capacity: 400,
      currentCount: 242,
      status: ShelterStatus.open,
      zones: ['Hall principal', 'Annexe A', 'Zone PMR', 'Espace enfants', 'Infirmerie'],
      responsableName: 'Paul DUMONT',
      responsablePhone: '0690 77 88 99',
      agentNames: ['Agent MARTIN', 'Agent DUPONT', 'Agent LACOUR', 'Agent RIVIÈRE'],
      stock: {
        'eau': 900,
        'repas': 260,
        'couvertures': 300,
        'lits': 200,
        'masques': 150,
        'couches': 30,
        'medicaments': 20,
      },
    ),
  ];

  late List<PersonModel> _persons;
  late List<FamilyModel> _families;
  late List<CheckinModel> _checkins;
  late List<AlertModel> _alerts;
  late List<TransferModel> _transfers;
  late List<NeedModel> _needs;

  void _initMockData() {
    final now = DateTime.now();

    _persons = [
      PersonModel(
        id: 'person_1',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        qrCode: 'rv://event/event_1/person/person_1/token/abc123',
        firstName: 'Marie',
        lastName: 'JEAN-BAPTISTE',
        ageApprox: 42,
        originCommune: 'Saint-Claude',
        phone: '0690 12 34 56',
        currentZone: 'Dortoir A',
        status: PersonStatus.present,
        createdAt: now.subtract(const Duration(hours: 5)),
        lastCheckinAt: now.subtract(const Duration(minutes: 30)),
      ),
      PersonModel(
        id: 'person_2',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        familyId: 'family_1',
        qrCode: 'rv://event/event_1/person/person_2/token/def456',
        firstName: 'Lucas',
        lastName: 'MARTIAL',
        ageApprox: 8,
        originCommune: 'Baillif',
        currentZone: 'Espace familles',
        status: PersonStatus.present,
        vulnerabilityFlags: const ['enfant'],
        createdAt: now.subtract(const Duration(hours: 4)),
        lastCheckinAt: now.subtract(const Duration(minutes: 45)),
      ),
      PersonModel(
        id: 'person_3',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        familyId: 'family_4',
        qrCode: 'rv://event/event_1/person/person_3/token/ghi789',
        firstName: 'Élise',
        lastName: 'FÉLIX',
        ageApprox: 76,
        originCommune: 'Saint-Claude',
        phone: '0690 00 00 00',
        currentZone: 'Zone PMR',
        status: PersonStatus.aVerifier,
        vulnerabilityFlags: const ['personne_agee', 'pmr'],
        needFlags: const [NeedType.medical],
        createdAt: now.subtract(const Duration(hours: 5, minutes: 30)),
        lastCheckinAt: now.subtract(const Duration(hours: 1, minutes: 10)),
      ),
      PersonModel(
        id: 'person_4',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        familyId: 'family_2',
        qrCode: 'rv://event/event_1/person/person_4/token/jkl012',
        firstName: 'Jean',
        lastName: 'PIERRE',
        ageApprox: 31,
        originCommune: 'Capesterre-Belle-Eau',
        phone: '0690 45 67 89',
        currentZone: 'Transfert en attente',
        status: PersonStatus.transfertEnAttente,
        createdAt: now.subtract(const Duration(hours: 3)),
        lastCheckinAt: now.subtract(const Duration(hours: 2)),
      ),
      PersonModel(
        id: 'person_5',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        qrCode: 'rv://event/event_1/person/person_5/token/mno345',
        firstName: 'Sophie',
        lastName: 'LUREL',
        ageApprox: 28,
        originCommune: 'Trois-Rivières',
        phone: '0690 23 45 67',
        currentZone: 'Dortoir B',
        status: PersonStatus.present,
        createdAt: now.subtract(const Duration(hours: 4, minutes: 15)),
        lastCheckinAt: now.subtract(const Duration(minutes: 20)),
      ),
      PersonModel(
        id: 'person_6',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        qrCode: 'rv://event/event_1/person/person_6/token/pqr678',
        firstName: 'Alain',
        lastName: 'NESTOR',
        ageApprox: 63,
        originCommune: 'Gourbeyre',
        currentZone: 'Dortoir C',
        status: PersonStatus.nonPointee,
        vulnerabilityFlags: const ['personne_agee', 'sans_papiers', 'isolement'],
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      PersonModel(
        id: 'person_7',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        familyId: 'family_1',
        qrCode: 'rv://event/event_1/person/person_7/token/stu901',
        firstName: 'Jean-Baptiste',
        lastName: 'MARTIAL',
        ageApprox: 38,
        originCommune: 'Baillif',
        phone: '0690 78 90 12',
        currentZone: 'Dortoir B',
        status: PersonStatus.present,
        createdAt: now.subtract(const Duration(hours: 4)),
        lastCheckinAt: now.subtract(const Duration(minutes: 15)),
      ),
      PersonModel(
        id: 'person_8',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        familyId: 'family_1',
        qrCode: 'rv://event/event_1/person/person_8/token/vwx234',
        firstName: 'Marie-Line',
        lastName: 'MARTIAL',
        ageApprox: 35,
        originCommune: 'Baillif',
        currentZone: 'Dortoir B',
        status: PersonStatus.present,
        createdAt: now.subtract(const Duration(hours: 4)),
        lastCheckinAt: now.subtract(const Duration(minutes: 20)),
      ),
    ];

    _families = [
      FamilyModel(
        id: 'family_1',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        displayName: 'Famille MARTIAL',
        originCommune: 'Baillif',
        memberIds: const ['person_2', 'person_7', 'person_8'],
        membersCount: 4,
        assignedZone: 'A1',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      FamilyModel(
        id: 'family_2',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        displayName: 'Famille PIERRE',
        originCommune: 'Capesterre-Belle-Eau',
        memberIds: const ['person_4'],
        membersCount: 5,
        assignedZone: 'B2',
        isSeparated: true,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      FamilyModel(
        id: 'family_3',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        displayName: 'Famille BERNARD',
        memberIds: const [],
        membersCount: 3,
        assignedZone: 'C1',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      FamilyModel(
        id: 'family_4',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        displayName: 'Famille FÉLIX',
        originCommune: 'Saint-Claude',
        memberIds: const ['person_3'],
        membersCount: 2,
        assignedZone: 'D2',
        createdAt: now.subtract(const Duration(hours: 5, minutes: 30)),
      ),
    ];

    _checkins = [
      CheckinModel(
        id: 'checkin_1',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        personId: 'person_7',
        familyId: 'family_1',
        type: CheckinType.arrival,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      CheckinModel(
        id: 'checkin_2',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        personId: 'person_3',
        type: CheckinType.arrival,
        createdAt: now.subtract(const Duration(hours: 5, minutes: 30)),
      ),
      CheckinModel(
        id: 'checkin_3',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        personId: 'person_3',
        type: CheckinType.mealBreakfast,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 10)),
      ),
      CheckinModel(
        id: 'checkin_4',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        personId: 'person_3',
        type: CheckinType.medical,
        createdAt: now.subtract(const Duration(minutes: 45)),
      ),
      CheckinModel(
        id: 'checkin_5',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        personId: 'person_7',
        familyId: 'family_1',
        type: CheckinType.presence,
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
    ];

    _alerts = [
      AlertModel(
        id: 'alert_1',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        personId: 'person_2',
        type: 'child_without_adult',
        severity: AlertSeverity.critical,
        title: 'Enfant non rattaché à un adulte – Lucas, 8 ans',
        description: "Un enfant de 8 ans est sans accompagnateur connu.",
        status: AlertStatus.open,
        location: 'Zone A – Accueil',
        createdAt: now.subtract(const Duration(minutes: 37)),
      ),
      AlertModel(
        id: 'alert_2',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        personId: 'person_3',
        type: 'medical_need',
        severity: AlertSeverity.critical,
        title: 'Besoin médical prioritaire – Élise FÉLIX',
        description: 'Femme enceinte signalant des douleurs et besoin de suivi.',
        status: AlertStatus.open,
        location: 'Zone B – Soins',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 45)),
      ),
      AlertModel(
        id: 'alert_3',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        familyId: 'family_2',
        type: 'family_separated',
        severity: AlertSeverity.warning,
        title: 'Famille séparée – Famille PIERRE',
        description: '2 enfants séparés de leurs parents depuis le transfert.',
        status: AlertStatus.open,
        location: 'Zone C – Hébergement',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 21)),
      ),
      AlertModel(
        id: 'alert_4',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        type: 'stock_low',
        severity: AlertSeverity.info,
        title: 'Stock faible – Couvertures',
        description: 'Niveau de couvertures inférieur au seuil minimum.',
        status: AlertStatus.open,
        location: 'Réserve – Matériel',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 18)),
      ),
    ];

    _transfers = [
      TransferModel(
        id: 'transfer_1',
        eventId: 'event_1',
        fromShelterId: 'shelter_1',
        fromShelterName: 'Gymnase de Baie-Mahault',
        toShelterId: 'shelter_2',
        toShelterName: 'Centre de Capesterre',
        personIds: const ['person_4'],
        familyId: 'family_2',
        familyName: 'Famille PIERRE',
        status: TransferStatus.pending,
        transportMode: 'Bus',
        departurePlannedAt: DateTime(now.year, now.month, now.day, 10, 0),
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      TransferModel(
        id: 'transfer_2',
        eventId: 'event_1',
        fromShelterId: 'shelter_1',
        fromShelterName: 'École de Gourbeyre',
        toShelterId: 'shelter_3',
        toShelterName: 'Salle de Basse-Terre',
        personIds: List.generate(12, (i) => 'person_ext_$i'),
        status: TransferStatus.inProgress,
        transportMode: 'Bus',
        departurePlannedAt: DateTime(now.year, now.month, now.day, 11, 30),
        departedAt: DateTime(now.year, now.month, now.day, 11, 35),
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      TransferModel(
        id: 'transfer_3',
        eventId: 'event_1',
        fromShelterId: 'shelter_1',
        fromShelterName: 'Gymnase de Baie-Mahault',
        toShelterId: 'shelter_infirmerie',
        toShelterName: 'Infirmerie',
        personIds: const ['person_3'],
        status: TransferStatus.confirmed,
        transportMode: 'Ambulance',
        departurePlannedAt: DateTime(now.year, now.month, now.day, 9, 0),
        departedAt: DateTime(now.year, now.month, now.day, 9, 0),
        arrivalConfirmedAt: DateTime(now.year, now.month, now.day, 9, 28),
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
    ];

    _needs = [
      NeedModel(
        id: 'need_1',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        personId: 'person_3',
        type: NeedType.medical,
        urgency: 'critical',
        status: 'open',
        description: 'Traitement médical quotidien',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      NeedModel(
        id: 'need_2',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        type: NeedType.babyKit,
        urgency: 'high',
        status: 'open',
        description: 'Kits bébé pour les familles avec nourrissons',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      NeedModel(
        id: 'need_3',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        type: NeedType.blanket,
        urgency: 'medium',
        status: 'open',
        description: 'Stock de couvertures insuffisant',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Getters (données locales / mock)
  // ---------------------------------------------------------------------------
  ShelterModel get currentShelter =>
      shelters.firstWhere((s) => s.id == currentShelterId);

  List<PersonModel> get allPersons => _persons
      .where((p) => !p.isDeleted && p.shelterId == currentShelterId)
      .toList();

  List<PersonModel> get presentPersons =>
      allPersons.where((p) => p.status == PersonStatus.present).toList();

  List<PersonModel> get vulnerablePersons =>
      allPersons.where((p) => p.isVulnerable).toList();

  List<FamilyModel> get currentFamilies =>
      _families.where((f) => f.shelterId == currentShelterId).toList();

  List<AlertModel> get openAlerts => _alerts
      .where((a) =>
          a.shelterId == currentShelterId && a.status != AlertStatus.resolved)
      .toList();

  List<AlertModel> get allAlerts =>
      _alerts.where((a) => a.shelterId == currentShelterId).toList();

  List<CheckinModel> get recentCheckins =>
      _checkins.where((c) => c.shelterId == currentShelterId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<TransferModel> get currentTransfers => _transfers
      .where((t) =>
          t.fromShelterId == currentShelterId ||
          t.toShelterId == currentShelterId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<NeedModel> get currentNeeds => _needs
      .where((n) => n.shelterId == currentShelterId && n.status == 'open')
      .toList();

  PersonModel? getPersonById(String id) {
    try {
      return _persons.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  FamilyModel? getFamilyById(String id) {
    try {
      return _families.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CheckinModel> getPersonCheckins(String personId) =>
      _checkins.where((c) => c.personId == personId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<AlertModel> getPersonAlerts(String personId) =>
      _alerts.where((a) => a.personId == personId).toList();

  List<NeedModel> getPersonNeeds(String personId) => _needs
      .where((n) => n.personId == personId && n.status == 'open')
      .toList();

  List<PersonModel> getFamilyMembers(String familyId) =>
      _persons.where((p) => p.familyId == familyId && !p.isDeleted).toList();

  Map<String, int> get countsByShelterId {
    final map = <String, int>{};
    for (final s in shelters) {
      map[s.id] =
          _persons.where((p) => p.shelterId == s.id && !p.isDeleted).length;
    }
    return map;
  }

  // ── Occupation en direct (source unique de vérité) ──────────────────
  // ShelterModel.currentCount est un compteur dénormalisé côté Firestore,
  // jamais recalculé automatiquement lors des ajouts/transferts/sorties.
  // Ces accesseurs recalculent l'occupation à partir des personnes réelles
  // (même logique que countsByShelterId) et doivent être utilisés partout
  // où une capacité/occupation est affichée, plutôt que shelter.currentCount.

  /// Nombre réel de personnes recensées pour ce centre (non supprimées).
  int occupancyOf(String shelterId) => countsByShelterId[shelterId] ?? 0;

  /// Places restantes réelles = capacité - occupation réelle.
  int placesRestantesOf(String shelterId) {
    final shelter = shelters.firstWhere(
      (s) => s.id == shelterId,
      orElse: () => currentShelter,
    );
    return shelter.capacity - occupancyOf(shelterId);
  }

  /// Taux d'occupation réel (0.0 à 1.0+).
  double capacityPercentOf(String shelterId) {
    final shelter = shelters.firstWhere(
      (s) => s.id == shelterId,
      orElse: () => currentShelter,
    );
    if (shelter.capacity <= 0) return 0.0;
    return occupancyOf(shelterId) / shelter.capacity;
  }

  // ── Analytics cross-centres (cellule de crise / préfecture) ────────
  /// Toutes les personnes non supprimées, tous centres confondus.
  List<PersonModel> get everyPerson =>
      _persons.where((p) => !p.isDeleted).toList();

  /// Tous les besoins ouverts, tous centres confondus.
  List<NeedModel> get everyOpenNeed =>
      _needs.where((n) => n.status == 'open').toList();

  /// Toutes les personnes non pointées, tous centres confondus.
  List<PersonModel> get everyNonPointee => _persons
      .where((p) => !p.isDeleted && p.status == PersonStatus.nonPointee)
      .toList();

  /// Répartition des personnes par commune d'origine (tous centres).
  Map<String, int> get countsByOriginCommune {
    final map = <String, int>{};
    for (final p in everyPerson) {
      final key = p.originCommune ?? 'Non renseignée';
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  // ── Journal d'audit (RGS / NIS2) — délègue au service métier ───────
  void _auditExportOrAccess(String action, String targetType,
      {String? targetId, Map<String, dynamic>? metadata}) {
    _auditService?.log(
      organizationId: currentOrganizationId,
      userId: currentUserId,
      role: currentRole.name,
      action: action,
      targetType: targetType,
      targetId: targetId,
      metadata: metadata,
    );
  }

  /// Consigne un export (rapport + format).
  void auditExport(String report, String format) => _auditExportOrAccess(
        'export',
        'report',
        metadata: {'report': report, 'format': format},
      );

  /// Consigne une consultation de données nominatives (RGPD – traçabilité).
  void auditNominativeAccess(String targetType, String targetId) =>
      _auditExportOrAccess('access_nominative', targetType, targetId: targetId);

  // ---------------------------------------------------------------------------
  // Actions — délèguent aux services métier si Firebase disponible
  // ---------------------------------------------------------------------------

  void login(
    String agentCode,
    String shelterId, {
    bool offline = false,
    UserRole role = UserRole.agent,
  }) {
    isLoggedIn = true;
    currentAgentCode = agentCode;
    currentShelterId = shelterId;
    currentRole = role;
    isOffline = offline;
    _auditService?.log(
      organizationId: currentOrganizationId,
      userId: currentUserId,
      role: role.keycloakName,
      action: 'LOGIN',
      targetType: 'user',
      targetId: currentUserId,
    );
    notifyListeners();
  }

  Future<void> loginAgent({
    required String agentCode,
    required String password,
  }) async {
    // Mode démo : accepter tout code agent
    isLoggedIn = true;
    currentAgentCode = agentCode;
    currentRole = UserRole.agent;
    isOffline = false;
    // TODO: En production, appeler Cloud Function loginAgent
    _auditService?.log(
      organizationId: currentOrganizationId,
      userId: currentUserId,
      role: currentRole.keycloakName,
      action: 'LOGIN',
      targetType: 'user',
      targetId: currentUserId,
    );
    notifyListeners();
  }

  Future<void> loginOffline({
    required String agentCode,
  }) async {
    isLoggedIn = true;
    currentAgentCode = agentCode;
    currentRole = UserRole.agent;
    isOffline = true;
    _auditService?.log(
      organizationId: currentOrganizationId,
      userId: currentUserId,
      role: currentRole.keycloakName,
      action: 'LOGIN',
      targetType: 'user',
      targetId: currentUserId,
      metadata: {'offline': true},
    );
    notifyListeners();
  }

  void logout() {
    _auditService?.log(
      organizationId: currentOrganizationId,
      userId: currentUserId,
      role: currentRole.keycloakName,
      action: 'LOGOUT',
      targetType: 'user',
      targetId: currentUserId,
    );
    isLoggedIn = false;
    currentAgentCode = '';
    isOffline = false;
    notifyListeners();
  }

  void addPerson(PersonModel person) {
    _persons.add(person);
    final now = DateTime.now();
    final arrivalCheckin = CheckinModel(
      id: 'checkin_${now.millisecondsSinceEpoch}',
      eventId: activeEvent.id,
      shelterId: currentShelterId,
      personId: person.id,
      type: CheckinType.arrival,
      createdAt: now,
      createdBy: currentUserId,
    );
    _checkins.add(arrivalCheckin);

    // Délègue au service métier si Firebase disponible
    _personService?.createPerson(
      person,
      createdBy: currentUserId,
      createdByRole: currentRole.keycloakName,
      arrivalCheckin: arrivalCheckin,
    );

    notifyListeners();
  }

  void createCheckin({
    required String personId,
    required CheckinType type,
    String? notes,
  }) {
    final now = DateTime.now();
    final checkin = CheckinModel(
      id: 'checkin_${now.millisecondsSinceEpoch}',
      eventId: activeEvent.id,
      shelterId: currentShelterId,
      personId: personId,
      type: type,
      createdAt: now,
      notes: notes,
      createdBy: currentUserId,
    );
    _checkins.add(checkin);

    final idx = _persons.indexWhere((p) => p.id == personId);
    PersonStatus? newStatus;
    if (idx >= 0) {
      if (type == CheckinType.exitFinal) {
        newStatus = PersonStatus.sortieDefinitive;
      } else if (type == CheckinType.exitTemporary) {
        newStatus = PersonStatus.sortieTemporaire;
      } else if (type == CheckinType.medical) {
        newStatus = PersonStatus.hospitalisee;
      } else if (type == CheckinType.arrival ||
          type == CheckinType.presence ||
          type == CheckinType.mealBreakfast ||
          type == CheckinType.mealLunch ||
          type == CheckinType.mealDinner ||
          type == CheckinType.night) {
        newStatus = PersonStatus.present;
      }
      _persons[idx] = _persons[idx].copyWith(
        status: newStatus,
        lastCheckinAt: now,
        updatedBy: currentUserId,
      );
    }

    final person = idx >= 0 ? _persons[idx] : null;
    if (person != null && newStatus != null) {
      _personService?.createCheckin(
        person: person,
        checkin: checkin,
        newStatus: newStatus,
        updatedBy: currentUserId,
        updatedByRole: currentRole.keycloakName,
      );
    }

    notifyListeners();
  }

  void resolveAlert(String alertId) {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx >= 0) {
      final resolved = DateTime.now();
      final alert = _alerts[idx];
      _alerts[idx] = alert.copyWith(
        status: AlertStatus.resolved,
        resolvedAt: resolved,
        updatedBy: currentUserId,
      );
      _alertService?.resolve(
        alert,
        resolvedBy: currentUserId,
        resolvedByRole: currentRole.keycloakName,
      );
    }
    notifyListeners();
  }

  void markAlertInProgress(String alertId) {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx >= 0) {
      final alert = _alerts[idx];
      _alerts[idx] = alert.copyWith(status: AlertStatus.inProgress, updatedBy: currentUserId);
      _alertService?.markInProgress(
        alert,
        updatedBy: currentUserId,
        updatedByRole: currentRole.keycloakName,
      );
    }
    notifyListeners();
  }

  void confirmTransferArrival(String transferId) {
    final idx = _transfers.indexWhere((t) => t.id == transferId);
    if (idx >= 0) {
      final now = DateTime.now();
      final transfer = _transfers[idx];
      _transfers[idx] = transfer.copyWith(
        status: TransferStatus.confirmed,
        arrivalConfirmedAt: now,
        updatedBy: currentUserId,
      );
      _transferService?.confirmArrival(
        transfer,
        updatedBy: currentUserId,
        updatedByRole: currentRole.keycloakName,
      );
    }
    notifyListeners();
  }

  void markTransferDeparted(String transferId) {
    final idx = _transfers.indexWhere((t) => t.id == transferId);
    if (idx >= 0) {
      final now = DateTime.now();
      final transfer = _transfers[idx];
      _transfers[idx] = transfer.copyWith(
        status: TransferStatus.inProgress,
        departedAt: now,
        updatedBy: currentUserId,
      );
      _transferService?.markDeparted(
        transfer,
        updatedBy: currentUserId,
        updatedByRole: currentRole.keycloakName,
      );
    }
    notifyListeners();
  }

  void addTransfer(TransferModel transfer) {
    _transfers.add(transfer);
    _transferService?.createTransfer(
      transfer,
      createdBy: currentUserId,
      createdByRole: currentRole.keycloakName,
    );
    notifyListeners();
  }

  void markFamilySeparated(String familyId, bool separated) {
    final idx = _families.indexWhere((f) => f.id == familyId);
    if (idx >= 0) {
      _families[idx] = _families[idx].copyWith(
        isSeparated: separated,
        updatedBy: currentUserId,
      );
      ServiceLocator.instance.firebaseAvailable
          ? ServiceLocator.instance.familyRepository.updateSeparated(
              familyId, separated, currentUserId)
          : null;
    }
    notifyListeners();
  }

  void addNeed(NeedModel need) {
    _needs.add(need);
    ServiceLocator.instance.firebaseAvailable
        ? ServiceLocator.instance.needRepository.save(need)
        : null;
    notifyListeners();
  }

  void updateShelterStatus(String shelterId, ShelterStatus status) {
    final idx = shelters.indexWhere((s) => s.id == shelterId);
    if (idx >= 0) {
      shelters[idx] = shelters[idx].copyWith(status: status, updatedBy: currentUserId);
      _refugeService?.updateStatus(
        shelterId, status, currentOrganizationId, currentUserId, currentRole.keycloakName);
      notifyListeners();
    }
  }

  void updateShelterStock(String shelterId, String item, int qty) {
    final idx = shelters.indexWhere((s) => s.id == shelterId);
    if (idx < 0) return;
    final newStock = Map<String, int>.from(shelters[idx].stock);
    newStock[item] = qty < 0 ? 0 : qty;
    shelters[idx] = shelters[idx].copyWith(stock: newStock, updatedBy: currentUserId);
    _refugeService?.updateStock(shelterId, newStock, currentOrganizationId, currentUserId, currentRole.keycloakName);
    notifyListeners();
  }

  void addShelterZone(String shelterId, String zone) {
    final idx = shelters.indexWhere((s) => s.id == shelterId);
    if (idx < 0) return;
    final newZones = List<String>.from(shelters[idx].zones);
    if (!newZones.contains(zone)) {
      newZones.add(zone);
      shelters[idx] = shelters[idx].copyWith(zones: newZones, updatedBy: currentUserId);
      _refugeService?.updateZones(shelterId, newZones, currentOrganizationId, currentUserId, currentRole.keycloakName);
      notifyListeners();
    }
  }

  void removeShelterZone(String shelterId, String zone) {
    final idx = shelters.indexWhere((s) => s.id == shelterId);
    if (idx < 0) return;
    final newZones = List<String>.from(shelters[idx].zones)..remove(zone);
    shelters[idx] = shelters[idx].copyWith(zones: newZones, updatedBy: currentUserId);
    _refugeService?.updateZones(shelterId, newZones, currentOrganizationId, currentUserId, currentRole.keycloakName);
    notifyListeners();
  }

  void updateShelterResponsable(String shelterId, {String? name, String? phone}) {
    final idx = shelters.indexWhere((s) => s.id == shelterId);
    if (idx < 0) return;
    shelters[idx] = shelters[idx].copyWith(
        responsableName: name, responsablePhone: phone, updatedBy: currentUserId);
    _refugeService?.updateResponsable(shelterId,
        name: name,
        phone: phone,
        organizationId: currentOrganizationId,
        updatedBy: currentUserId,
        updatedByRole: currentRole.keycloakName);
    notifyListeners();
  }

  void addShelterAgent(String shelterId, String agentName) {
    final idx = shelters.indexWhere((s) => s.id == shelterId);
    if (idx < 0) return;
    final newAgents = List<String>.from(shelters[idx].agentNames);
    if (!newAgents.contains(agentName)) {
      newAgents.add(agentName);
      shelters[idx] = shelters[idx].copyWith(agentNames: newAgents, updatedBy: currentUserId);
      _refugeService?.updateAgents(shelterId, newAgents, currentOrganizationId, currentUserId, currentRole.keycloakName);
      notifyListeners();
    }
  }

  void removeShelterAgent(String shelterId, String agentName) {
    final idx = shelters.indexWhere((s) => s.id == shelterId);
    if (idx < 0) return;
    final newAgents = List<String>.from(shelters[idx].agentNames)..remove(agentName);
    shelters[idx] = shelters[idx].copyWith(agentNames: newAgents, updatedBy: currentUserId);
    _refugeService?.updateAgents(shelterId, newAgents, currentOrganizationId, currentUserId, currentRole.keycloakName);
    notifyListeners();
  }

  void activateCrisis({
    required String name,
    required String type,
    required String zoneName,
  }) {
    final now = DateTime.now();
    activeEvent = activeEvent.copyWith(
      name: name,
      type: type,
      volcanoName: zoneName,
      status: EventStatus.active,
      startedAt: now,
      clearEndedAt: true,
      updatedBy: currentUserId,
    );
    for (var i = 0; i < shelters.length; i++) {
      if (shelters[i].status == ShelterStatus.preparation) {
        shelters[i] = shelters[i].copyWith(status: ShelterStatus.open);
      }
    }
    _crisisService?.activate(
      activeEvent,
      activatedBy: currentUserId,
      activatedByRole: currentRole.keycloakName,
    );
    notifyListeners();
  }

  void deactivateCrisis() {
    activeEvent = activeEvent.copyWith(
      status: EventStatus.closed,
      endedAt: DateTime.now(),
      updatedBy: currentUserId,
    );
    _crisisService?.deactivate(
      activeEvent,
      deactivatedBy: currentUserId,
      deactivatedByRole: currentRole.keycloakName,
    );
    notifyListeners();
  }

  void createFamilyCheckin({
    required List<String> personIds,
    required String familyId,
    required CheckinType type,
  }) {
    final now = DateTime.now();
    for (var i = 0; i < personIds.length; i++) {
      final personId = personIds[i];
      final checkin = CheckinModel(
        id: 'checkin_${now.millisecondsSinceEpoch}_$i',
        eventId: activeEvent.id,
        shelterId: currentShelterId,
        personId: personId,
        familyId: familyId,
        type: type,
        createdAt: now,
        createdBy: currentUserId,
      );
      _checkins.add(checkin);
      final idx = _persons.indexWhere((p) => p.id == personId);
      if (idx >= 0) {
        final person = _persons[idx];
        _persons[idx] = person.copyWith(
          status: PersonStatus.present,
          lastCheckinAt: now,
          updatedBy: currentUserId,
        );
        _personService?.createCheckin(
          person: person,
          checkin: checkin,
          newStatus: PersonStatus.present,
          updatedBy: currentUserId,
          updatedByRole: currentRole.keycloakName,
        );
      }
    }
    notifyListeners();
  }
}
