import 'package:flutter_test/flutter_test.dart';
import 'package:safepoint_app/models/enums.dart';
import 'package:safepoint_app/services/app_state.dart';

// Le pointage doit rester fiable même en cas de double scan : un pointage
// en double n'est jamais rejeté (mieux vaut un doublon qu'un pointage
// manquant en situation de crise) mais il est signalé à l'agent. Les
// statistiques du jour doivent toujours refléter la liste réelle des
// pointages, jamais un compteur dénormalisé qui pourrait dériver.
void main() {
  group('AppState — pointage (types, doublons, statistiques du jour)', () {
    late AppState state;

    setUp(() {
      state = AppState();
    });

    test('createCheckin ne signale aucun doublon pour un premier pointage', () {
      final result = state.createCheckin(
        personId: 'person_1',
        type: CheckinType.douche,
      );
      expect(result.duplicateMinutes, isNull);
      expect(result.checkin.type, CheckinType.douche);
    });

    test(
        'createCheckin signale un doublon quand le même type est repointé '
        'moins de 2h après pour la même personne', () {
      state.createCheckin(personId: 'person_1', type: CheckinType.activite);
      final second = state.createCheckin(
        personId: 'person_1',
        type: CheckinType.activite,
      );
      expect(second.duplicateMinutes, isNotNull);
      expect(second.duplicateMinutes, lessThan(120));
    });

    test('createCheckin ne signale pas de doublon pour un type différent', () {
      state.createCheckin(personId: 'person_1', type: CheckinType.douche);
      final result = state.createCheckin(
        personId: 'person_1',
        type: CheckinType.activite,
      );
      expect(result.duplicateMinutes, isNull);
    });

    test(
        'createCheckin ne signale pas de doublon entre deux personnes différentes',
        () {
      state.createCheckin(personId: 'person_1', type: CheckinType.douche);
      final result = state.createCheckin(
        personId: 'person_2',
        type: CheckinType.douche,
      );
      expect(result.duplicateMinutes, isNull);
    });

    test('douche et activite font passer la personne en présent', () {
      final result = state.createCheckin(
        personId: 'person_1',
        type: CheckinType.douche,
      );
      final person = state.getPersonById('person_1');
      expect(person?.status, PersonStatus.present);
      expect(result.checkin.personId, 'person_1');
    });

    test('todayCheckinCounts regroupe les 3 types de repas sous "repas"', () {
      final before = state.todayCheckinCounts('shelter_1')['repas']!;
      state.createCheckin(
          personId: 'person_1', type: CheckinType.mealBreakfast);
      state.createCheckin(personId: 'person_2', type: CheckinType.mealLunch);
      state.createCheckin(personId: 'person_4', type: CheckinType.mealDinner);

      expect(state.todayCheckinCounts('shelter_1')['repas'], before + 3);
    });

    test('todayCheckinCounts compte séparément soins, douche et activité', () {
      final beforeSoins = state.todayCheckinCounts('shelter_1')['soins']!;
      final beforeDouche = state.todayCheckinCounts('shelter_1')['douche']!;
      final beforeActivite = state.todayCheckinCounts('shelter_1')['activite']!;

      state.createCheckin(personId: 'person_1', type: CheckinType.medical);
      state.createCheckin(personId: 'person_2', type: CheckinType.douche);
      state.createCheckin(personId: 'person_4', type: CheckinType.activite);

      final counts = state.todayCheckinCounts('shelter_1');
      expect(counts['soins'], beforeSoins + 1);
      expect(counts['douche'], beforeDouche + 1);
      expect(counts['activite'], beforeActivite + 1);
    });

    test('todayCheckinCounts utilise le centre courant par défaut', () {
      expect(
        state.todayCheckinCounts(),
        state.todayCheckinCounts(state.currentShelterId),
      );
    });

    test(
        'todayCheckinCounts renvoie des compteurs à zéro pour un centre sans pointage',
        () {
      final counts = state.todayCheckinCounts('shelter_inexistant');
      expect(counts['repas'], 0);
      expect(counts['soins'], 0);
      expect(counts['douche'], 0);
      expect(counts['activite'], 0);
    });
  });
}
