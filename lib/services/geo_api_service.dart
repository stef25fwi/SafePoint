import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/commune_model.dart';

/// Accès à l'API Découpage administratif (geo.api.gouv.fr).
///
/// Permet l'autocomplétion des communes françaises avec récupération du
/// code INSEE, des codes postaux et de la population municipale.
/// API publique, sans clé, conforme aux usages du service public.
class GeoApiService {
  GeoApiService._();
  static final GeoApiService instance = GeoApiService._();

  static const _base = 'https://geo.api.gouv.fr';

  final http.Client _client = http.Client();

  /// Champs demandés à l'API (limite la charge réseau).
  static const _fields =
      'nom,code,codesPostaux,population,codeDepartement,codeRegion';

  /// Recherche de communes par nom (autocomplétion).
  /// [query] : début du nom de commune (min. 1 caractère).
  /// [codeDepartement] : filtre optionnel (ex : '971' pour la Guadeloupe).
  Future<List<CommuneModel>> searchByName(
    String query, {
    String? codeDepartement,
    int limit = 10,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final params = {
      'nom': q,
      'fields': _fields,
      'boost': 'population',
      'limit': '$limit',
      if (codeDepartement != null) 'codeDepartement': codeDepartement,
    };
    return _get('/communes', params);
  }

  /// Recherche de communes par code postal.
  Future<List<CommuneModel>> searchByCodePostal(String codePostal) async {
    final cp = codePostal.trim();
    if (cp.length < 2) return const [];
    return _get('/communes', {'codePostal': cp, 'fields': _fields});
  }

  /// Détail d'une commune par son code INSEE.
  Future<CommuneModel?> getByCodeInsee(String codeInsee) async {
    final list = await _get('/communes/$codeInsee', {'fields': _fields});
    return list.isNotEmpty ? list.first : null;
  }

  Future<List<CommuneModel>> _get(String path, Map<String, String> params) async {
    try {
      final uri = Uri.parse('$_base$path').replace(queryParameters: params);
      final res = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(CommuneModel.fromGeoApi)
            .toList();
      }
      if (decoded is Map<String, dynamic>) {
        return [CommuneModel.fromGeoApi(decoded)];
      }
      return const [];
    } catch (_) {
      // Réseau indisponible (mode hors-ligne) → liste vide, l'UI bascule
      // sur la saisie manuelle.
      return const [];
    }
  }

  void dispose() => _client.close();
}
