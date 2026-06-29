import 'package:firebase_core/firebase_core.dart';

import 'environment.dart';

// Repositories abstraits
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/person_repository.dart';
import '../domain/repositories/refuge_repository.dart';
import '../domain/repositories/checkin_repository.dart';
import '../domain/repositories/transfer_repository.dart';
import '../domain/repositories/alert_repository.dart';
import '../domain/repositories/audit_repository.dart';
import '../domain/repositories/crisis_event_repository.dart';
import '../domain/repositories/family_repository.dart';
import '../domain/repositories/need_repository.dart';
import '../domain/repositories/file_repository.dart';

// Firebase implementations (V1)
import '../infrastructure/firebase/firebase_auth_repository.dart';
import '../infrastructure/firebase/firebase_person_repository.dart';
import '../infrastructure/firebase/firebase_refuge_repository.dart';
import '../infrastructure/firebase/firebase_checkin_repository.dart';
import '../infrastructure/firebase/firebase_transfer_repository.dart';
import '../infrastructure/firebase/firebase_alert_repository.dart';
import '../infrastructure/firebase/firebase_audit_repository.dart';
import '../infrastructure/firebase/firebase_crisis_event_repository.dart';
import '../infrastructure/firebase/firebase_family_repository.dart';
import '../infrastructure/firebase/firebase_need_repository.dart';
import '../infrastructure/firebase/firebase_file_repository.dart';

// API implementations (V2 placeholders)
import '../infrastructure/api/api_client.dart';
import '../infrastructure/api/api_auth_repository.dart';
import '../infrastructure/api/api_person_repository.dart';
import '../infrastructure/api/api_refuge_repository.dart';
import '../infrastructure/api/api_checkin_repository.dart';
import '../infrastructure/api/api_transfer_repository.dart';
import '../infrastructure/api/api_alert_repository.dart';
import '../infrastructure/api/api_audit_repository.dart';

// Domain services
import '../domain/services/audit_service.dart';
import '../domain/services/auth_service.dart';
import '../domain/services/person_service.dart';
import '../domain/services/refuge_service.dart';
import '../domain/services/alert_service.dart';
import '../domain/services/transfer_service.dart';
import '../domain/services/crisis_event_service.dart';
import '../domain/services/file_service.dart';

import '../core/constants/app_constants.dart';

// ---------------------------------------------------------------------------
// ServiceLocator — point d'injection unique.
//
// En V1 : Environment.useFirebase == true → Firebase implementations.
// En V2 : flip Environment.useApiBackend = true et configurez ApiClient
//          → les repositories basculent automatiquement vers l'API REST.
// ---------------------------------------------------------------------------
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;

  // Firebase available flag
  bool _firebaseAvailable = false;

  // Repositories
  late AuthRepository _authRepository;
  late PersonRepository _personRepository;
  late RefugeRepository _refugeRepository;
  late CheckinRepository _checkinRepository;
  late TransferRepository _transferRepository;
  late AlertRepository _alertRepository;
  late AuditRepository _auditRepository;
  late CrisisEventRepository _crisisEventRepository;
  late FamilyRepository _familyRepository;
  late NeedRepository _needRepository;
  late FileRepository _fileRepository;

  // Domain services
  late AuditService _auditService;
  late AuthDomainService _authService;
  late PersonService _personService;
  late RefugeService _refugeService;
  late AlertService _alertService;
  late TransferService _transferService;
  late CrisisEventService _crisisEventService;
  late FileService _fileService;

  // ---------------------------------------------------------------------------
  // Initialisation — appelée depuis main.dart après Firebase.initializeApp
  // ---------------------------------------------------------------------------
  void initialize({bool firebaseAvailable = false}) {
    _firebaseAvailable = firebaseAvailable;

    if (Environment.useApiBackend) {
      _initApiImplementations();
    } else if (_firebaseAvailable) {
      _initFirebaseImplementations();
    } else {
      // Mode démo sans Firebase : les repositories Firebase ne seront pas utilisés
      // Les pages utilisent les données mock de AppState directement
      _initFirebaseImplementations(); // Constructeurs sans appels Firestore
    }

    _initDomainServices();
  }

  void _initFirebaseImplementations() {
    _authRepository = FirebaseAuthRepository();
    _personRepository = FirebasePersonRepository();
    _refugeRepository = FirebaseRefugeRepository();
    _checkinRepository = FirebaseCheckinRepository();
    _transferRepository = FirebaseTransferRepository();
    _alertRepository = FirebaseAlertRepository();
    _auditRepository = FirebaseAuditRepository();
    _crisisEventRepository = FirebaseCrisisEventRepository();
    _familyRepository = FirebaseFamilyRepository();
    _needRepository = FirebaseNeedRepository();
    _fileRepository = FirebaseFileRepository();
  }

  void _initApiImplementations() {
    // V2 : configurer baseUrl depuis variables d'environnement sécurisées
    const client = ApiClient(
      baseUrl: 'https://api.safepoint.guadeloupe.fr', // V2 Cloud Temple
      organizationId: AppDefaults.organizationId,
    );
    _authRepository = ApiAuthRepository(client);
    _personRepository = ApiPersonRepository(client);
    _refugeRepository = ApiRefugeRepository(client);
    _checkinRepository = ApiCheckinRepository(client);
    _transferRepository = ApiTransferRepository(client);
    _alertRepository = ApiAlertRepository(client);
    _auditRepository = ApiAuditRepository(client);
    // Ces trois n'ont pas encore de placeholder API complet
    _crisisEventRepository = FirebaseCrisisEventRepository();
    _familyRepository = FirebaseFamilyRepository();
    _needRepository = FirebaseNeedRepository();
  }

  void _initDomainServices() {
    _auditService = AuditService(_auditRepository);
    _authService = AuthDomainService(_authRepository, _auditService);
    _personService = PersonService(_personRepository, _checkinRepository, _auditService);
    _refugeService = RefugeService(_refugeRepository, _auditService);
    _alertService = AlertService(_alertRepository, _auditService);
    _transferService = TransferService(_transferRepository, _auditService);
    _crisisEventService = CrisisEventService(_crisisEventRepository, _auditService);
    _fileService = FileService(_fileRepository, _auditService);
  }

  // ---------------------------------------------------------------------------
  // Accesseurs publics
  // ---------------------------------------------------------------------------
  bool get firebaseAvailable => _firebaseAvailable;

  AuditService get auditService => _auditService;
  AuthDomainService get authService => _authService;
  PersonService get personService => _personService;
  RefugeService get refugeService => _refugeService;
  AlertService get alertService => _alertService;
  TransferService get transferService => _transferService;
  CrisisEventService get crisisEventService => _crisisEventService;
  FileService get fileService => _fileService;

  // Repositories directs (pour cas spéciaux)
  FamilyRepository get familyRepository => _familyRepository;
  NeedRepository get needRepository => _needRepository;
  FileRepository get fileRepository => _fileRepository;
}

// Vérifie si Firebase est disponible
bool isFirebaseAvailable() {
  try {
    Firebase.app();
    return true;
  } catch (_) {
    return false;
  }
}
