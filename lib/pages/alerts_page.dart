import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/alert_model.dart';
import '../models/enums.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/alert_card.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<AlertModel> _getAlerts(AppState state, AlertTab tab) {
    final all = state.allAlerts;
    switch (tab) {
      case AlertTab.critical:
        return all
            .where((a) =>
                a.severity == AlertSeverity.critical &&
                a.status != AlertStatus.resolved)
            .toList();
      case AlertTab.toTreat:
        return all
            .where((a) =>
                (a.status == AlertStatus.open ||
                    a.status == AlertStatus.inProgress) &&
                a.severity != AlertSeverity.critical)
            .toList();
      case AlertTab.resolved:
        return all.where((a) => a.status == AlertStatus.resolved).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final totalOpen = state.openAlerts.length;
    final criticalCount = state.allAlerts
        .where((a) =>
            a.severity == AlertSeverity.critical &&
            a.status != AlertStatus.resolved)
        .length;
    final inProgressCount =
        state.allAlerts.where((a) => a.status == AlertStatus.inProgress).length;
    final needsCount = state.currentNeeds.length;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          AppHeader(
            title: 'safepointapp.',
            subtitle: 'Centre d\'hébergement – ${state.currentShelter.name}',
            alertCount: totalOpen,
          ),

          // Title + badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Alertes et besoins urgents',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('$totalOpen alertes',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: AppColors.bgPage,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_rounded,
                            size: 16, color: AppColors.red),
                        SizedBox(width: 4),
                        Text('Critiques'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 16, color: AppColors.orange),
                        SizedBox(width: 4),
                        Text('À traiter'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 16, color: AppColors.green),
                        SizedBox(width: 4),
                        Text('Résolues'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Summary KPIs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _AlertKpi(
                    icon: Icons.warning_rounded,
                    label: 'Critiques',
                    value: criticalCount,
                    color: AppColors.red),
                const SizedBox(width: 10),
                _AlertKpi(
                    icon: Icons.schedule,
                    label: 'En cours',
                    value: inProgressCount,
                    color: AppColors.orange),
                const SizedBox(width: 10),
                _AlertKpi(
                    icon: Icons.inventory_2_outlined,
                    label: 'Besoins',
                    value: needsCount,
                    color: AppColors.blue),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: AlertTab.values.map((tab) {
                final alerts = _getAlerts(state, tab);
                if (alerts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            tab == AlertTab.resolved
                                ? Icons.check_circle_outline
                                : Icons.notifications_off_outlined,
                            size: 48,
                            color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text(
                          tab == AlertTab.resolved
                              ? 'Aucune alerte résolue'
                              : 'Aucune alerte',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => AlertCard(
                    alert: alerts[i],
                    onTreat: alerts[i].status == AlertStatus.open &&
                            state.canResolveAlerts
                        ? () => state.markAlertInProgress(alerts[i].id)
                        : null,
                    onResolve: alerts[i].status == AlertStatus.inProgress &&
                            state.canResolveAlerts
                        ? () => state.resolveAlert(alerts[i].id)
                        : null,
                    onSee: alerts[i].type == 'stock_low' ? () {} : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertKpi extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _AlertKpi(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                Text('$value',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                        height: 1.1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
