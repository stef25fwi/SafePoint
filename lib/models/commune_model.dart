/// Représente une commune renvoyée par l'API Découpage administratif
/// (geo.api.gouv.fr). Sert à l'autocomplétion des champs commune/CP et à
/// récupérer le code INSEE + la population municipale.
class CommuneModel {
  final String nom;
  final String codeInsee;
  final List<String> codesPostaux;
  final int? population;
  final String? codeDepartement;
  final String? codeRegion;

  const CommuneModel({
    required this.nom,
    required this.codeInsee,
    this.codesPostaux = const [],
    this.population,
    this.codeDepartement,
    this.codeRegion,
  });

  /// Premier code postal (le plus courant pour l'affichage).
  String? get codePostal => codesPostaux.isNotEmpty ? codesPostaux.first : null;

  /// Libellé d'affichage : « Baie-Mahault (97122) ».
  String get displayLabel => codePostal != null ? '$nom ($codePostal)' : nom;

  factory CommuneModel.fromGeoApi(Map<String, dynamic> json) {
    return CommuneModel(
      nom: json['nom'] as String? ?? '',
      codeInsee: json['code'] as String? ?? '',
      codesPostaux: (json['codesPostaux'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      population: json['population'] as int?,
      codeDepartement: json['codeDepartement'] as String?,
      codeRegion: json['codeRegion'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'codeInsee': codeInsee,
        'codesPostaux': codesPostaux,
        'population': population,
        'codeDepartement': codeDepartement,
        'codeRegion': codeRegion,
      };

  factory CommuneModel.fromMap(Map<String, dynamic> m) => CommuneModel(
        nom: m['nom'] as String? ?? '',
        codeInsee: m['codeInsee'] as String? ?? '',
        codesPostaux: (m['codesPostaux'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        population: m['population'] as int?,
        codeDepartement: m['codeDepartement'] as String?,
        codeRegion: m['codeRegion'] as String?,
      );
}
