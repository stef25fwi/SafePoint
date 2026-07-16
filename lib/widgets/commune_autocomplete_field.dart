import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/commune_model.dart';
import '../services/geo_api_service.dart';

/// Champ d'autocomplétion de commune branché sur geo.api.gouv.fr.
///
/// Renvoie la commune sélectionnée (nom + code INSEE + code postal + population)
/// via [onSelected]. En cas d'absence de réseau, l'API renvoie une liste vide
/// et l'utilisateur peut tout de même saisir librement le nom (fallback offline
/// proposé via [fallbackCommunes]).
class CommuneAutocompleteField extends StatelessWidget {
  final String? initialValue;
  final ValueChanged<CommuneModel> onSelected;

  /// Filtre départemental (ex : '971' Guadeloupe) pour cibler les résultats.
  final String? codeDepartement;

  /// Communes proposées hors-ligne si l'API est injoignable.
  final List<String> fallbackCommunes;

  const CommuneAutocompleteField({
    super.key,
    this.initialValue,
    required this.onSelected,
    this.codeDepartement,
    this.fallbackCommunes = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<CommuneModel>(
      initialValue:
          initialValue != null ? TextEditingValue(text: initialValue!) : null,
      displayStringForOption: (c) => c.displayLabel,
      optionsBuilder: (TextEditingValue value) async {
        final q = value.text.trim();
        if (q.length < 2) return const Iterable<CommuneModel>.empty();
        final results = await GeoApiService.instance
            .searchByName(q, codeDepartement: codeDepartement);
        if (results.isNotEmpty) return results;
        // Fallback hors-ligne : propose les communes locales correspondantes.
        return fallbackCommunes
            .where((name) => name.toLowerCase().contains(q.toLowerCase()))
            .map((name) => CommuneModel(nom: name, codeInsee: ''));
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.location_on_outlined,
                size: 18, color: AppColors.textSecondary),
            hintText: 'Commune d\'origine *',
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Champ requis' : null,
        );
      },
      optionsViewBuilder: (context, onSelectedCb, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final c = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    title: Text(c.nom,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      [
                        if (c.codePostal != null) c.codePostal,
                        if (c.population != null) '${c.population} hab.',
                      ].whereType<String>().join(' · '),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () => onSelectedCb(c),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
