import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/emergency_event_model.dart';
import '../models/shelter_model.dart';
import '../models/person_model.dart';
import '../models/family_model.dart';
import '../models/checkin_model.dart';
import '../models/alert_model.dart';
import '../models/transfer_model.dart';
import '../models/need_model.dart';
import '../models/enums.dart';
import 'firestore_service.dart';

class AppState extends ChangeNotifier {
  // Auth
  bool isLoggedIn = false;
  String currentAgentCode = '';
  String currentShelterId = 'shelter_1';
  UserRole currentRole = UserRole.responsableCentre;
  bool isOffline = false;

  // Firestore disponible si Firebase est initialisé
  bool get _firestoreEnabled {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  FirestoreService get _fs => FirestoreService.instance;

  // --- Mock Data ---
  final EmergencyEventModel activeEvent = EmergencyEventModel(
    id: 'event_1',
    name: 'Éruption volcanique – Soufrière',
    type: 'eruption',
    status: EventStatus.active,
    volcanoName: 'Soufrière',
    startedAt: DateTime.now().subtract(const Duration(hours: 6)),
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
        'Zone A – Accueil',
        'Zone B – Soins',
        'Zone C – Hébergement'
      ],
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
      zones: ['Salle A', 'Salle B', 'Espace familles', 'Zone médicale'],
    ),
    const ShelterModel(
      id: 'shelter_3',
      eventId: 'event_1',
      name: 'Salle de Basse-Terre',
      commune: 'Basse-Terre',
      address: 'Place du Champ d\'Arbaud, Basse-Terre',
      capacity: 400,
      currentCount: 242,
      status: ShelterStatus.open,
      zones: ['Hall principal', 'Annexe A', 'Zone PMR', 'Espace enfants'],
    ),
  ];

  late List<PersonModel> _persons;
  late List<FamilyModel> _families;
  late List<CheckinModel> _checkins;
  late List<AlertModel> _alerts;
  late List<TransferModel> _transfers;
  late List<NeedModel> _needs;

  AppState() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    _persons = [
      PersonModel(
        id: 'person_1',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        familyId: null,
        qrCode: 'rv://event/event_1/person/person_1/token/abc123',
        firstName: 'Marie',
        lastName: 'JEAN-BAPTISTE',
        ageApprox: 42,
        originCommune: 'Saint-Claude',
        phone: '0690 12 34 56',
        currentZone: 'Dortoir A',
        status: PersonStatus.present,
        vulnerabilityFlags: [],
        needFlags: [],
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
        vulnerabilityFlags: ['enfant'],
        needFlags: [],
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
        vulnerabilityFlags: ['personne_agee', 'pmr'],
        needFlags: [NeedType.medical],
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
        vulnerabilityFlags: [],
        needFlags: [],
        createdAt: now.subtract(const Duration(hours: 3)),
        lastCheckinAt: now.subtract(const Duration(hours: 2)),
      ),
      PersonModel(
        id: 'person_5',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        familyId: null,
        qrCode: 'rv://event/event_1/person/person_5/token/mno345',
        firstName: 'Sophie',
        lastName: 'LUREL',
        ageApprox: 28,
        originCommune: 'Trois-Rivières',
        phone: '0690 23 45 67',
        currentZone: 'Dortoir B',
        status: PersonStatus.present,
        vulnerabilityFlags: [],
        needFlags: [],
        createdAt: now.subtract(const Duration(hours: 4, minutes: 15)),
        lastCheckinAt: now.subtract(const Duration(minutes: 20)),
      ),
      PersonModel(
        id: 'person_6',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        familyId: null,
        qrCode: 'rv://event/event_1/person/person_6/token/pqr678',
        firstName: 'Alain',
        lastName: 'NESTOR',
        ageApprox: 63,
        originCommune: 'Gourbeyre',
        currentZone: 'Dortoir C',
        status: PersonStatus.nonPointee,
        vulnerabilityFlags: ['personne_agee'],
        needFlags: [],
        createdAt: now.subtract(const Duration(hours: 6)),
        lastCheckinAt: null,
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
        vulnerabilityFlags: [],
        needFlags: [],
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
        vulnerabilityFlags: [],
        needFlags: [],
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
        memberIds: ['person_2', 'person_7', 'person_8'],
        membersCount: 4,
        assignedZone: 'A1',
        isSeparated: false,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      FamilyModel(
        id: 'family_2',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        displayName: 'Famille PIERRE',
        originCommune: 'Capesterre-Belle-Eau',
        memberIds: ['person_4'],
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
        memberIds: [],
        membersCount: 3,
        assignedZone: 'C1',
        isSeparated: false,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      FamilyModel(
        id: 'family_4',
        eventId: 'event_1',
        shelterId: 'shelter_1',
        displayName: 'Famille FÉLIX',
        originCommune: 'Saint-Claude',
        memberIds: ['person_3'],
        membersCount: 2,
        assignedZone: 'D2',
        isSeparated: false,
        hasChildrenAlone: false,
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
        description: 'Un enfant de 8 ans est sans accompagnateur connu.',
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
        description:
            'Femme enceinte signalant des douleurs et besoin de suivi.',
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
        personIds: ['person_4'],
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
        personIds: ['person_3'],
        familyName: null,
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

  // Getters
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

  List<CheckinModel> getPersonCheckins(String personId) {
    return _checkins.where((c) => c.personId == personId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<AlertModel> getPersonAlerts(String personId) {
    return _alerts.where((a) => a.personId == personId).toList();
  }

  List<NeedModel> getPersonNeeds(String personId) {
    return _needs
        .where((n) => n.personId == personId && n.status == 'open')
        .toList();
  }

  List<PersonModel> getFamilyMembers(String familyId) {
    return _persons
        .where((p) => p.familyId == familyId && !p.isDeleted)
        .toList();
  }

  // Counts per shelter for reports
  Map<String, int> get countsByShelterId {
    final map = <String, int>{};
    for (final s in shelters) {
      map[s.id] =
          _persons.where((p) => p.shelterId == s.id && !p.isDeleted).length;
    }
    return map;
  }

  // Actions
  void login(String agentCode, String shelterId, {bool offline = false}) {
    isLoggedIn = true;
    currentAgentCode = agentCode;
    currentShelterId = shelterId;
    isOffline = offline;
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    currentAgentCode = '';
    isOffline = false;
    notifyListeners();
  }

  void addPerson(PersonModel person) {
    _persons.add(person);
    final arrivalCheckin = CheckinModel(
      id: 'checkin_${DateTime.now().millisecondsSinceEpoch}',
      eventId: 'event_1',
      shelterId: currentShelterId,
      personId: person.id,
      type: CheckinType.arrival,
      createdAt: DateTime.now(),
    );
    _checkins.add(arrivalCheckin);
    if (_firestoreEnabled) {
      _fs.savePerson(person);
      _fs.saveCheckin(arrivalCheckin);
    }
    notifyListeners();
  }

  void createCheckin(
      {required String personId, required CheckinType type, String? notes}) {
    final checkin = CheckinModel(
      id: 'checkin_${DateTime.now().millisecondsSinceEpoch}',
      eventId: 'event_1',
      shelterId: currentShelterId,
      personId: personId,
      type: type,
      createdAt: DateTime.now(),
      notes: notes,
    );
    _checkins.add(checkin);

    // Update person status
    final idx = _persons.indexWhere((p) => p.id == personId);
    PersonStatus? newStatus;
    if (idx >= 0) {
      if (type == CheckinType.exitFinal) {
        newStatus = PersonStatus.sortieDefinitive;
      } else if (type == CheckinType.exitTemporary) {
        newStatus = PersonStatus.sortieTemporaire;
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
        lastCheckinAt: DateTime.now(),
      );
    }
    if (_firestoreEnabled) {
      _fs.saveCheckin(checkin);
      if (newStatus != null) {
        _fs.updatePersonStatus(personId, newStatus, DateTime.now());
      }
    }
    notifyListeners();
  }

  void resolveAlert(String alertId) {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx >= 0) {
      final resolved = DateTime.now();
      _alerts[idx] = _alerts[idx].copyWith(
        status: AlertStatus.resolved,
        resolvedAt: resolved,
      );
      if (_firestoreEnabled) {
        _fs.updateAlertStatus(alertId, AlertStatus.resolved, resolvedAt: resolved);
      }
    }
    notifyListeners();
  }

  void markAlertInProgress(String alertId) {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx >= 0) {
      _alerts[idx] = _alerts[idx].copyWith(status: AlertStatus.inProgress);
      if (_firestoreEnabled) {
        _fs.updateAlertStatus(alertId, AlertStatus.inProgress);
      }
    }
    notifyListeners();
  }

  void confirmTransferArrival(String transferId) {
    final idx = _transfers.indexWhere((t) => t.id == transferId);
    if (idx >= 0) {
      final now = DateTime.now();
      _transfers[idx] = _transfers[idx].copyWith(
        status: TransferStatus.confirmed,
        arrivalConfirmedAt: now,
      );
      if (_firestoreEnabled) {
        _fs.updateTransferStatus(
          transferId,
          TransferStatus.confirmed,
          arrivalConfirmedAt: now,
        );
      }
    }
    notifyListeners();
  }

  void markTransferDeparted(String transferId) {
    final idx = _transfers.indexWhere((t) => t.id == transferId);
    if (idx >= 0) {
      final now = DateTime.now();
      _transfers[idx] = _transfers[idx].copyWith(
        status: TransferStatus.inProgress,
        departedAt: now,
      );
      if (_firestoreEnabled) {
        _fs.updateTransferStatus(
          transferId,
          TransferStatus.inProgress,
          departedAt: now,
        );
      }
    }
    notifyListeners();
  }

  void addTransfer(TransferModel transfer) {
    _transfers.add(transfer);
    if (_firestoreEnabled) {
      _fs.saveTransfer(transfer);
    }
    notifyListeners();
  }

  void markFamilySeparated(String familyId, bool separated) {
    final idx = _families.indexWhere((f) => f.id == familyId);
    if (idx >= 0) {
      _families[idx] = _families[idx].copyWith(isSeparated: separated);
      if (_firestoreEnabled) {
        _fs.updateFamilySeparated(familyId, separated);
      }
    }
    notifyListeners();
  }

  void addNeed(NeedModel need) {
    _needs.add(need);
    if (_firestoreEnabled) {
      _fs.saveNeed(need);
    }
    notifyListeners();
  }
}
