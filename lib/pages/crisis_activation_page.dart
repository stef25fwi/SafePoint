import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/enums.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/crisis_banner.dart';

class CrisisActivationPage extends StatefulWidget {
  const CrisisActivationPage({super.key});

  @override
  State<CrisisActivationPage> createState() => _CrisisActivationPageState();
}

class _CrisisActivationPageState extends State<CrisisActivationPage> {
  String _selectedType = 'eruption';
  final _zoneCtrl = TextEditingController();

  static const _types = [
    _EventType('eruption', 'Éruption volcanique', Icons.local_fire_department, AppColors.red),
    _EventType('inondation', 'Inondation', Icons.water, AppColors.blue),
    _EventType('seisme', 'Séisme', Icons.vibration, AppColors.orange),
    _EventType('cyclone', 'Cyclone tropical', Icons.air, AppColors.purple),
  ];

  static const _monthsFr = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  _EventType get _currentType =>
      _types.firstWhere((t) => t.id == _selectedType);

  String _buildEventName(String zone) {
    final now = DateTime.now();
    final month = _monthsFr[now.month - 1];
    final typeName = _currentType.label;
    return zone.trim().isEmpty
        ? '$typeName – $month ${now.year}'
        : '$typeName – ${zone.trim()} – $month ${now.year}';
  }

  @override
  void dispose() {
    _zoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmActivate(BuildContext context) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final eventName = _buildEventName(_zoneCtrl.text);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Confirmer l\'activation', style: TextStyle(fontSize: 17))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"$eventName"',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cette action déclenche immédiatement le mode crise pour tous les centres d\'hébergement.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Activer la crise', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      state.activateCrisis(
        name: eventName,
        type: _selectedType,
        zoneName: _zoneCtrl.text.trim(),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text('Crise activée : $eventName'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _confirmDeactivate(BuildContext context) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.green),
            SizedBox(width: 8),
            Text('Clôturer l\'événement', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: const Text(
          'Mettre fin à l\'événement de crise en cours ?\n\nLes centres sortiront du mode crise.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clôturer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      state.deactivateCrisis();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Événement clôturé – mode crise désactivé'),
          backgroundColor: AppColors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          AppHeader(
            title: 'safepointapp.',
            subtitle: 'Préfecture / COD – Gestion de crise',
            showBack: true,
            alertCount: state.openAlerts.length,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: state.isCrisisActive
                  ? _ActiveCrisisView(state: state, onDeactivate: () => _confirmDeactivate(context))
                  : _ActivationForm(
                      selectedType: _selectedType,
                      types: _types,
                      zoneCtrl: _zoneCtrl,
                      onTypeChanged: (t) => setState(() => _selectedType = t),
                      buildEventName: _buildEventName,
                      onActivate: () => _confirmActivate(context),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active crisis view ────────────────────────────────────────────────────────

class _ActiveCrisisView extends StatelessWidget {
  final AppState state;
  final VoidCallback onDeactivate;

  const _ActiveCrisisView({required this.state, required this.onDeactivate});

  String _elapsed(DateTime since) {
    final diff = DateTime.now().difference(since);
    if (diff.inDays >= 1) return '${diff.inDays} j ${diff.inHours.remainder(24)} h';
    if (diff.inHours >= 1) return '${diff.inHours} h ${diff.inMinutes.remainder(60)} min';
    return '${diff.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    final event = state.activeEvent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Active banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.redLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              const Icon(Icons.warning_rounded, color: AppColors.red, size: 48),
              const SizedBox(height: 12),
              const Text(
                'CRISE ACTIVE',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.red, letterSpacing: 1.5),
              ),
              const SizedBox(height: 6),
              Text(
                event.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Activé il y a ${_elapsed(event.startedAt)}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Shelters status
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.business, size: 18, color: AppColors.navy),
                  SizedBox(width: 8),
                  Text('État des centres', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 14),
              ...state.shelters.map((s) => _ShelterStatusRow(shelter: s)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Total stats
        Row(
          children: [
            Expanded(child: _StatTile(
              icon: Icons.group,
              label: 'Personnes\naccueillies',
              value: '${state.shelters.fold(0, (sum, s) => sum + s.currentCount)}',
              color: AppColors.blue,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatTile(
              icon: Icons.business_outlined,
              label: 'Centres\nactifs',
              value: '${state.shelters.where((s) => s.status == ShelterStatus.open || s.status == ShelterStatus.full).length}',
              color: AppColors.green,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatTile(
              icon: Icons.warning_rounded,
              label: 'Alertes\nouvertes',
              value: '${state.openAlerts.length}',
              color: AppColors.red,
            )),
          ],
        ),
        const SizedBox(height: 32),

        // Deactivate button
        OutlinedButton.icon(
          onPressed: onDeactivate,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.red,
            side: const BorderSide(color: AppColors.red),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.power_settings_new),
          label: const Text('Clôturer l\'événement de crise'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cette action met fin au mode crise pour tous les centres.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ShelterStatusRow extends StatelessWidget {
  final dynamic shelter;
  const _ShelterStatusRow({required this.shelter});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (shelter.status as ShelterStatus) {
      case ShelterStatus.open:
        statusColor = AppColors.green;
        statusLabel = 'Ouvert';
        statusIcon = Icons.check_circle;
      case ShelterStatus.full:
        statusColor = AppColors.orange;
        statusLabel = 'Complet';
        statusIcon = Icons.warning_rounded;
      case ShelterStatus.closed:
        statusColor = AppColors.grayText;
        statusLabel = 'Fermé';
        statusIcon = Icons.cancel;
      case ShelterStatus.preparation:
        statusColor = AppColors.blue;
        statusLabel = 'Préparation';
        statusIcon = Icons.hourglass_top;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(shelter.name as String,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
          Text('${shelter.currentCount as int} pers.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(statusLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color, height: 1.1)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Activation form ───────────────────────────────────────────────────────────

class _ActivationForm extends StatelessWidget {
  final String selectedType;
  final List<_EventType> types;
  final TextEditingController zoneCtrl;
  final void Function(String) onTypeChanged;
  final String Function(String) buildEventName;
  final VoidCallback onActivate;

  const _ActivationForm({
    required this.selectedType,
    required this.types,
    required this.zoneCtrl,
    required this.onTypeChanged,
    required this.buildEventName,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: const Column(
            children: [
              Icon(Icons.emergency, size: 44, color: AppColors.navy),
              SizedBox(height: 12),
              Text(
                'Activation d\'un événement de crise',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              SizedBox(height: 6),
              Text(
                'Déclenche la mise en alerte de tous les centres d\'hébergement du territoire.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Type selector
        const Text('Type d\'événement',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: types.map((t) => _TypeTile(
            type: t,
            selected: selectedType == t.id,
            onTap: () => onTypeChanged(t.id),
          )).toList(),
        ),
        const SizedBox(height: 20),

        // Zone / volcano name
        const Text('Localisation / nom de zone',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: zoneCtrl,
          decoration: const InputDecoration(
            hintText: 'Ex : Soufrière, Rivière Salée…',
            prefixIcon: Icon(Icons.place_outlined, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 20),

        // Live preview
        const Text('Aperçu de la bannière',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: zoneCtrl,
          builder: (ctx, val, _) => CrisisBanner(
            label: 'Événement actif : ${buildEventName(val.text)}',
          ),
        ),
        const SizedBox(height: 28),

        // Activate button
        ElevatedButton.icon(
          onPressed: onActivate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.warning_rounded),
          label: const Text('Activer la crise'),
        ),
        const SizedBox(height: 10),
        const Text(
          'Action irréversible sans confirmation – tous les centres basculent immédiatement en mode crise.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  final _EventType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeTile({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? type.color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? type.color : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(type.icon, size: 20, color: selected ? type.color : AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                type.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? type.color : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventType {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const _EventType(this.id, this.label, this.icon, this.color);
}
