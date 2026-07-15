import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/app_colors.dart';
import '../core/app_routes.dart';
import '../models/enums.dart';
import '../models/person_model.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/commune_autocomplete_field.dart';
import '../widgets/translator_panel.dart';

class PersonFormPage extends StatefulWidget {
  const PersonFormPage({super.key});

  @override
  State<PersonFormPage> createState() => _PersonFormPageState();
}

class _PersonFormPageState extends State<PersonFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedCommune;
  String? _selectedCodeInsee;
  String? _selectedCodePostal;
  String? _selectedFamilyId;
  String? _selectedZone;
  PersonStatus _initialStatus = PersonStatus.present;
  bool _isLoading = false;
  bool _hasPapers = true;

  final Set<String> _vulnerabilityFlags = {};
  final Set<NeedType> _needFlags = {};

  final _communes = [
    'Saint-Claude', 'Gourbeyre', 'Basse-Terre', 'Trois-Rivières',
    'Capesterre-Belle-Eau', 'Vieux-Fort', 'Vieux-Habitants',
    'Baillif', 'Bouillante', 'Pointe-Noire',
  ];

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _ageCtrl.dispose();
    _birthDateCtrl.dispose();
    _phoneCtrl.dispose();
    _sectorCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _toggleVulnerability(String flag) {
    setState(() {
      if (_vulnerabilityFlags.contains(flag)) {
        _vulnerabilityFlags.remove(flag);
      } else {
        _vulnerabilityFlags.add(flag);
      }
    });
  }

  void _toggleNeed(NeedType type) {
    setState(() {
      if (_needFlags.contains(type)) {
        _needFlags.remove(type);
      } else {
        _needFlags.add(type);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final state = context.read<AppState>();
    const uuid = Uuid();
    final personId = uuid.v4();

    final vuln = _vulnerabilityFlags.toList();
    if (!_hasPapers) vuln.add('sans_papiers');

    final person = PersonModel(
      id: personId,
      eventId: 'event_1',
      shelterId: state.currentShelterId,
      familyId: _selectedFamilyId,
      qrCode: 'sp://person/$personId/token/${uuid.v4().substring(0, 8)}',
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim().toUpperCase(),
      ageApprox: int.tryParse(_ageCtrl.text),
      originCommune: _selectedCommune,
      originCodeInsee: _selectedCodeInsee,
      originCodePostal: _selectedCodePostal,
      originSector: _sectorCtrl.text.trim().isEmpty ? null : _sectorCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      emergencyContactName: _emergencyNameCtrl.text.trim().isEmpty ? null : _emergencyNameCtrl.text.trim(),
      emergencyContactPhone: _emergencyPhoneCtrl.text.trim().isEmpty ? null : _emergencyPhoneCtrl.text.trim(),
      currentZone: _selectedZone,
      status: _initialStatus,
      vulnerabilityFlags: vuln,
      needFlags: _needFlags.toList(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
      lastCheckinAt: DateTime.now(),
    );

    state.addPerson(person);

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.personDetail, arguments: personId);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final families = state.currentFamilies;
    final zones = state.currentShelter.zones;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppHeader(
                title: 'safepointapp.',
                subtitle: 'Centre d\'hébergement – ${state.currentShelter.name}',
                showBack: true,
                showNotification: false,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    const Text('Nouvelle fiche personne', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.5,
                      backgroundColor: AppColors.divider,
                      color: AppColors.blue,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => showTranslatorPanel(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.purple,
                        side: const BorderSide(color: AppColors.purple),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.translate, size: 18),
                      label: const Text(
                          'Traducteur — parler avec la personne'),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [

                      // ── Identité ──────────────────────────────────────
                      _FormSection(
                        icon: Icons.person_outlined,
                        title: 'Identité',
                        iconColor: AppColors.blue,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _field('Nom *', _lastNameCtrl, Icons.person_outline, required: true)),
                              const SizedBox(width: 10),
                              Expanded(child: _field('Prénom *', _firstNameCtrl, Icons.person_outline, required: true)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _field(
                            'Âge approximatif *',
                            _ageCtrl,
                            Icons.calendar_today_outlined,
                            hint: 'ex : 42',
                            keyboardType: TextInputType.number,
                            required: true,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            'Date de naissance (JJ/MM/AA)',
                            _birthDateCtrl,
                            Icons.date_range_outlined,
                            hint: 'ex : 25/06/1980',
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 12),
                          CommuneAutocompleteField(
                            initialValue: _selectedCommune,
                            codeDepartement: '971',
                            fallbackCommunes: _communes,
                            onSelected: (c) => setState(() {
                              _selectedCommune = c.nom;
                              _selectedCodeInsee =
                                  c.codeInsee.isEmpty ? null : c.codeInsee;
                              _selectedCodePostal = c.codePostal;
                            }),
                          ),
                          const SizedBox(height: 12),
                          _field('Secteur / Quartier évacué', _sectorCtrl, Icons.business_outlined, hint: 'ex : Savane, Centre-ville…'),
                          const SizedBox(height: 12),
                          _field('Téléphone', _phoneCtrl, Icons.phone_outlined, hint: '06 90 12 34 56', keyboardType: TextInputType.phone),
                          const SizedBox(height: 12),
                          _Dropdown(
                            icon: Icons.group_outlined,
                            hint: 'Rattachement familial (optionnel)',
                            value: _selectedFamilyId,
                            items: families.map((f) => f.id).toList(),
                            displayItems: families.map((f) => f.displayName).toList(),
                            onChanged: (v) => setState(() => _selectedFamilyId = v),
                            nullable: true,
                          ),
                          const SizedBox(height: 12),
                          // Papiers
                          GestureDetector(
                            onTap: () => setState(() => _hasPapers = !_hasPapers),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: _hasPapers ? Colors.white : AppColors.orangeLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _hasPapers ? AppColors.divider : AppColors.orange),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.badge_outlined, size: 18, color: _hasPapers ? AppColors.textSecondary : AppColors.orangeText),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text('Arrivée sans papiers d\'identité', style: TextStyle(fontSize: 14, color: _hasPapers ? AppColors.textSecondary : AppColors.orangeText, fontWeight: _hasPapers ? FontWeight.normal : FontWeight.w600))),
                                  Icon(_hasPapers ? Icons.check_box_outline_blank : Icons.check_box, color: _hasPapers ? AppColors.textHint : AppColors.orange, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Contact d'urgence ─────────────────────────────
                      _FormSection(
                        icon: Icons.emergency_outlined,
                        title: 'Contact d\'urgence',
                        iconColor: AppColors.red,
                        children: [
                          _field('Nom du contact', _emergencyNameCtrl, Icons.person_pin_outlined, hint: 'Prénom Nom'),
                          const SizedBox(height: 12),
                          _field('Téléphone du contact', _emergencyPhoneCtrl, Icons.phone_in_talk_outlined, hint: '06 90 …', keyboardType: TextInputType.phone),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Vulnérabilités / Besoins ──────────────────────
                      _FormSection(
                        icon: Icons.favorite_outline,
                        title: 'Vulnérabilités / Besoins particuliers',
                        iconColor: AppColors.orange,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _VulnChip(label: 'Enfant', icon: Icons.child_care, selected: _vulnerabilityFlags.contains('enfant'), onTap: () => _toggleVulnerability('enfant'), color: AppColors.blue),
                              _VulnChip(label: 'Personne âgée', icon: Icons.elderly, selected: _vulnerabilityFlags.contains('personne_agee'), onTap: () => _toggleVulnerability('personne_agee'), color: AppColors.purple),
                              _VulnChip(label: 'PMR / Handicap', icon: Icons.accessible, selected: _vulnerabilityFlags.contains('pmr'), onTap: () => _toggleVulnerability('pmr'), color: AppColors.green),
                              _VulnChip(label: 'Traitement médical', icon: Icons.medical_services_outlined, selected: _needFlags.contains(NeedType.medical), onTap: () => _toggleNeed(NeedType.medical), color: AppColors.red),
                              _VulnChip(label: 'Grossesse', icon: Icons.pregnant_woman, selected: _vulnerabilityFlags.contains('grossesse'), onTap: () => _toggleVulnerability('grossesse'), color: Colors.pink),
                              _VulnChip(label: 'Isolement social', icon: Icons.person_off_outlined, selected: _vulnerabilityFlags.contains('isolement'), onTap: () => _toggleVulnerability('isolement'), color: AppColors.navy),
                              _VulnChip(label: 'Animal de compagnie', icon: Icons.pets_outlined, selected: _needFlags.contains(NeedType.animal), onTap: () => _toggleNeed(NeedType.animal), color: AppColors.amber),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Zone et statut ────────────────────────────────
                      _FormSection(
                        icon: Icons.business_outlined,
                        title: 'Affectation',
                        iconColor: AppColors.purple,
                        children: [
                          _Dropdown(
                            icon: Icons.business_outlined,
                            hint: 'Zone du centre *',
                            value: _selectedZone,
                            items: zones,
                            onChanged: (v) => setState(() => _selectedZone = v),
                          ),
                          const SizedBox(height: 12),
                          _Dropdown(
                            icon: Icons.shield_outlined,
                            hint: 'Statut initial *',
                            value: _initialStatus.name,
                            items: [PersonStatus.present.name, PersonStatus.nonPointee.name, PersonStatus.aVerifier.name],
                            displayItems: const ['Présent(e)', 'Non pointé(e)', 'Suivi requis'],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _initialStatus = PersonStatus.values.firstWhere((s) => s.name == v));
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Notes ─────────────────────────────────────────
                      _FormSection(
                        icon: Icons.notes_outlined,
                        title: 'Notes (usage interne)',
                        iconColor: AppColors.textSecondary,
                        children: [
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Informations complémentaires…',
                              prefixIcon: Icon(Icons.edit_note, size: 18, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.qr_code_2),
                        label: const Text('Enregistrer et générer le QR'),
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
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {
    String? hint,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        hintText: hint ?? label,
      ),
      validator: required ? (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null : null,
    );
  }
}

// ────────────────────────────────────────────────────────────
// Shared widgets
// ────────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final List<Widget> children;

  const _FormSection({required this.icon, required this.title, required this.iconColor, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final IconData icon;
  final String hint;
  final String? value;
  final List<String> items;
  final List<String>? displayItems;
  final Function(String?) onChanged;
  final bool nullable;

  const _Dropdown({
    required this.icon,
    required this.hint,
    required this.value,
    required this.items,
    this.displayItems,
    required this.onChanged,
    this.nullable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Row(children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(hint, style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
          ]),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          items: [
            if (nullable)
              const DropdownMenuItem<String>(value: null, child: Text('Aucun', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
            ...items.asMap().entries.map((e) => DropdownMenuItem<String>(
              value: e.value,
              child: Text(displayItems?[e.key] ?? e.value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _VulnChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _VulnChip({required this.label, required this.icon, required this.selected, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.divider, width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? color : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? color : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
