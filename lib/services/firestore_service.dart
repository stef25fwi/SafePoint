// ---------------------------------------------------------------------------
// FirestoreService — DEPRECATED.
// This façade has been superseded by the repository/service layer introduced
// in V1 (migration-ready architecture).
//
// Use ServiceLocator.instance.<domainService> instead:
//   • personService     → PersonService (persons, checkins)
//   • refugeService     → RefugeService (shelters)
//   • alertService      → AlertService  (alerts)
//   • transferService   → TransferService (transfers)
//   • familyRepository  → FamilyRepository (families)
//   • needRepository    → NeedRepository   (needs)
//
// This file is retained only to avoid breaking any import that hasn't been
// migrated yet. All methods now throw UnimplementedError to surface usages.
// Remove this file once all call sites have been updated.
// ---------------------------------------------------------------------------

@Deprecated('Use ServiceLocator domain services instead')
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();
}
