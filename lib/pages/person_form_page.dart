import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/app_colors.dart';
import '../core/app_routes.dart';
import '../models/enums.dart';
import '../models/person_model.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';

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
  final _phoneCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();

  String? _selectedCommune;
  String? _selectedFamilyId;
  String? _selectedZone;
  PersonStatus _initialStatus = PersonStatus.present;
  bool _isLoading = false;

  final Set<String> _vulnerabilityFlags = {};
  final Set<NeedType> _needFlags = {};

  final _communes = [
    'Saint-Claude',
    'Gourbeyre',
    'Basse-Terre',
    'Trois-Rivières',
    'Capesterre-Belle-Eau',
    'Vieux-Fort',
    'Vieux-Habitants',
    'Baillif',
    'Bouillante',
    'Pointe-Noire',
  ];

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _sectorCtrl.dispose();
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

    final person = PersonModel(
      id: personId,
      eventId: 'event_1',
      shelterId: state.currentShelterId,
      familyId: _selectedFamilyId,
      qrCode:
          'rv://event/event_1/person/$personId/token/${uuid.v4().substring(0, 8)}',
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim().toUpperCase(),
      ageApprox: int.tryParse(_ageCtrl.text),
      originCommune: _selectedCommune,
      originSector:
          _sectorCtrl.text.trim().isEmpty ? null : _sectorCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      currentZone: _selectedZone,
      status: _initialStatus,
      vulnerabilityFlags: _vulnerabilityFlags.toList(),
      needFlags: _needFlags.toList(),
      createdAt: DateTime.now(),
      lastCheckinAt: DateTime.now(),
    );

    state.addPerson(person);

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.personDetail,
        arguments: personId);
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
                subtitle:
                    'Centre d\'hébergement – ${state.currentShelter.name}',
                showBack: true,
                showNotification: false,
              ),
              // Progress
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    const Text('Nouvelle fiche',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    const Text('Étape 1 sur 2',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.blue,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.5,
                      backgroundColor: AppColors.divider,
                      color: AppColors.blue,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Informations
                      _FormSection(
                        icon: Icons.person_outlined,
                        title: 'Informations de la personne',
                        iconColor: AppColors.blue,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: _field('Nom *', _lastNameCtrl,
                                      Icons.person_outline,
                                      required: true)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _field('Prénom *', _firstNameCtrl,
                                      Icons.person_outline,
                                      required: true)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _field('Âge / Date de naissance *', _ageCtrl,
                              Icons.calendar_today_outlined,
                              hint: 'JJ / MM / AAAA ou âge',
                              keyboardType: TextInputType.number),
                          const SizedBox(height: 12),
                          _Dropdown(
                            icon: Icons.location_on_outlined,
                            hint: 'Commune d\'origine *',
                            value: _selectedCommune,
                            items: _communes,
                            onChanged: (v) =>
                                setState(() => _selectedCommune = v),
                          ),
                          const SizedBox(height: 12),
                          _field('Secteur / Quartier', _sectorCtrl,
                              Icons.business_outlined),
                          const SizedBox(height: 12),
                          _field('Téléphone', _phoneCtrl, Icons.phone_outlined,
                              hint: '06 12 34 56 78',
                              keyboardType: TextInputType.phone),
                          const SizedBox(height: 12),
                          _Dropdown(
                            icon: Icons.group_outlined,
                            hint: 'Groupe familial',
                            value: _selectedFamilyId,
                            items: families.map((f) => f.id).toList(),
                            displayItems:
                                families.map((f) => f.displayName).toList(),
                            onChanged: (v) =>
                                setState(() => _selectedFamilyId = v),
                            nullable: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Besoins/vulnérabilités
                      _FormSection(
                        icon: Icons.favorite_outline,
                        title: 'Besoins / vulnérabilités',
                        iconColor: AppColors.orange,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _VulnChip(
                                  label: 'Enfant',
                                  icon: Icons.child_care,
                                  flag: 'enfant',
                                  selected:
                                      _vulnerabilityFlags.contains('enfant'),
                                  onTap: () => _toggleVulnerability('enfant'),
                                  color: AppColors.blue),
                              _VulnChip(
                                  label: 'Personne âgée',
                                  icon: Icons.elderly,
                                  flag: 'personne_agee',
                                  selected: _vulnerabilityFlags
                                      .contains('personne_agee'),
                                  onTap: () =>
                                      _toggleVulnerability('personne_agee'),
                                  color: AppColors.purple),
                              _VulnChip(
                                  label: 'PMR',
                                  icon: Icons.accessible,
                                  flag: 'pmr',
                                  selected: _vulnerabilityFlags.contains('pmr'),
                                  onTap: () => _toggleVulnerability('pmr'),
                                  color: AppColors.green),
                              _VulnChip(
                                  label: 'Traitement médical',
                                  icon: Icons.medical_services_outlined,
                                  flag: 'medical',
                                  selected:
                                      _needFlags.contains(NeedType.medical),
                                  onTap: () => _toggleNeed(NeedType.medical),
                                  color: AppColors.red),
                              _VulnChip(
                                  label: 'Grossesse',
                                  icon: Icons.pregnant_woman,
                                  flag: 'grossesse',
                                  selected:
                                      _vulnerabilityFlags.contains('grossesse'),
                                  onTap: () =>
                                      _toggleVulnerability('grossesse'),
                                  color: Colors.pink),
                              _VulnChip(
                                  label: 'Animal',
                                  icon: Icons.pets_outlined,
                                  flag: 'animal',
                                  selected:
                                      _needFlags.contains(NeedType.animal),
                                  onTap: () => _toggleNeed(NeedType.animal),
                                  color: AppColors.amber),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Affectation
                      _FormSection(
                        icon: Icons.location_on,
                        title: 'Affectation',
                        iconColor: AppColors.navy,
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
                            items: [
                              PersonStatus.present.name,
                              PersonStatus.nonPointee.name,
                              PersonStatus.aVerifier.name
                            ],
                            displayItems: const [
                              'Présent(e)',
                              'Non pointé(e)',
                              'Suivi requis'
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _initialStatus = PersonStatus
                                    .values
                                    .firstWhere((s) => s.name == v));
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Submit
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
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

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
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
        labelText: null,
      ),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null
          : null,
    );
  }
}

class _FormSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final List<Widget> children;

  const _FormSection({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ],
          ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Text(hint,
                  style:
                      const TextStyle(color: AppColors.textHint, fontSize: 14)),
            ],
          ),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.textSecondary),
          items: [
            if (nullable)
              const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Aucun',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14))),
            ...items.asMap().entries.map((e) => DropdownMenuItem<String>(
                  value: e.value,
                  child: Text(displayItems?[e.key] ?? e.value,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary)),
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
  final String flag;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _VulnChip({
    required this.label,
    required this.icon,
    required this.flag,
    required this.selected,
    required this.onTap,
    required this.color,
  });

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
          border: Border.all(
              color: selected ? color : AppColors.divider,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: selected ? color : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? color : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
