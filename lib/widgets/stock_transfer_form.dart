import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/app_state.dart';

/// Métadonnées d'affichage (icône, libellé, unité par défaut) pour les
/// catégories de stock. Reprend les clés utilisées par l'onglet Stocks et
/// le formulaire d'entrée, afin d'afficher un rendu cohérent ici aussi.
class _CatMeta {
  final String label;
  final IconData icon;
  final String defaultUnit;
  const _CatMeta(this.label, this.icon, this.defaultUnit);
}

const _catMeta = <String, _CatMeta>{
  'eau': _CatMeta('Eau', Icons.water_drop, 'litres'),
  'repas': _CatMeta('Repas', Icons.restaurant, 'portions'),
  'couvertures':
      _CatMeta('Couvertures', Icons.airline_seat_flat_angled, 'unités'),
  'lits': _CatMeta('Lits', Icons.bed, 'unités'),
  'masques': _CatMeta('Masques', Icons.masks, 'unités'),
  'couches': _CatMeta('Couches', Icons.child_care, 'unités'),
  'medicaments': _CatMeta('Médicaments', Icons.medical_services, 'kits'),
  'hygiene': _CatMeta('Hygiène', Icons.soap, 'unités'),
  'vetements': _CatMeta('Vêtements', Icons.checkroom, 'unités'),
  'autre': _CatMeta('Autre', Icons.inventory_2, 'unités'),
};

_CatMeta _metaOf(String key) =>
    _catMeta[key] ?? _CatMeta(key, Icons.inventory_2, 'unités');

/// Ouvre le formulaire de transfert de stock depuis [fromShelterId].
Future<void> showStockTransferForm(BuildContext context, String fromShelterId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StockTransferSheet(fromShelterId: fromShelterId),
  );
}

class _StockTransferSheet extends StatefulWidget {
  final String fromShelterId;
  const _StockTransferSheet({required this.fromShelterId});

  @override
  State<_StockTransferSheet> createState() => _StockTransferSheetState();
}

class _StockTransferSheetState extends State<_StockTransferSheet> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _category;
  String? _toShelterId;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit(AppState state, Map<String, int> available) {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null || _toShelterId == null) return;

    final fromShelter =
        state.shelters.firstWhere((s) => s.id == widget.fromShelterId);
    final toShelter = state.shelters.firstWhere((s) => s.id == _toShelterId);
    final meta = _metaOf(_category!);
    final quantity = int.parse(_qtyCtrl.text.trim());

    state.addStockTransfer(
      fromShelterId: fromShelter.id,
      fromShelterName: fromShelter.name,
      toShelterId: toShelter.id,
      toShelterName: toShelter.name,
      category: _category!,
      label: meta.label,
      quantity: quantity,
      unit: meta.defaultUnit,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '$quantity ${meta.defaultUnit} de ${meta.label} en transfert vers ${toShelter.name}.'),
      backgroundColor: AppColors.blue,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final fromShelter =
        state.shelters.firstWhere((s) => s.id == widget.fromShelterId);
    final available = Map<String, int>.from(fromShelter.stock)
      ..removeWhere((_, qty) => qty <= 0);
    final destinations =
        state.shelters.where((s) => s.id != widget.fromShelterId).toList();

    if (_category == null && available.isNotEmpty) {
      _category = available.keys.first;
    }
    final maxQty = _category != null ? (available[_category] ?? 0) : 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgPage,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: AppColors.navy, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Transférer depuis ${fromShelter.name}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: available.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucun stock disponible dans ce centre pour un transfert.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          const _FieldLabel('Produit à transférer'),
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: available.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                final key = available.keys.elementAt(i);
                                final meta = _metaOf(key);
                                final sel = key == _category;
                                return GestureDetector(
                                  onTap: () => setState(() => _category = key),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color:
                                          sel ? AppColors.navy : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: sel
                                              ? AppColors.navy
                                              : AppColors.divider),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(meta.icon,
                                            size: 16,
                                            color: sel
                                                ? Colors.white
                                                : AppColors.textSecondary),
                                        const SizedBox(width: 6),
                                        Text(meta.label,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: sel
                                                    ? Colors.white
                                                    : AppColors.textPrimary)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                              'Disponible : $maxQty ${_metaOf(_category ?? '').defaultUnit}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 14),
                          const _FieldLabel('Quantité à transférer *'),
                          TextFormField(
                            controller: _qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _dec('0'),
                            validator: (v) {
                              final n = int.tryParse(v?.trim() ?? '');
                              if (n == null || n <= 0) {
                                return 'Quantité invalide';
                              }
                              if (n > maxQty) {
                                return 'Maximum disponible : $maxQty';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          const _FieldLabel('Centre destinataire *'),
                          DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: _toShelterId ??
                                (destinations.isNotEmpty
                                    ? destinations.first.id
                                    : null),
                            decoration: _dec('Sélectionner un centre'),
                            items: destinations
                                .map((s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(s.name,
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _toShelterId = v),
                            validator: (v) => v == null ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 14),
                          const _FieldLabel('Notes'),
                          TextFormField(
                            controller: _notesCtrl,
                            decoration: _dec('Motif, urgence, instructions…'),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _submit(state, available),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Lancer le transfert'),
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).viewInsets.bottom +
                                  12),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      );
}
