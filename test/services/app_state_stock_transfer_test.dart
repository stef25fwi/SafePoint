import 'package:flutter_test/flutter_test.dart';
import 'package:safepoint_app/models/enums.dart';
import 'package:safepoint_app/services/app_state.dart';

// Un transfert de stock déplace une quantité tracée entre deux centres :
// à la création, le centre source est décrémenté (via une entrée de
// mouvement négative) ; à la confirmation, le centre destination est
// incrémenté ; en cas d'annulation avant confirmation, le centre source
// est restitué. L'agrégat par catégorie (utilisé par les seuils/alertes)
// doit rester cohérent à chaque étape.
void main() {
  group('AppState — transferts de stock (suivi du nombre de produits)', () {
    late AppState state;

    setUp(() {
      state = AppState();
    });

    test('stockTransfersOf renvoie les transferts au départ ou à l\'arrivée',
        () {
      final atSource = state.stockTransfersOf('shelter_1');
      final atDest = state.stockTransfersOf('shelter_2');
      expect(atSource, isNotEmpty);
      expect(atDest, isNotEmpty);
      expect(
        atSource.every((t) =>
            t.fromShelterId == 'shelter_1' || t.toShelterId == 'shelter_1'),
        isTrue,
      );
    });

    test(
        'addStockTransfer décrémente immédiatement l\'agrégat du centre source',
        () {
      final before = state.stockQuantityOf('shelter_1', 'eau');
      final destBefore = state.stockQuantityOf('shelter_2', 'eau');

      state.addStockTransfer(
        fromShelterId: 'shelter_1',
        fromShelterName: 'Gymnase de Baie-Mahault',
        toShelterId: 'shelter_2',
        toShelterName: 'Centre de Capesterre',
        category: 'eau',
        label: 'Palettes eau',
        quantity: 100,
        unit: 'bouteilles',
      );

      expect(state.stockQuantityOf('shelter_1', 'eau'), before - 100);
      // Rien n'arrive côté destination avant confirmation de réception.
      expect(state.stockQuantityOf('shelter_2', 'eau'), destBefore);

      final transfer = state.stockTransfersOf('shelter_1').first;
      expect(transfer.status, TransferStatus.pending);
      expect(transfer.quantity, 100);
      expect(transfer.outEntryId, isNotNull);

      final shelter1 = state.shelters.firstWhere((s) => s.id == 'shelter_1');
      expect(shelter1.stock['eau'], state.stockQuantityOf('shelter_1', 'eau'),
          reason:
              'l\'agrégat affiché doit rester aligné sur la somme des entrées');
    });

    test(
        'markStockTransferDeparted passe le statut en transit sans bouger le stock',
        () {
      state.addStockTransfer(
        fromShelterId: 'shelter_1',
        fromShelterName: 'Gymnase de Baie-Mahault',
        toShelterId: 'shelter_2',
        toShelterName: 'Centre de Capesterre',
        category: 'repas',
        label: 'Rations',
        quantity: 30,
        unit: 'portions',
      );
      final transfer = state.stockTransfersOf('shelter_1').first;
      final qtyAfterCreate = state.stockQuantityOf('shelter_1', 'repas');

      state.markStockTransferDeparted(transfer.id);

      final updated = state
          .stockTransfersOf('shelter_1')
          .firstWhere((t) => t.id == transfer.id);
      expect(updated.status, TransferStatus.inProgress);
      expect(updated.departedAt, isNotNull);
      expect(state.stockQuantityOf('shelter_1', 'repas'), qtyAfterCreate);
    });

    test('confirmStockTransferArrival ajoute la quantité au centre destination',
        () {
      state.addStockTransfer(
        fromShelterId: 'shelter_1',
        fromShelterName: 'Gymnase de Baie-Mahault',
        toShelterId: 'shelter_2',
        toShelterName: 'Centre de Capesterre',
        category: 'masques',
        label: 'Boîtes masques',
        quantity: 50,
        unit: 'unités',
      );
      final transfer = state.stockTransfersOf('shelter_1').first;
      final destBefore = state.stockQuantityOf('shelter_2', 'masques');

      state.confirmStockTransferArrival(transfer.id);

      expect(state.stockQuantityOf('shelter_2', 'masques'), destBefore + 50);
      final updated = state
          .stockTransfersOf('shelter_2')
          .firstWhere((t) => t.id == transfer.id);
      expect(updated.status, TransferStatus.confirmed);
      expect(updated.confirmedAt, isNotNull);
      expect(updated.inEntryId, isNotNull);

      final destEntry = state
          .stockEntriesOf('shelter_2')
          .firstWhere((e) => e.id == updated.inEntryId);
      expect(destEntry.provenance, contains('Gymnase de Baie-Mahault'));
      expect(destEntry.quantity, 50);
    });

    test('cancelStockTransfer restitue la quantité au centre source', () {
      state.addStockTransfer(
        fromShelterId: 'shelter_1',
        fromShelterName: 'Gymnase de Baie-Mahault',
        toShelterId: 'shelter_2',
        toShelterName: 'Centre de Capesterre',
        category: 'couches',
        label: 'Paquets de couches',
        quantity: 15,
        unit: 'unités',
      );
      final transfer = state.stockTransfersOf('shelter_1').first;
      final qtyAfterCreate = state.stockQuantityOf('shelter_1', 'couches');

      state.cancelStockTransfer(transfer.id);

      expect(
          state.stockQuantityOf('shelter_1', 'couches'), qtyAfterCreate + 15);
      final updated = state
          .stockTransfersOf('shelter_1')
          .firstWhere((t) => t.id == transfer.id);
      expect(updated.status, TransferStatus.cancelled);
    });

    test('cancelStockTransfer est un no-op une fois le transfert confirmé', () {
      state.addStockTransfer(
        fromShelterId: 'shelter_1',
        fromShelterName: 'Gymnase de Baie-Mahault',
        toShelterId: 'shelter_2',
        toShelterName: 'Centre de Capesterre',
        category: 'medicaments',
        label: 'Kits médicaments',
        quantity: 3,
        unit: 'kits',
      );
      final transfer = state.stockTransfersOf('shelter_1').first;
      state.confirmStockTransferArrival(transfer.id);
      final qtyAfterConfirm = state.stockQuantityOf('shelter_1', 'medicaments');

      state.cancelStockTransfer(transfer.id);

      expect(state.stockQuantityOf('shelter_1', 'medicaments'), qtyAfterConfirm,
          reason:
              'un transfert déjà confirmé ne doit plus pouvoir être annulé');
      final updated = state
          .stockTransfersOf('shelter_1')
          .firstWhere((t) => t.id == transfer.id);
      expect(updated.status, TransferStatus.confirmed);
    });
  });
}
