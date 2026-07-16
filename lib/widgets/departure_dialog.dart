import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Informations de convoi saisies au moment du départ d'un transfert.
class DepartureInfo {
  final String? transportMode;
  final String? vehicleRegistration;
  final String? driverName;
  final String? driverPhone;

  const DepartureInfo({
    this.transportMode,
    this.vehicleRegistration,
    this.driverName,
    this.driverPhone,
  });
}

/// Dialog de saisie du convoi au départ : moyen de transport,
/// immatriculation, chauffeur et son téléphone. Renvoie null si annulé.
Future<DepartureInfo?> showDepartureDialog(BuildContext context) {
  return showDialog<DepartureInfo>(
    context: context,
    builder: (_) => const _DepartureDialog(),
  );
}

class _DepartureDialog extends StatefulWidget {
  const _DepartureDialog();

  @override
  State<_DepartureDialog> createState() => _DepartureDialogState();
}

class _DepartureDialogState extends State<_DepartureDialog> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  static const _transports = [
    'Bus',
    'Ambulance',
    'Voiture',
    'Minibus',
    'Autre'
  ];
  String _transport = 'Bus';

  @override
  void dispose() {
    _plateCtrl.dispose();
    _driverCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      DepartureInfo(
        transportMode: _transport,
        vehicleRegistration: _plateCtrl.text.trim().isEmpty
            ? null
            : _plateCtrl.text.trim().toUpperCase(),
        driverName:
            _driverCtrl.text.trim().isEmpty ? null : _driverCtrl.text.trim(),
        driverPhone:
            _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.directions_bus, color: AppColors.blue, size: 22),
          SizedBox(width: 8),
          Expanded(
              child: Text('Départ du convoi', style: TextStyle(fontSize: 18))),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Moyen de transport'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in _transports)
                    ChoiceChip(
                      label: Text(t),
                      selected: _transport == t,
                      onSelected: (_) => setState(() => _transport = t),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const _Label('Immatriculation *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _plateCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: _dec('AB-123-CD'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 14),
              const _Label('Chauffeur *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _driverCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Nom du chauffeur'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 14),
              const _Label('Téléphone chauffeur'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _dec('0690 00 00 00'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.local_shipping, size: 18),
          label: const Text('Marquer le départ'),
        ),
      ],
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: AppColors.bgPage,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));
}
