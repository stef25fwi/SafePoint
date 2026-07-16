import 'package:flutter_test/flutter_test.dart';
import 'package:safepoint_app/models/enums.dart';
import 'package:safepoint_app/models/transfer_model.dart';
import 'package:safepoint_app/services/app_state.dart';

// Un transfert de personnes doit se voir dans les données à chaque étape :
// création → les personnes passent « transfert en attente » ; départ →
// « transfert en cours » + pointage transferDeparture au centre source ;
// confirmation d'arrivée → les personnes sont réellement rattachées au
// centre destination (les effectifs des deux centres évoluent) + pointage
// transferArrival côté destination. Régression couverte : avant ce
// correctif, confirmer une arrivée ne déplaçait jamais personne.
void main() {
  group('AppState — cycle de vie du transfert de personnes', () {
    late AppState state;

    TransferModel makeTransfer(List<String> personIds) => TransferModel(
          id: 'transfer_test',
          eventId: 'event_1',
          fromShelterId: 'shelter_1',
          fromShelterName: 'Gymnase de Baie-Mahault',
          toShelterId: 'shelter_2',
          toShelterName: 'Centre de Capesterre',
          personIds: personIds,
          status: TransferStatus.pending,
          createdAt: DateTime.now(),
        );

    setUp(() {
      state = AppState();
    });

    test('addTransfer passe les personnes en « transfert en attente »', () {
      state.addTransfer(makeTransfer(['person_1']));

      final person = state.getPersonById('person_1');
      expect(person?.status, PersonStatus.transfertEnAttente);
      expect(person?.currentZone, 'Transfert en attente');
    });

    test(
        'markTransferDeparted passe les personnes en « transfert en cours » '
        'et trace un pointage transferDeparture au centre source', () {
      state.addTransfer(makeTransfer(['person_1']));

      state.markTransferDeparted('transfer_test');

      final person = state.getPersonById('person_1');
      expect(person?.status, PersonStatus.transfertEnCours);
      expect(person?.shelterId, 'shelter_1',
          reason: 'la personne ne change pas de centre avant l\'arrivée');

      final departure = state
          .getPersonCheckins('person_1')
          .where((c) => c.type == CheckinType.transferDeparture);
      expect(departure, isNotEmpty);
      expect(departure.first.shelterId, 'shelter_1');
    });

    test(
        'confirmTransferArrival déplace réellement les personnes vers le '
        'centre destination et fait évoluer les effectifs', () {
      final sourceBefore = state.occupancyOf('shelter_1');
      final destBefore = state.occupancyOf('shelter_2');

      state.addTransfer(makeTransfer(['person_1']));
      state.markTransferDeparted('transfer_test');
      state.confirmTransferArrival('transfer_test');

      final person = state.getPersonById('person_1');
      expect(person?.shelterId, 'shelter_2',
          reason: 'la personne doit être rattachée au centre destination');
      expect(person?.status, PersonStatus.present);
      expect(person?.currentZone, 'Accueil');

      expect(state.occupancyOf('shelter_1'), sourceBefore - 1,
          reason: 'l\'effectif du centre source doit diminuer');
      expect(state.occupancyOf('shelter_2'), destBefore + 1,
          reason: 'l\'effectif du centre destination doit augmenter');

      final arrival = state
          .getPersonCheckins('person_1')
          .where((c) => c.type == CheckinType.transferArrival);
      expect(arrival, isNotEmpty);
      expect(arrival.first.shelterId, 'shelter_2',
          reason: 'le pointage d\'arrivée est tracé côté destination');
    });

    test('confirmTransferArrival est idempotent (pas de double déplacement)',
        () {
      state.addTransfer(makeTransfer(['person_1']));
      state.markTransferDeparted('transfer_test');
      state.confirmTransferArrival('transfer_test');

      final checkinsAfterFirst = state.getPersonCheckins('person_1').length;
      state.confirmTransferArrival('transfer_test');

      expect(state.getPersonCheckins('person_1').length, checkinsAfterFirst,
          reason: 're-confirmer ne doit pas créer de nouveaux pointages');
    });

    test('markTransferDeparted ignore un transfert déjà parti ou confirmé', () {
      state.addTransfer(makeTransfer(['person_1']));
      state.markTransferDeparted('transfer_test');
      state.confirmTransferArrival('transfer_test');

      state.markTransferDeparted('transfer_test');

      final transfer =
          state.currentTransfers.firstWhere((t) => t.id == 'transfer_test');
      expect(transfer.status, TransferStatus.confirmed,
          reason: 'le statut ne doit pas revenir en arrière');
      expect(state.getPersonById('person_1')?.status, PersonStatus.present);
    });

    test('le transfert de plusieurs personnes les déplace toutes', () {
      state.addTransfer(makeTransfer(['person_1', 'person_2']));
      state.markTransferDeparted('transfer_test');
      state.confirmTransferArrival('transfer_test');

      expect(state.getPersonById('person_1')?.shelterId, 'shelter_2');
      expect(state.getPersonById('person_2')?.shelterId, 'shelter_2');
    });
  });
}
