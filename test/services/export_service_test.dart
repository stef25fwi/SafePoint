import 'package:flutter_test/flutter_test.dart';
import 'package:safepoint_app/models/enums.dart';
import 'package:safepoint_app/services/app_state.dart';
import 'package:safepoint_app/services/export_service.dart';

// Les exports alimentent la cellule de crise et la préfecture : chaque
// agrégat doit correspondre exactement aux données réelles de l'état.
void main() {
  late AppState state;
  final svc = ExportService.instance;

  setUp(() {
    state = AppState();
  });

  group('ExportService — synthèse par centre', () {
    test('une ligne par centre, en-têtes attendus', () {
      final table = svc.syntheseParCentre(state);
      expect(table.rows.length, state.shelters.length);
      expect(table.headers, contains('Centre'));
      expect(table.headers, contains('Capacité'));
      expect(table.headers, contains('Recensés'));
    });

    test('les recensés par centre correspondent aux personnes réelles', () {
      final table = svc.syntheseParCentre(state);
      final idxRecenses = table.headers.indexOf('Recensés');
      for (var i = 0; i < state.shelters.length; i++) {
        final shelter = state.shelters[i];
        final expected =
            state.everyPerson.where((p) => p.shelterId == shelter.id).length;
        expect(table.rows[i][idxRecenses], '$expected',
            reason: 'centre ${shelter.name}');
      }
    });

    test('les non pointés par centre correspondent au statut réel', () {
      final table = svc.syntheseParCentre(state);
      final idx = table.headers.indexOf('Non pointés');
      for (var i = 0; i < state.shelters.length; i++) {
        final shelter = state.shelters[i];
        final expected = state.everyPerson
            .where((p) =>
                p.shelterId == shelter.id &&
                p.status == PersonStatus.nonPointee)
            .length;
        expect(table.rows[i][idx], '$expected');
      }
    });
  });

  group('ExportService — synthèse par commune d\'origine', () {
    test('total des lignes = total des personnes (agrégat exhaustif)', () {
      final table = svc.syntheseParCommune(state);
      final total =
          table.rows.map((r) => int.parse(r[1])).fold(0, (a, b) => a + b);
      expect(total, state.everyPerson.length);
    });

    test('tri décroissant par effectif', () {
      final table = svc.syntheseParCommune(state);
      final values = table.rows.map((r) => int.parse(r[1])).toList();
      final sorted = [...values]..sort((a, b) => b.compareTo(a));
      expect(values, sorted);
    });
  });

  group('ExportService — listes nominatives', () {
    test('personnesNonPointees ne liste que le statut nonPointee', () {
      final table = svc.personnesNonPointees(state);
      expect(table.rows.length, state.everyNonPointee.length);
    });

    test('exportComplet liste toutes les personnes non supprimées', () {
      final table = svc.exportComplet(state);
      expect(table.rows.length, state.everyPerson.length);
      expect(table.headers, contains('Code INSEE'));
      expect(table.headers, contains('Vulnérabilités'));
    });

    test('besoins liste tous les besoins ouverts', () {
      final table = svc.besoins(state);
      expect(table.rows.length, state.everyOpenNeed.length);
    });
  });

  group('ExportService — CSV', () {
    test('en-têtes + une ligne par entrée, séparateur point-virgule', () {
      const table = ReportTable(
        title: 'Test',
        headers: ['A', 'B'],
        rows: [
          ['1', '2'],
          ['3', '4'],
        ],
      );
      final csv = svc.toCsv(table).trim().split('\n');
      expect(csv.length, 3);
      expect(csv[0], 'A;B');
      expect(csv[1], '1;2');
    });

    test('échappe les points-virgules, guillemets et sauts de ligne', () {
      const table = ReportTable(
        title: 'Test',
        headers: ['Champ'],
        rows: [
          ['valeur;avec;séparateurs'],
          ['citation "guillemets"'],
          ['multi\nligne'],
        ],
      );
      final csv = svc.toCsv(table);
      expect(csv, contains('"valeur;avec;séparateurs"'));
      expect(csv, contains('"citation ""guillemets"""'));
      expect(csv, contains('"multi\nligne"'));
    });

    test('le CSV de l\'export complet ne perd aucune ligne', () {
      final table = svc.exportComplet(state);
      final lines = svc.toCsv(table).trim().split('\n');
      // Aucune donnée mock ne contient de saut de ligne : 1 ligne d'en-tête
      // + 1 ligne par personne.
      expect(lines.length, 1 + table.rows.length);
    });
  });

  group('ExportService — PDF', () {
    test('toPdf produit un document non vide', () async {
      final table = svc.syntheseParCentre(state);
      final bytes = await svc.toPdf(table);
      expect(bytes.length, greaterThan(500));
      // Signature d'un fichier PDF.
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('toPdf gère une table vide sans erreur', () async {
      const empty = ReportTable(title: 'Vide', headers: ['X'], rows: []);
      final bytes = await svc.toPdf(empty);
      expect(bytes, isNotEmpty);
    });
  });
}
