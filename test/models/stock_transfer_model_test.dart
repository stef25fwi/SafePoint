import 'package:flutter_test/flutter_test.dart';
import 'package:safepoint_app/models/enums.dart';
import 'package:safepoint_app/models/stock_transfer_model.dart';

void main() {
  group('StockTransferModel', () {
    StockTransferModel sample() => StockTransferModel(
          id: 'transfer_x',
          fromShelterId: 'shelter_1',
          fromShelterName: 'Gymnase de Baie-Mahault',
          toShelterId: 'shelter_2',
          toShelterName: 'Centre de Capesterre',
          category: 'couvertures',
          label: 'Couvertures de survie',
          quantity: 40,
          unit: 'unités',
          createdAt: DateTime(2026, 7, 15, 8),
          requestedBy: 'Agent NESTOR',
        );

    test('valeurs par défaut : statut en attente, updatedAt/updatedBy alignés',
        () {
      final t = sample();
      expect(t.status, TransferStatus.pending);
      expect(t.updatedAt, t.createdAt);
      expect(t.updatedBy, t.requestedBy);
      expect(t.departedAt, isNull);
      expect(t.confirmedAt, isNull);
      expect(t.outEntryId, isNull);
      expect(t.inEntryId, isNull);
    });

    test('copyWith fait évoluer le statut sans toucher aux champs figés', () {
      final t = sample();
      final departed = t.copyWith(
        status: TransferStatus.inProgress,
        departedAt: DateTime(2026, 7, 15, 9),
        updatedBy: 'Agent PIERRE',
      );

      expect(departed.status, TransferStatus.inProgress);
      expect(departed.departedAt, DateTime(2026, 7, 15, 9));
      expect(departed.updatedBy, 'Agent PIERRE');
      // Champs d'origine préservés
      expect(departed.id, t.id);
      expect(departed.quantity, t.quantity);
      expect(departed.fromShelterId, t.fromShelterId);
      expect(departed.toShelterId, t.toShelterId);
      expect(departed.requestedBy, t.requestedBy);
    });

    test('toSqlMap sérialise le statut et les dates ISO8601', () {
      final t = sample().copyWith(
        status: TransferStatus.confirmed,
        confirmedAt: DateTime(2026, 7, 15, 10),
        inEntryId: 'entry_in_1',
      );
      final map = t.toSqlMap();

      expect(map['status'], 'confirmed');
      expect(map['quantity'], 40);
      expect(map['from_refuge_id'], 'shelter_1');
      expect(map['to_refuge_id'], 'shelter_2');
      expect(map['confirmed_at'], DateTime(2026, 7, 15, 10).toIso8601String());
      expect(map['in_entry_id'], 'entry_in_1');
      expect(map['created_at'], DateTime(2026, 7, 15, 8).toIso8601String());
    });
  });
}
