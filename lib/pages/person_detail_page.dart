import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../core/app_routes.dart';
import '../models/checkin_model.dart';
import '../models/enums.dart';
import '../models/need_model.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/status_badge.dart';

class PersonDetailPage extends StatefulWidget {
  const PersonDetailPage({super.key});

  @override
  State<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends State<PersonDetailPage> {
  bool _audited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_audited) {
      _audited = true;
      final personId = ModalRoute.of(context)!.settings.arguments as String;
      // Traçabilité RGPD : consultation d'une fiche nominative.
      context.read<AppState>().auditNominativeAccess('person', personId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final personId = ModalRoute.of(context)!.settings.arguments as String;
    final state = context.watch<AppState>();
    final person = state.getPersonById(personId);

    if (person == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fiche personne')),
        body: const Center(child: Text('Personne introuvable')),
      );
    }

    final checkins = state.getPersonCheckins(personId);
    final alerts = state.getPersonAlerts(personId);
    final dynamicNeeds = state.getPersonNeeds(personId);
    final family =
        person.familyId != null ? state.getFamilyById(person.familyId!) : null;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              title: 'safepointapp.',
              subtitle: 'Centre d\'hébergement – ${state.currentShelter.name}',
              showBack: true,
              alertCount:
                  alerts.where((a) => a.status != AlertStatus.resolved).length,
            ),
          ),
          // Person hero
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: person.isVulnerable
                          ? AppColors.orangeLight
                          : AppColors.blueLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 36,
                      color: person.isVulnerable
                          ? AppColors.orangeText
                          : AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.fullName,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                        ),
                        Text(
                          '${person.displayAge} ans – ${person.currentZone ?? "Zone non définie"}',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.fromPersonStatus(person.status),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Profile summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Card(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_outlined,
                          size: 18, color: AppColors.blue),
                      SizedBox(width: 8),
                      Text('Résumé du profil',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ProfileRow(
                    icon: Icons.location_on_outlined,
                    label: 'Commune d\'origine',
                    value: person.originCommune ?? 'Non renseignée',
                    color: AppColors.blue,
                  ),
                  if (person.phone != null)
                    _ProfileRow(
                      icon: Icons.phone_outlined,
                      label: 'Contact',
                      value: person.phone!,
                      color: AppColors.green,
                    ),
                  _ProfileRow(
                    icon: Icons.family_restroom,
                    label: 'Groupe familial',
                    value: family?.displayName ?? 'Aucun',
                    color: AppColors.purple,
                    onTap: family != null
                        ? () => Navigator.pushNamed(context, AppRoutes.families)
                        : null,
                  ),
                  _ProfileRow(
                    icon: Icons.business_outlined,
                    label: 'Zone du centre',
                    value: person.currentZone ?? 'Non définie',
                    color: AppColors.navy,
                    isChip: true,
                    chipText: person.currentZone,
                  ),
                  if (person.vulnerabilityFlags.isNotEmpty ||
                      person.needFlags.isNotEmpty ||
                      dynamicNeeds.isNotEmpty)
                    _ProfileRowNeeds(
                      icon: Icons.favorite_outline,
                      label: 'Besoins',
                      vulnerabilities: person.vulnerabilityFlags,
                      needs: [
                        ...person.needFlags,
                        ...dynamicNeeds.map((n) => n.type)
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // Checkin history
          if (checkins.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _Card(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.access_time_filled,
                            size: 18, color: AppColors.navy),
                        SizedBox(width: 8),
                        Text('Historique de pointage',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...checkins.take(5).map((c) => _CheckinRow(checkin: c)),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Card(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt, size: 18, color: AppColors.navy),
                      SizedBox(width: 8),
                      Text('Actions rapides',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.how_to_reg,
                          label: 'Pointer présence',
                          color: AppColors.blue,
                          onTap: () {
                            context.read<AppState>().createCheckin(
                                personId: personId, type: CheckinType.presence);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Présence enregistrée'),
                                  backgroundColor: AppColors.green),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.swap_horiz,
                          label: 'Transférer',
                          color: AppColors.green,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.createTransfer,
                              arguments: [personId]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.add_circle_outline,
                          label: 'Ajouter un besoin',
                          color: AppColors.purple,
                          onTap: () => _showAddNeedDialog(context, personId),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.phone_outlined,
                          label: 'Contacter famille',
                          color: AppColors.navy,
                          onTap: person.phone != null
                              ? () => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text(
                                          'Appel vers ${person.phone}...')))
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _showAddNeedDialog(BuildContext context, String personId) {
    NeedType? selected;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un besoin'),
        content: StatefulBuilder(
          builder: (ctx, setSt) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NeedType.values
                .map((t) => GestureDetector(
                      onTap: () => setSt(() => selected = t),
                      child: Chip(
                        label: Text(t.label),
                        backgroundColor:
                            selected == t ? AppColors.blueLight : null,
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: selected == null
                ? null
                : () {
                    final state = context.read<AppState>();
                    state.addNeed(NeedModel(
                      id: 'need_${DateTime.now().millisecondsSinceEpoch}',
                      eventId: 'event_1',
                      shelterId: state.currentShelterId,
                      personId: personId,
                      type: selected!,
                      urgency: 'medium',
                      status: 'open',
                      createdAt: DateTime.now(),
                    ));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Besoin ajouté'),
                          backgroundColor: AppColors.green),
                    );
                  },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isChip;
  final String? chipText;
  final VoidCallback? onTap;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isChip = false,
    this.chipText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary))),
          GestureDetector(
            onTap: onTap,
            child: isChip && chipText != null
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(chipText!,
                        style: const TextStyle(
                            color: AppColors.greenText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: onTap != null
                          ? AppColors.blue
                          : AppColors.textPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRowNeeds extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> vulnerabilities;
  final List<NeedType> needs;

  const _ProfileRowNeeds({
    required this.icon,
    required this.label,
    required this.vulnerabilities,
    required this.needs,
  });

  @override
  Widget build(BuildContext context) {
    final chips = [
      ...vulnerabilities.map((v) => _vulnLabel(v)),
      ...needs.map((n) => n.label),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.orange),
          const SizedBox(width: 12),
          const Text('Besoins',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const Spacer(),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.end,
            children: chips
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orangeLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(c,
                          style: const TextStyle(
                              color: AppColors.orangeText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  String _vulnLabel(String flag) {
    switch (flag) {
      case 'enfant':
        return 'Enfant';
      case 'personne_agee':
        return 'Pers. âgée';
      case 'pmr':
        return 'PMR';
      case 'grossesse':
        return 'Grossesse';
      case 'medical':
        return 'Médical';
      default:
        return flag;
    }
  }
}

class _CheckinRow extends StatelessWidget {
  final CheckinModel checkin;
  const _CheckinRow({required this.checkin});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
                color: AppColors.blue, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(checkin.type.label,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary))),
          Text(fmt.format(checkin.createdAt),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withValues(alpha: 0.08)
              : AppColors.grayLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: onTap != null
                  ? color.withValues(alpha: 0.3)
                  : AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: onTap != null ? color : AppColors.grayText, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: onTap != null ? color : AppColors.grayText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
