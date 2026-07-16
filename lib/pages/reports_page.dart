import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/enums.dart';
import '../services/app_state.dart';
import '../services/export_service.dart';
import '../core/app_routes.dart';
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
    // Échelle de l'axe calculée depuis les données réelles (pas de valeurs
    // figées) : 3 paliers ronds (ex. 0/50/100/150) couvrant maxCount.
    final axisStep = _niceStep(maxCount);
    final axisMax = axisStep * 3;

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

          // Accès analytics consolidées (commune / préfecture / cellule)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.analytics),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.navy, AppColors.blue]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.insights_outlined,
                          color: Colors.white, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Analytics consolidées',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                            Text('Synthèses multi-centres + exports',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

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
                      final pct = axisMax > 0 ? count / axisMax : 0.0;
                      final colors = [
                        AppColors.blue,
                        AppColors.green,
                        AppColors.purple
                      ];
                      final colorIdx = state.shelters.indexOf(s) % 3;
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.shelterDetail,
                            arguments: s.id),
                        child: Padding(
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
                                      duration:
                                          const Duration(milliseconds: 600),
                                      height: 10,
                                      width: constraints.maxWidth * pct,
                                      decoration: BoxDecoration(
                                          color: colors[colorIdx],
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [0, axisStep, axisStep * 2, axisStep * 3]
                          .map((v) => Text('$v',
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
                          onTap: () => _runExport(context,
                              ExportService.instance.exportComplet(state),
                              format: _ExportFormat.csv),
                        )),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _ExportBtn(
                          icon: Icons.picture_as_pdf_outlined,
                          label: 'Exporter PDF',
                          color: AppColors.red,
                          onTap: () => _runExport(context,
                              ExportService.instance.exportComplet(state),
                              format: _ExportFormat.pdf),
                        )),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _ExportBtn(
                          icon: Icons.calendar_today_outlined,
                          label: 'Synthèse jour',
                          color: AppColors.blue,
                          onTap: () => _showExportSheet(context,
                              ExportService.instance.syntheseParCentre(state)),
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
                        label: 'Synthèse par centre',
                        color: AppColors.orange,
                        onTap: () => _showExportSheet(context,
                            ExportService.instance.syntheseParCentre(state))),
                    const Divider(height: 1),
                    _ReportRow(
                        icon: Icons.location_city_outlined,
                        label: 'Synthèse par commune d\'origine',
                        color: AppColors.green,
                        onTap: () => _showExportSheet(context,
                            ExportService.instance.syntheseParCommune(state))),
                    const Divider(height: 1),
                    _ReportRow(
                        icon: Icons.warning_amber_rounded,
                        label: 'Liste des personnes non pointées',
                        color: AppColors.red,
                        onTap: () => _showExportSheet(
                            context,
                            ExportService.instance
                                .personnesNonPointees(state))),
                    const Divider(height: 1),
                    _ReportRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Liste des besoins',
                        color: AppColors.blue,
                        onTap: () => _showExportSheet(
                            context, ExportService.instance.besoins(state))),
                    const Divider(height: 1),
                    _ReportRow(
                        icon: Icons.groups_outlined,
                        label: 'Export complet (nominatif)',
                        color: AppColors.purple,
                        onTap: () => _showExportSheet(context,
                            ExportService.instance.exportComplet(state))),
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

  /// Feuille de choix du format pour un rapport donné.
  void _showExportSheet(BuildContext context, ReportTable table) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(table.title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ),
                  Text('${table.rows.length} ligne(s)',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.table_view, color: AppColors.green),
              title: const Text('Exporter en CSV'),
              subtitle: const Text('Tableur (Excel, LibreOffice…)'),
              onTap: () {
                Navigator.pop(ctx);
                _runExport(context, table, format: _ExportFormat.csv);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined,
                  color: AppColors.red),
              title: const Text('Exporter en PDF'),
              subtitle: const Text('Document partageable'),
              onTap: () {
                Navigator.pop(ctx);
                _runExport(context, table, format: _ExportFormat.pdf);
              },
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined, color: AppColors.navy),
              title: const Text('Aperçu / Imprimer'),
              onTap: () {
                Navigator.pop(ctx);
                _runExport(context, table, format: _ExportFormat.print);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _runExport(BuildContext context, ReportTable table,
      {required _ExportFormat format}) async {
    final messenger = ScaffoldMessenger.of(context);
    if (table.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Aucune donnée à exporter pour ce rapport.'),
        backgroundColor: AppColors.orange,
      ));
      return;
    }
    try {
      context.read<AppState>().auditExport(table.title, format.name);
      final svc = ExportService.instance;
      switch (format) {
        case _ExportFormat.csv:
          await svc.shareCsv(table);
          break;
        case _ExportFormat.pdf:
          await svc.sharePdf(table);
          break;
        case _ExportFormat.print:
          await svc.previewPdf(table);
          break;
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Échec de l\'export : $e'),
        backgroundColor: AppColors.red,
      ));
    }
  }

  /// Calcule un palier "rond" (1/2/5 × puissance de 10) tel que 3 paliers
  /// couvrent [maxValue]. Sert à générer une échelle d'axe qui correspond
  /// réellement aux données affichées, plutôt qu'une échelle figée.
  int _niceStep(int maxValue) {
    if (maxValue <= 0) return 1;
    final raw = maxValue / 3;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toInt();
    final residual = raw / magnitude;
    final int niceResidual;
    if (residual <= 1) {
      niceResidual = 1;
    } else if (residual <= 2) {
      niceResidual = 2;
    } else if (residual <= 5) {
      niceResidual = 5;
    } else {
      niceResidual = 10;
    }
    return niceResidual * magnitude;
  }
}

enum _ExportFormat { csv, pdf, print }

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
