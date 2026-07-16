import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:safepoint_app/core/constants/app_constants.dart';
import 'package:safepoint_app/models/stock_entry_model.dart';

void main() {
  group('StockEntryModel', () {
    StockEntryModel sample() => StockEntryModel(
          id: 'stock_x',
          refugeId: 'shelter_1',
          category: 'eau',
          label: 'Palette Cristaline 1,5 L',
          quantity: 480,
          unit: 'bouteilles',
          dateEntree: DateTime(2026, 7, 14, 9, 30),
          provenance: 'Préfecture',
          expiryDate: DateTime(2026, 12, 31),
          notes: 'Livraison partielle',
          addedBy: 'Agent LUREL',
          createdAt: DateTime(2026, 7, 14, 10),
        );

    test('createdAt par défaut est renseigné', () {
      final e = StockEntryModel(
        id: 'a',
        refugeId: 'shelter_1',
        category: 'repas',
        label: 'Rations',
        quantity: 10,
        dateEntree: DateTime(2026, 1, 1),
      );
      expect(e.createdAt, isNotNull);
      expect(e.organizationId, AppDefaults.organizationId);
      expect(e.addedBy, AppDefaults.demoUserId);
    });

    test('hasPhoto suit photoBytes et photoUrl', () {
      expect(sample().hasPhoto, isFalse);
      expect(sample().copyWith(photoUrl: 'https://x/y.jpg').hasPhoto, isTrue);
      expect(
        sample().copyWith(photoBytes: Uint8List.fromList([1, 2, 3])).hasPhoto,
        isTrue,
      );
    });

    test('toMap exclut les octets de photo (transient) et sérialise les dates',
        () {
      final map =
          sample().copyWith(photoBytes: Uint8List.fromList([9, 9])).toMap();
      expect(map.containsKey('photoBytes'), isFalse);
      expect(map.containsKey('photo_bytes'), isFalse);
      expect(
          map['date_entree'], DateTime(2026, 7, 14, 9, 30).toIso8601String());
      expect(map['expiry_date'], DateTime(2026, 12, 31).toIso8601String());
      expect(map['refuge_id'], 'shelter_1');
      expect(map['added_by'], 'Agent LUREL');
    });

    test('round-trip toMap -> fromMap préserve les champs persistés', () {
      final original = sample();
      final restored = StockEntryModel.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.refugeId, original.refugeId);
      expect(restored.category, original.category);
      expect(restored.label, original.label);
      expect(restored.quantity, original.quantity);
      expect(restored.unit, original.unit);
      expect(restored.dateEntree, original.dateEntree);
      expect(restored.provenance, original.provenance);
      expect(restored.expiryDate, original.expiryDate);
      expect(restored.notes, original.notes);
      expect(restored.addedBy, original.addedBy);
      expect(restored.createdAt, original.createdAt);
    });

    test('fromMap tolère une map incomplète sans planter', () {
      final e = StockEntryModel.fromMap({'id': 'z'});
      expect(e.id, 'z');
      expect(e.quantity, 0);
      expect(e.category, '');
      expect(e.expiryDate, isNull);
      expect(e.organizationId, AppDefaults.organizationId);
    });
  });
}
