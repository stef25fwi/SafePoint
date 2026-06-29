import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/enums.dart';
import '../services/app_state.dart';
import '../services/export_service.dart';
import '../widgets/app_header.dart';

/// Vue analytics agrégée, accessible aux profils commune et préfecture.
///
/// N'affiche que des indicateurs agrégés (jamais de données nominatives pour
/// la préfecture, conformément au cadrage CNIL). Les exports nominatifs ne
/// sont proposés qu'aux profils habilités (cellule de crise / admin).
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final svc = ExportService.instance;

    final everyone = state.everyPerson;
    final total = everyone.length;
    final present =
        everyone.where((p) => p.status == PersonStatus.present).length;
    final nonPointee =
        everyone.where((p) => p.status == PersonStatus.nonPointee).length;
    final besoins = state.everyOpenNeed.length;

    final parCentre = svc.syntheseParCentre(state);
    final parCommune = svc.syntheseParCommune(state);

    final canNominative = state.canSeeNominativeData;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              title: 'safepointapp.',
              subtitle: 'Analytics – ${state.activeEvent.name}',
              showBack: true,
              showNotification: false,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Indicateurs de crise',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  Text('${state.shelters.length} centres · vue consolidée',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // KPIs agrégés
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                      child: _Kpi(
                          label: 'Recensés',
                          value: total,
                          icon: Icons.groups_outlined,
                          color: AppColors.blue)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _Kpi(
                          label: 'Présents',
                          value: present,
                          icon: Icons.check_circle_outline,
                          color: AppColors.green)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _Kpi(
                          label: 'Non pointés',
                          value: nonPointee,
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.red)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _Kpi(
                          label: 'Besoins',
                          value: besoins,
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.orange)),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // Synthèse par centre
          SliverToBoxAdapter(
            child: _TableCard(
              table: parCentre,
              icon: Icons.business_outlined,
              onExport: () => _showExportSheet(context, parCentre),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // Synthèse par commune d'origine
          SliverToBoxAdapter(
            child: _TableCard(
              table: parCommune,
              icon: Icons.location_city_outlined,
              onExport: () => _showExportSheet(context, parCommune),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // Exports nominatifs (habilités uniquement)
          if (canNominative)
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
                      const Text('Exports cellule de crise',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      const Text('Données nominatives – usage habilité',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      _ExportRow(
                          icon: Icons.warning_amber_rounded,
                          label: 'Personnes non pointées',
                          color: AppColors.red,
                          onTap: () => _showExportSheet(
                              context, svc.personnesNonPointees(state))),
                      const Divider(height: 1),
                      _ExportRow(
                          icon: Icons.inventory_2_outlined,
                          label: 'Liste des besoins',
                          color: AppColors.blue,
                          onTap: () =>
                              _showExportSheet(context, svc.besoins(state))),
                      const Divider(height: 1),
                      _ExportRow(
                          icon: Icons.groups_outlined,
                          label: 'Export complet (nominatif)',
                          color: AppColors.purple,
                          onTap: () => _showExportSheet(
                              context, svc.exportComplet(state))),
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
              onTap: () {
                Navigator.pop(ctx);
                _run(context, () => ExportService.instance.shareCsv(table));
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined,
                  color: AppColors.red),
              title: const Text('Exporter en PDF'),
              onTap: () {
                Navigator.pop(ctx);
                _run(context, () => ExportService.instance.sharePdf(table));
              },
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined, color: AppColors.navy),
              title: const Text('Aperçu / Imprimer'),
              onTap: () {
                Navigator.pop(ctx);
                _run(context, () => ExportService.instance.previewPdf(table));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _run(
      BuildContext context, Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Échec de l\'export : $e'),
        backgroundColor: AppColors.red,
      ));
    }
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _Kpi(
      {required this.label,
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
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text('$value',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.1)),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final ReportTable table;
  final IconData icon;
  final VoidCallback onExport;

  const _TableCard(
      {required this.table, required this.icon, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.navy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(table.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                ),
                IconButton(
                  icon: const Icon(Icons.download_outlined,
                      size: 20, color: AppColors.navy),
                  onPressed: onExport,
                  tooltip: 'Exporter',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (table.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Aucune donnée.',
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 18,
                  headingRowHeight: 36,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 40,
                  headingTextStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                  dataTextStyle: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  columns: table.headers
                      .map((h) => DataColumn(label: Text(h)))
                      .toList(),
                  rows: table.rows
                      .map((r) => DataRow(
                          cells:
                              r.map((c) => DataCell(Text(c))).toList()))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExportRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExportRow(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
            const Icon(Icons.download_outlined,
                size: 20, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
