import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_routes.dart';
import '../models/checkin_model.dart';
import '../models/enums.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/crisis_banner.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_header.dart';
import 'main_shell_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final shelter = state.currentShelter;
    final persons = state.allPersons;
    final presentCount = persons.where((p) => p.status == PersonStatus.present).length;
    final alertCount = state.openAlerts.length;
    final familyCount = state.currentFamilies.length;
    final needs = state.currentNeeds;
    final recentCheckins = state.recentCheckins.take(3).toList();

    // Indicators – situations requiring attention
    final nonPointeeCount = persons.where((p) => p.status == PersonStatus.nonPointee).length;
    final sansTelCount = persons.where((p) => p.phone == null).length;
    final sansPapiersCount = persons.where((p) => p.vulnerabilityFlags.contains('sans_papiers')).length;
    final ageesSeulCount = persons.where((p) => p.vulnerabilityFlags.contains('personne_agee') && p.familyId == null).length;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (state.isOffline) const _OfflineBannerSimple(),
                AppHeader(
                  title: 'safepointapp.',
                  subtitle: 'Centre d\'hébergement – ${shelter.name}',
                  alertCount: alertCount,
                  onNotificationTap: () => _goToAlerts(context),
                ),
                CrisisBanner(label: 'Événement actif : ${state.activeEvent.name}'),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // KPI cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: KpiCard(
                    title: 'Présents',
                    value: '$presentCount',
                    icon: Icons.group_outlined,
                    color: AppColors.blue,
                    onTap: () => _goToPersons(context),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: KpiCard(
                    title: 'Places restantes',
                    value: '${shelter.placesRestantes}',
                    icon: Icons.bed_outlined,
                    color: AppColors.green,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: KpiCard(
                    title: 'Familles',
                    value: '$familyCount',
                    icon: Icons.family_restroom,
                    color: AppColors.purple,
                    onTap: () => _goToFamilies(context),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: KpiCard(
                    title: 'Alertes',
                    value: '$alertCount',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.red,
                    onTap: () => _goToAlerts(context),
                  )),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Crisis management — préfecture / admin only
          if (state.canActivateCrisis)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _CrisisManagementCard(
                  isActive: state.isCrisisActive,
                  eventName: state.activeEvent.name,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.crisisActivation),
                ),
              ),
            ),
          if (state.canActivateCrisis)
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Pointage rapide — hidden for prefectureLecture
          if (state.canCheckIn)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
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
                          Icon(Icons.qr_code_scanner, size: 20, color: AppColors.navy),
                          SizedBox(width: 8),
                          Text('Pointage rapide', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _QuickAction(
                            icon: Icons.qr_code_scanner,
                            label: 'Scanner QR',
                            onTap: () => _goToScanner(context),
                          )),
                          if (state.canCreatePerson) ...[
                            const SizedBox(width: 10),
                            Expanded(child: _QuickAction(
                              icon: Icons.person_add_alt_1,
                              label: 'Ajouter\nune personne',
                              onTap: () => Navigator.pushNamed(context, AppRoutes.personForm),
                            )),
                          ],
                          const SizedBox(width: 10),
                          Expanded(child: _QuickAction(
                            icon: Icons.groups,
                            label: 'Pointer un\ngroupe',
                            onTap: () => _goToFamilies(context),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Situations à surveiller
          if (nonPointeeCount + sansTelCount + sansPapiersCount + ageesSeulCount > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 20, color: AppColors.orange),
                          SizedBox(width: 8),
                          Text('Situations à surveiller', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (nonPointeeCount > 0)
                        _AlertIndicator(icon: Icons.person_off_outlined, label: 'Non pointé(e)s', count: nonPointeeCount, color: AppColors.grayText, bgColor: AppColors.grayLight),
                      if (sansTelCount > 0)
                        _AlertIndicator(icon: Icons.phone_disabled_outlined, label: 'Sans téléphone', count: sansTelCount, color: AppColors.blueText, bgColor: AppColors.blueLight),
                      if (sansPapiersCount > 0)
                        _AlertIndicator(icon: Icons.badge_outlined, label: 'Sans papiers d\'identité', count: sansPapiersCount, color: AppColors.orangeText, bgColor: AppColors.orangeLight),
                      if (ageesSeulCount > 0)
                        _AlertIndicator(icon: Icons.elderly_outlined, label: 'Personnes âgées seules', count: ageesSeulCount, color: AppColors.purpleText, bgColor: AppColors.purpleLight),
                    ],
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Besoins urgents
          if (needs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SectionHeader(
                        icon: Icons.inventory_2_outlined,
                        title: 'Besoins urgents',
                        iconColor: AppColors.orange,
                        actionLabel: 'Voir tout',
                        onAction: () => _goToAlerts(context),
                      ),
                      const SizedBox(height: 12),
                      ...needs.map((n) => _NeedRow(
                        icon: _needIcon(n.type),
                        label: n.type.label,
                        count: needs.where((x) => x.type == n.type).length,
                        urgent: n.urgency == 'critical',
                      )).toSet(),
                    ],
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Activité récente
          if (recentCheckins.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SectionHeader(
                        icon: Icons.access_time_filled,
                        title: 'Activité récente',
                        actionLabel: 'Voir tout',
                        iconColor: AppColors.navy,
                      ),
                      const SizedBox(height: 12),
                      ...recentCheckins.map((c) => _ActivityRow(checkin: c, state: state)),
                    ],
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Capacité centre
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.shelterDetail, arguments: shelter.id),
                child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bar_chart, size: 20, color: AppColors.navy),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Capacité du centre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                        Text(
                          '${shelter.currentCount} / ${shelter.capacity}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: shelter.capacityPercent,
                        backgroundColor: AppColors.divider,
                        color: shelter.capacityPercent > 0.9 ? AppColors.red : AppColors.blue,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(shelter.capacityPercent * 100).toStringAsFixed(0)} % de capacité utilisée',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  IconData _needIcon(NeedType type) {
    switch (type) {
      case NeedType.medical: return Icons.medical_services_outlined;
      case NeedType.babyKit: return Icons.child_friendly_outlined;
      case NeedType.blanket: return Icons.airline_seat_flat_angled;
      case NeedType.water: return Icons.water_drop_outlined;
      case NeedType.food: return Icons.restaurant_outlined;
      case NeedType.animal: return Icons.pets_outlined;
      default: return Icons.inventory_2_outlined;
    }
  }

  void _goToAlerts(BuildContext context) {
    final shell = context.findAncestorStateOfType<MainShellPageState>();
    shell?.setTab(3);
  }

  void _goToPersons(BuildContext context) {
    final shell = context.findAncestorStateOfType<MainShellPageState>();
    shell?.setTab(1);
  }

  void _goToScanner(BuildContext context) {
    final shell = context.findAncestorStateOfType<MainShellPageState>();
    shell?.setTab(2);
  }

  void _goToFamilies(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.families);
  }
}

class _AlertIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final Color bgColor;

  const _AlertIndicator({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
          Text('$count', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _OfflineBannerSimple extends StatelessWidget {
  const _OfflineBannerSimple();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFFF59E0B),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 14),
          SizedBox(width: 6),
          Text('Mode hors connexion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgPage,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.navy, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool urgent;

  const _NeedRow({required this.icon, required this.label, required this.count, required this.urgent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.orangeLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.orange, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: urgent ? AppColors.orange : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final CheckinModel checkin;
  final AppState state;

  const _ActivityRow({required this.checkin, required this.state});

  @override
  Widget build(BuildContext context) {
    final person = state.getPersonById(checkin.personId);
    final family = checkin.familyId != null ? state.getFamilyById(checkin.familyId!) : null;
    final h = checkin.createdAt.hour.toString().padLeft(2, '0');
    final m = checkin.createdAt.minute.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(person?.fullName, family?.displayName),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                if (person != null)
                  Text(
                    person.currentZone ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          Text('$h:$m', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  String _title(String? personName, String? familyName) {
    switch (checkin.type) {
      case CheckinType.arrival:
        return familyName != null ? 'Arrivée de $familyName' : 'Arrivée de ${personName ?? "inconnu"}';
      case CheckinType.mealBreakfast:
        return 'Pointage repas – Petit-déjeuner';
      case CheckinType.mealLunch:
        return 'Pointage repas – Déjeuner';
      case CheckinType.mealDinner:
        return 'Pointage repas – Dîner';
      case CheckinType.transferDeparture:
        return 'Transfert vers Centre de Capesterre';
      case CheckinType.presence:
        return 'Présence confirmée – ${personName ?? ""}';
      case CheckinType.medical:
        return 'Passage infirmerie – ${personName ?? ""}';
      default:
        return checkin.type.label;
    }
  }

  Color get _iconBg {
    switch (checkin.type) {
      case CheckinType.arrival: return AppColors.greenLight;
      case CheckinType.mealBreakfast:
      case CheckinType.mealLunch:
      case CheckinType.mealDinner: return AppColors.orangeLight;
      case CheckinType.transferDeparture: return AppColors.blueLight;
      default: return AppColors.grayLight;
    }
  }

  Color get _iconColor {
    switch (checkin.type) {
      case CheckinType.arrival: return AppColors.green;
      case CheckinType.mealBreakfast:
      case CheckinType.mealLunch:
      case CheckinType.mealDinner: return AppColors.orange;
      case CheckinType.transferDeparture: return AppColors.blue;
      default: return AppColors.grayText;
    }
  }

  IconData get _icon {
    switch (checkin.type) {
      case CheckinType.arrival: return Icons.group;
      case CheckinType.mealBreakfast:
      case CheckinType.mealLunch:
      case CheckinType.mealDinner: return Icons.restaurant_outlined;
      case CheckinType.transferDeparture: return Icons.directions_bus;
      default: return Icons.check_circle_outline;
    }
  }
}

class _CrisisManagementCard extends StatelessWidget {
  final bool isActive;
  final String eventName;
  final VoidCallback onTap;

  const _CrisisManagementCard({
    required this.isActive,
    required this.eventName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.red : AppColors.navy;
    final bg = isActive ? AppColors.redLight : AppColors.bgPage;
    final borderColor = isActive ? AppColors.red.withValues(alpha: 0.35) : AppColors.divider;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isActive ? 1.5 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.warning_rounded : Icons.emergency_outlined,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Crise active' : 'Aucun événement actif',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive ? eventName : 'Activer un événement de crise',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
