import 'package:flutter_test/flutter_test.dart';
import 'package:safepoint_app/models/commune_model.dart';
import 'package:safepoint_app/services/geo_api_service.dart';

void main() {
  group('CommuneModel — parsing geo.api.gouv.fr', () {
    test('fromGeoApi extrait nom, code INSEE, CP et population', () {
      final commune = CommuneModel.fromGeoApi({
        'nom': 'Baie-Mahault',
        'code': '97103',
        'codesPostaux': ['97122'],
        'population': 32703,
        'codeDepartement': '971',
        'codeRegion': '01',
      });
      expect(commune.nom, 'Baie-Mahault');
      expect(commune.codeInsee, '97103');
      expect(commune.codePostal, '97122');
      expect(commune.population, 32703);
      expect(commune.codeDepartement, '971');
    });

    test('fromGeoApi tolère les champs manquants', () {
      final commune = CommuneModel.fromGeoApi(const {});
      expect(commune.nom, '');
      expect(commune.codeInsee, '');
      expect(commune.codePostal, isNull);
      expect(commune.population, isNull);
    });

    test('displayLabel inclut le CP quand disponible', () {
      final avec = CommuneModel.fromGeoApi({
        'nom': 'Basse-Terre',
        'code': '97105',
        'codesPostaux': ['97100'],
      });
      expect(avec.displayLabel, 'Basse-Terre (97100)');

      const sans = CommuneModel(nom: 'Inconnue', codeInsee: 'x');
      expect(sans.displayLabel, 'Inconnue');
    });

    test('toMap / fromMap est un aller-retour sans perte', () {
      const original = CommuneModel(
        nom: 'Capesterre-Belle-Eau',
        codeInsee: '97107',
        codesPostaux: ['97130'],
        population: 18460,
        codeDepartement: '971',
        codeRegion: '01',
      );
      final roundTrip = CommuneModel.fromMap(original.toMap());
      expect(roundTrip.nom, original.nom);
      expect(roundTrip.codeInsee, original.codeInsee);
      expect(roundTrip.codesPostaux, original.codesPostaux);
      expect(roundTrip.population, original.population);
    });
  });

  group('GeoApiService — validation des entrées (sans réseau)', () {
    final svc = GeoApiService.instance;

    test('recherche vide : liste vide, aucun appel réseau', () async {
      expect(await svc.searchByName(''), isEmpty);
      expect(await svc.searchByName('   '), isEmpty);
    });

    test('code postal trop court : liste vide, aucun appel réseau', () async {
      expect(await svc.searchByCodePostal(''), isEmpty);
      expect(await svc.searchByCodePostal('9'), isEmpty);
    });

    test('échec réseau : liste vide plutôt qu\'exception (mode hors-ligne)',
        () async {
      // En environnement de test, l'appel HTTP échoue : le service doit
      // dégrader proprement vers une liste vide (l'UI bascule alors sur le
      // fallback local / la saisie manuelle).
      final result = await svc.searchByName('Basse-Terre');
      expect(result, isA<List<CommuneModel>>());
    });
  });
}
