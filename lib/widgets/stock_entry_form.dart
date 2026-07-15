import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/app_colors.dart';
import '../models/stock_entry_model.dart';
import '../services/app_state.dart';

/// Catégories normalisées pilotant l'agrégat de stock du centre.
/// Alignées sur les clés utilisées par le tableau de bord et les alertes.
const _categories = <_Cat>[
  _Cat('eau', 'Eau', Icons.water_drop, 'litres'),
  _Cat('repas', 'Repas', Icons.restaurant, 'portions'),
  _Cat('couvertures', 'Couvertures', Icons.airline_seat_flat_angled, 'unités'),
  _Cat('lits', 'Lits', Icons.bed, 'unités'),
  _Cat('masques', 'Masques', Icons.masks, 'unités'),
  _Cat('couches', 'Couches', Icons.child_care, 'unités'),
  _Cat('medicaments', 'Médicaments', Icons.medical_services, 'kits'),
  _Cat('hygiene', 'Hygiène', Icons.soap, 'unités'),
  _Cat('vetements', 'Vêtements', Icons.checkroom, 'unités'),
  _Cat('autre', 'Autre', Icons.inventory_2, 'unités'),
];

class _Cat {
  final String key;
  final String label;
  final IconData icon;
  final String defaultUnit;
  const _Cat(this.key, this.label, this.icon, this.defaultUnit);
}

/// Ouvre le formulaire d'ajout d'une entrée de stock pour [shelterId].
Future<void> showStockEntryForm(BuildContext context, String shelterId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StockEntrySheet(shelterId: shelterId),
  );
}

class _StockEntrySheet extends StatefulWidget {
  final String shelterId;
  const _StockEntrySheet({required this.shelterId});

  @override
  State<_StockEntrySheet> createState() => _StockEntrySheetState();
}

class _StockEntrySheetState extends State<_StockEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'litres');
  final _provenanceCtrl = TextEditingController();

  _Cat _category = _categories.first;
  DateTime _dateEntree = DateTime.now();
  DateTime? _expiry;
  Uint8List? _photoBytes;
  bool _pickingPhoto = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _provenanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto(ImageSource source) async {
    setState(() => _pickingPhoto = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 70,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        if (mounted) setState(() => _photoBytes = bytes);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Capture photo indisponible sur cet appareil.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _pickDate({required bool forExpiry}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: forExpiry ? (_expiry ?? now) : _dateEntree,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) {
      setState(() {
        if (forExpiry) {
          _expiry = picked;
        } else {
          _dateEntree = picked;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    final entry = StockEntryModel(
      id: const Uuid().v4(),
      refugeId: widget.shelterId,
      category: _category.key,
      label: _labelCtrl.text.trim(),
      quantity: int.tryParse(_qtyCtrl.text.trim()) ?? 0,
      unit: _unitCtrl.text.trim(),
      dateEntree: _dateEntree,
      provenance: _provenanceCtrl.text.trim().isEmpty
          ? null
          : _provenanceCtrl.text.trim(),
      expiryDate: _expiry,
      photoBytes: _photoBytes,
      organizationId: state.currentOrganizationId,
      addedBy: state.currentAgentCode.isEmpty
          ? 'Agent'
          : state.currentAgentCode,
    );
    state.addStockEntry(entry);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${entry.quantity} ${entry.unit} de ${entry.label} '
          'ajoutés au stock.'),
      backgroundColor: AppColors.green,
    ));
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
                  const Icon(Icons.add_box_outlined,
                      color: AppColors.navy, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Nouvelle entrée de stock',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Photo d'étiquetage
                    _PhotoPicker(
                      photoBytes: _photoBytes,
                      busy: _pickingPhoto,
                      onCamera: () => _capturePhoto(ImageSource.camera),
                      onGallery: () => _capturePhoto(ImageSource.gallery),
                      onClear: () => setState(() => _photoBytes = null),
                    ),
                    const SizedBox(height: 16),

                    // Catégorie
                    const _FieldLabel('Catégorie'),
                    _CategorySelector(
                      value: _category,
                      onChanged: (c) => setState(() {
                        _category = c;
                        if (_unitCtrl.text.isEmpty) {
                          _unitCtrl.text = c.defaultUnit;
                        }
                      }),
                    ),
                    const SizedBox(height: 14),

                    // Produit
                    const _FieldLabel('Produit *'),
                    TextFormField(
                      controller: _labelCtrl,
                      decoration: _dec('Ex : Palette eau Cristaline 1,5 L'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Champ requis'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Quantité + unité
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('Quantité *'),
                              TextFormField(
                                controller: _qtyCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _dec('0'),
                                validator: (v) {
                                  final n = int.tryParse(v?.trim() ?? '');
                                  if (n == null || n <= 0) {
                                    return 'Quantité invalide';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('Unité'),
                              TextFormField(
                                controller: _unitCtrl,
                                decoration: _dec('unité'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Date d'entrée + péremption
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'Date d\'entrée *',
                            value: _fmtDate(_dateEntree),
                            onTap: () => _pickDate(forExpiry: false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: 'Péremption',
                            value: _expiry != null ? _fmtDate(_expiry!) : '—',
                            onTap: () => _pickDate(forExpiry: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Provenance
                    const _FieldLabel('Provenance'),
                    TextFormField(
                      controller: _provenanceCtrl,
                      decoration:
                          _dec('Ex : Préfecture, Croix-Rouge, don, achat…'),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Ajouter au stock'),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom + 12),
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

class _PhotoPicker extends StatelessWidget {
  final Uint8List? photoBytes;
  final bool busy;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onClear;

  const _PhotoPicker({
    required this.photoBytes,
    required this.busy,
    required this.onCamera,
    required this.onGallery,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (photoBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(photoBytes!,
                height: 160, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: busy
          ? const Center(child: CircularProgressIndicator())
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PhotoBtn(
                    icon: Icons.photo_camera,
                    label: 'Photographier\nl\'étiquette',
                    onTap: onCamera),
                const SizedBox(width: 24),
                _PhotoBtn(
                    icon: Icons.photo_library_outlined,
                    label: 'Choisir\nune image',
                    onTap: onGallery),
              ],
            ),
    );
  }
}

class _PhotoBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PhotoBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: AppColors.navy),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy)),
        ],
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final _Cat value;
  final ValueChanged<_Cat> onChanged;
  const _CategorySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = _categories[i];
          final sel = c.key == value.key;
          return GestureDetector(
            onTap: () => onChanged(c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: sel ? AppColors.navy : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? AppColors.navy : AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(c.icon,
                      size: 16,
                      color: sel ? Colors.white : AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(c.label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppColors.textPrimary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateField(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
