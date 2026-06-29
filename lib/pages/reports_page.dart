import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/enums.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allPersons = state.allPersons;
    final total = allPersons.length;
    final present =
        allPersons.where((p) => p.status == PersonStatus.present).length;
    final transferred =
        allPersons.where((p) => p.status == PersonStatus.transferee).length;
    final notChecked =
        allPersons.where((p) => p.status == PersonStatus.nonPointee).length;
    final alertCount = state.openAlerts.length;

    final shelterCounts = state.countsByShelterId;
    final maxCount = shelterCounts.values.fold(0, (a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              title: 'safepointapp.',
              subtitle: 'Centre d\'hébergement – ${state.currentShelter.name}',
              alertCount: alertCount,
            ),
          ),

          // KPI summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                      child: _ReportKpi(
                          title: 'Recensés',
                          value: '$total',
                          icon: Icons.group_outlined,
                          color: AppColors.blue)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _ReportKpi(
                          title: 'Présents',
                          value: '$present',
                          icon: Icons.person_outline,
                          color: AppColors.green)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _ReportKpi(
                          title: 'Transférés',
                          value: '$transferred',
                          icon: Icons.directions_bus,
                          color: AppColors.purple)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _ReportKpi(
                          title: 'Non pointés',
                          value: '$notChecked',
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.red)),
                ],
              ),
            ),
          ),

          // Synthèse par centre
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bar_chart, size: 18, color: AppColors.navy),
                        SizedBox(width: 8),
                        Text('Synthèse',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Personnes par centre',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 14),
                    ...state.shelters.map((s) {
                      final count = shelterCounts[s.id] ?? 0;
                      final pct = maxCount > 0 ? count / maxCount : 0.0;
                      final colors = [
                        AppColors.blue,
                        AppColors.green,
                        AppColors.purple
                      ];
                      final colorIdx = state.shelters.indexOf(s) % 3;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(s.commune,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary)),
                                ),
                                Text('$count',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LayoutBuilder(builder: (ctx, constraints) {
                              return Stack(
                                children: [
                                  Container(
                                      height: 10,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                          color: AppColors.grayLight,
                                          borderRadius:
                                              BorderRadius.circular(5))),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 600),
                                    height: 10,
                                    width: constraints.maxWidth * pct,
                                    decoration: BoxDecoration(
                                        color: colors[colorIdx],
                                        borderRadius: BorderRadius.circular(5)),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['0', '250', '500', '750']
                          .map((l) => Text(l,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary)))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // Exports rapides
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.download_outlined,
                            size: 18, color: AppColors.navy),
                        SizedBox(width: 8),
                        Text('Exports rapides',
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
                            child: _ExportBtn(
                          icon: Icons.table_view,
                          label: 'Exporter CSV',
                          color: AppColors.green,
                          onTap: () => _showExportFeedback(context, 'CSV'),
                        )),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _ExportBtn(
                          icon: Icons.picture_as_pdf_outlined,
                          label: 'Exporter PDF',
                          color: AppColors.red,
                          onTap: () => _showExportFeedback(context, 'PDF'),
                        )),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _ExportBtn(
                          icon: Icons.calendar_today_outlined,
                          label: 'Synthèse jour',
                          color: AppColors.blue,
                          onTap: () => _showExportFeedback(context, 'synthèse'),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // Rapports disponibles
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.description_outlined,
                            size: 18, color: AppColors.navy),
                        SizedBox(width: 8),
                        Text('Rapports disponibles',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ReportRow(
                        icon: Icons.business_outlined,
                        label: 'Bilan par centre',
                        color: AppColors.orange,
                        onTap: () {}),
                    const Divider(height: 1),
                    _ReportRow(
                        icon: Icons.person_outlined,
                        label: 'Liste des personnes vulnérables',
                        color: AppColors.purple,
                        onTap: () {}),
                    const Divider(height: 1),
                    _ReportRow(
                        icon: Icons.history,
                        label: 'Historique des pointages',
                        color: AppColors.blue,
                        onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _showExportFeedback(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export $type en cours de génération...'),
        backgroundColor: AppColors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ReportKpi extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ReportKpi(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(title,
              style:
                  const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.1)),
          const SizedBox(height: 4),
          Container(
              height: 3,
              width: 20,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }
}

class _ExportBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExportBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

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
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ReportRow(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
