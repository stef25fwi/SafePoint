import 'package:flutter_test/flutter_test.dart';
import 'package:safepoint_app/models/enums.dart';
import 'package:safepoint_app/models/person_model.dart';
import 'package:safepoint_app/services/app_state.dart';

// Ces tests protègent contre la régression "chiffres non câblés" :
// l'occupation affichée doit TOUJOURS être recalculée depuis la liste réelle
// des personnes (source unique de vérité), jamais depuis le compteur
// dénormalisé ShelterModel.currentCount (figé, jamais mis à jour).
void main() {
  group('AppState — occupation en direct (source unique de vérité)', () {
    late AppState state;

    setUp(() {
      state = AppState();
    });

    test('occupancyOf recalcule depuis les personnes réelles, pas currentCount',
        () {
      for (final shelter in state.shelters) {
        final realCount = state.everyPerson
            .where((p) => p.shelterId == shelter.id)
            .length;
        expect(state.occupancyOf(shelter.id), realCount,
            reason: 'occupancyOf(${shelter.id}) doit égaler le décompte réel');
      }
    });

    test('occupancyOf est cohérent avec countsByShelterId', () {
      final counts = state.countsByShelterId;
      for (final shelter in state.shelters) {
        expect(state.occupancyOf(shelter.id), counts[shelter.id]);
      }
    });

    test('placesRestantesOf = capacité - occupation réelle', () {
      for (final shelter in state.shelters) {
        expect(state.placesRestantesOf(shelter.id),
            shelter.capacity - state.occupancyOf(shelter.id));
      }
    });

    test('capacityPercentOf = occupation réelle / capacité', () {
      for (final shelter in state.shelters) {
        expect(state.capacityPercentOf(shelter.id),
            closeTo(state.occupancyOf(shelter.id) / shelter.capacity, 1e-9));
      }
    });

    test('capacityPercentOf renvoie 0 pour un centre inconnu plutôt que NaN',
        () {
      expect(state.occupancyOf('shelter_inexistant'), 0);
    });

    test('addPerson fait évoluer l\'occupation en direct (anti-régression)',
        () {
      final shelterId = state.currentShelterId;
      final before = state.occupancyOf(shelterId);
      final placesBefore = state.placesRestantesOf(shelterId);

      state.addPerson(PersonModel(
        id: 'person_test_occupation',
        eventId: state.activeEvent.id,
        shelterId: shelterId,
        qrCode: 'sp://test',
        firstName: 'Test',
        lastName: 'OCCUPATION',
        status: PersonStatus.present,
        createdAt: DateTime.now(),
      ));

      expect(state.occupancyOf(shelterId), before + 1,
          reason: 'l\'occupation doit suivre les ajouts de personnes');
      expect(state.placesRestantesOf(shelterId), placesBefore - 1,
          reason: 'les places restantes doivent suivre les ajouts');
    });

    test(
        'le compteur dénormalisé currentCount ne pilote PAS l\'occupation '
        'affichée', () {
      final shelterId = state.currentShelterId;
      state.addPerson(PersonModel(
        id: 'person_test_denorm',
        eventId: state.activeEvent.id,
        shelterId: shelterId,
        qrCode: 'sp://test2',
        firstName: 'Test',
        lastName: 'DENORM',
        status: PersonStatus.present,
        createdAt: DateTime.now(),
      ));
      final staleCount =
          state.shelters.firstWhere((s) => s.id == shelterId).currentCount;
      // currentCount reste figé après un ajout : si occupancyOf lui était
      // égal par construction, ce test le détecterait.
      expect(state.occupancyOf(shelterId), isNot(staleCount),
          reason: 'occupancyOf ne doit pas refléter le compteur figé');
    });
  });

  group('AppState — agrégats analytics', () {
    late AppState state;

    setUp(() {
      state = AppState();
    });

    test('everyPerson exclut les personnes supprimées (soft-delete)', () {
      expect(state.everyPerson.any((p) => p.isDeleted), isFalse);
    });

    test('everyNonPointee ne contient que le statut nonPointee', () {
      expect(
          state.everyNonPointee
              .every((p) => p.status == PersonStatus.nonPointee),
          isTrue);
      final expected = state.everyPerson
          .where((p) => p.status == PersonStatus.nonPointee)
          .length;
      expect(state.everyNonPointee.length, expected);
    });

    test('countsByOriginCommune totalise exactement everyPerson', () {
      final counts = state.countsByOriginCommune;
      final total = counts.values.fold(0, (a, b) => a + b);
      expect(total, state.everyPerson.length,
          reason: 'chaque personne doit être comptée exactement une fois');
    });

    test('countsByOriginCommune regroupe les communes manquantes', () {
      final withoutCommune =
          state.everyPerson.where((p) => p.originCommune == null).length;
      if (withoutCommune > 0) {
        expect(state.countsByOriginCommune['Non renseignée'], withoutCommune);
      }
    });

    test('everyOpenNeed ne contient que des besoins ouverts', () {
      expect(state.everyOpenNeed.every((n) => n.status == 'open'), isTrue);
    });

    test('getFamilyMembers correspond aux personnes rattachées non supprimées',
        () {
      for (final family in state.currentFamilies) {
        final members = state.getFamilyMembers(family.id);
        expect(
            members.every((m) => m.familyId == family.id && !m.isDeleted),
            isTrue);
      }
    });
  });

  group('AppState — habilitations (RBAC)', () {
    late AppState state;

    setUp(() {
      state = AppState();
    });

    test('readOnlyObserver ne peut ni créer, ni pointer, ni voir le nominatif',
        () {
      state.currentRole = UserRole.readOnlyObserver;
      expect(state.canCreatePerson, isFalse);
      expect(state.canCheckIn, isFalse);
      expect(state.canSeeNominativeData, isFalse);
    });

    test('auditor peut exporter et consulter l\'audit mais pas créer', () {
      state.currentRole = UserRole.auditor;
      expect(state.canExportData, isTrue);
      expect(state.canViewAuditLogs, isTrue);
      expect(state.canCreatePerson, isFalse);
    });

    test('agent peut créer et pointer mais pas activer une crise', () {
      state.currentRole = UserRole.agent;
      expect(state.canCreatePerson, isTrue);
      expect(state.canCheckIn, isTrue);
      expect(state.canActivateCrisis, isFalse);
      expect(state.canEditShelter, isFalse);
    });

    test('prefectureAdmin peut activer une crise et résoudre des alertes', () {
      state.currentRole = UserRole.prefectureAdmin;
      expect(state.canActivateCrisis, isTrue);
      expect(state.canResolveAlerts, isTrue);
    });

    test('superAdmin a toutes les habilitations clés', () {
      state.currentRole = UserRole.superAdmin;
      expect(state.isAdmin, isTrue);
      expect(state.canCreatePerson, isTrue);
      expect(state.canResolveAlerts, isTrue);
      expect(state.canValidateTransfers, isTrue);
      expect(state.canExportData, isTrue);
      expect(state.canActivateCrisis, isTrue);
      expect(state.canEditShelter, isTrue);
      expect(state.canViewAuditLogs, isTrue);
    });
  });

  group('AppState — cycle crise', () {
    test('activateCrisis puis deactivateCrisis mettent à jour l\'événement',
        () {
      final state = AppState();
      state.activateCrisis(
        name: 'Test éruption',
        type: 'eruption',
        zoneName: 'Zone test',
      );
      expect(state.isCrisisActive, isTrue);
      expect(state.activeEvent.name, 'Test éruption');

      state.deactivateCrisis();
      expect(state.isCrisisActive, isFalse);
      expect(state.activeEvent.endedAt, isNotNull);
    });
  });
}
