import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/app_colors.dart';
import '../models/enums.dart';
import '../models/transfer_model.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';

class CreateTransferPage extends StatefulWidget {
  const CreateTransferPage({super.key});

  @override
  State<CreateTransferPage> createState() => _CreateTransferPageState();
}

class _CreateTransferPageState extends State<CreateTransferPage> {
  String? _toShelterId;
  String? _transportMode;
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  final _transports = ['Bus', 'Ambulance', 'Voiture', 'Minibus', 'Autre'];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context, List<String> personIds) async {
    if (_toShelterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir un centre de destination')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final state = context.read<AppState>();
    final dest = state.shelters.firstWhere((s) => s.id == _toShelterId!);
    final transfer = TransferModel(
      id: const Uuid().v4(),
      eventId: 'event_1',
      fromShelterId: state.currentShelterId,
      fromShelterName: state.currentShelter.name,
      toShelterId: _toShelterId!,
      toShelterName: dest.name,
      personIds: personIds,
      status: TransferStatus.pending,
      transportMode: _transportMode,
      departurePlannedAt: DateTime.now().add(const Duration(hours: 1)),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
    );
    state.addTransfer(transfer);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transfert créé avec succès'), backgroundColor: AppColors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final personIds = (args is List<String>) ? args : <String>[];
    final state = context.watch<AppState>();
    final destShelters = state.shelters.where((s) => s.id != state.currentShelterId).toList();

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'safepointapp.',
              subtitle: 'Nouveau transfert',
              showBack: true,
              showNotification: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Créer un transfert', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ),
                    const SizedBox(height: 16),

                    // Persons info
                    if (personIds.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.blueLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people_alt_outlined, color: AppColors.blue, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              '${personIds.length} personne${personIds.length > 1 ? 's' : ''} sélectionnée${personIds.length > 1 ? 's' : ''}',
                              style: const TextStyle(color: AppColors.blueText, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),

                    // Destination
                    _FormCard(
                      title: 'Centre de destination',
                      icon: Icons.business_outlined,
                      child: Column(
                        children: destShelters.map((s) {
                          final selected = _toShelterId == s.id;
                          return GestureDetector(
                            onTap: () => setState(() => _toShelterId = s.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.blueLight : AppColors.bgPage,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: selected ? AppColors.blue : AppColors.divider, width: selected ? 1.5 : 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.business, size: 18, color: selected ? AppColors.blue : AppColors.textSecondary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.name, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? AppColors.blue : AppColors.textPrimary, fontSize: 14)),
                                        Text('${s.placesRestantes} places restantes', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  if (selected) const Icon(Icons.check_circle, color: AppColors.blue, size: 20),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Transport
                    _FormCard(
                      title: 'Moyen de transport',
                      icon: Icons.directions_bus_outlined,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _transports.map((t) {
                          final sel = _transportMode == t;
                          return GestureDetector(
                            onTap: () => setState(() => _transportMode = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.blueLight : AppColors.bgPage,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: sel ? AppColors.blue : AppColors.divider, width: sel ? 1.5 : 1),
                              ),
                              child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? AppColors.blue : AppColors.textPrimary)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    _FormCard(
                      title: 'Notes (optionnel)',
                      icon: Icons.notes_outlined,
                      child: TextField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Informations complémentaires...',
                          filled: true,
                          fillColor: AppColors.bgPage,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _submit(context, personIds),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Créer le transfert'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FormCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.navy),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
