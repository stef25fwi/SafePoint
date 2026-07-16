import 'package:flutter_test/flutter_test.dart';
import 'package:safepoint_app/models/stock_entry_model.dart';
import 'package:safepoint_app/services/app_state.dart';

// Traçabilité du stock : les entrées (lots) sont la source de vérité fine et
// l'agrégat par catégorie (ShelterModel.stock, qui pilote seuils/alertes) doit
// TOUJOURS rester égal à la somme des entrées de la même catégorie.
void main() {
  group('AppState — entrées de stock (traçabilité)', () {
    late AppState state;

    setUp(() {
      state = AppState();
    });

    test('stockEntriesOf renvoie les entrées du centre triées par date desc',
        () {
      final entries = state.stockEntriesOf('shelter_1');
      expect(entries, isNotEmpty);
      expect(entries.every((e) => e.refugeId == 'shelter_1'), isTrue);
      for (var i = 0; i < entries.length - 1; i++) {
        expect(
          entries[i].dateEntree.isBefore(entries[i + 1].dateEntree),
          isFalse,
          reason:
              'les entrées doivent être triées du plus récent au plus ancien',
        );
      }
    });

    test('stockQuantityOf somme les quantités par catégorie', () {
      final expected = state
          .stockEntriesOf('shelter_1')
          .where((e) => e.category == 'eau')
          .fold<int>(0, (s, e) => s + e.quantity);
      expect(state.stockQuantityOf('shelter_1', 'eau'), expected);
    });

    test('stockQuantityOf renvoie 0 pour une catégorie absente', () {
      expect(state.stockQuantityOf('shelter_1', 'categorie_inexistante'), 0);
    });

    test('addStockEntry ajoute le lot et aligne l\'agrégat sur la somme', () {
      final before = state.stockQuantityOf('shelter_1', 'eau');
      final countBefore = state.stockEntriesOf('shelter_1').length;

      state.addStockEntry(StockEntryModel(
        id: 'test_add_1',
        refugeId: 'shelter_1',
        category: 'eau',
        label: 'Renfort eau',
        quantity: 120,
        dateEntree: DateTime(2026, 7, 15),
      ));

      expect(state.stockEntriesOf('shelter_1').length, countBefore + 1);
      expect(state.stockQuantityOf('shelter_1', 'eau'), before + 120);

      // L'agrégat qui pilote les alertes suit la somme des entrées.
      final shelter = state.shelters.firstWhere((s) => s.id == 'shelter_1');
      expect(shelter.stock['eau'], state.stockQuantityOf('shelter_1', 'eau'));
    });

    test('removeStockEntry retire le lot et réajuste l\'agrégat', () {
      state.addStockEntry(StockEntryModel(
        id: 'test_rm_1',
        refugeId: 'shelter_1',
        category: 'masques',
        label: 'Boîtes masques',
        quantity: 200,
        dateEntree: DateTime(2026, 7, 15),
      ));
      final withEntry = state.stockQuantityOf('shelter_1', 'masques');
      expect(withEntry, greaterThanOrEqualTo(200));

      state.removeStockEntry('test_rm_1');

      expect(state.stockQuantityOf('shelter_1', 'masques'), withEntry - 200);
      final shelter = state.shelters.firstWhere((s) => s.id == 'shelter_1');
      expect(shelter.stock['masques'],
          state.stockQuantityOf('shelter_1', 'masques'));
      expect(
        state.stockEntriesOf('shelter_1').any((e) => e.id == 'test_rm_1'),
        isFalse,
      );
    });

    test('removeStockEntry sur un id inconnu ne modifie rien', () {
      final countBefore = state.stockEntriesOf('shelter_1').length;
      state.removeStockEntry('id_inexistant');
      expect(state.stockEntriesOf('shelter_1').length, countBefore);
    });

    test('addStockEntry notifie les listeners', () {
      var notified = false;
      state.addListener(() => notified = true);
      state.addStockEntry(StockEntryModel(
        id: 'test_notify_1',
        refugeId: 'shelter_1',
        category: 'repas',
        label: 'Repas',
        quantity: 10,
        dateEntree: DateTime(2026, 7, 15),
      ));
      expect(notified, isTrue);
    });
  });
}
