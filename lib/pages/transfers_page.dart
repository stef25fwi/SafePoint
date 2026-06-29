import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_routes.dart';
import '../models/enums.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/transfer_card.dart';

class TransfersPage extends StatefulWidget {
  const TransfersPage({super.key});

  @override
  State<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends State<TransfersPage> {
  TransferStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = state.currentTransfers;

    final filtered = _filter == null ? all : all.where((t) => t.status == _filter).toList();
    final pendingCount = all.where((t) => t.status == TransferStatus.pending).length;
    final inProgressCount = all.where((t) => t.status == TransferStatus.inProgress).length;
    final confirmedCount = all.where((t) => t.status == TransferStatus.confirmed).length;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          AppHeader(
            title: 'safepoint.app',
            subtitle: 'Centre d\'hébergement – ${state.currentShelter.name}',
            showBack: true,
            alertCount: state.openAlerts.length,
          ),

          // Title
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Icon(Icons.swap_horiz, size: 26, color: AppColors.navy),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transferts inter-centres', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('Suivi des départs et arrivées', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Status KPIs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _StatusKpi(
                  icon: Icons.schedule,
                  label: 'En attente',
                  value: pendingCount,
                  color: AppColors.orange,
                  selected: _filter == TransferStatus.pending,
                  onTap: () => setState(() => _filter = _filter == TransferStatus.pending ? null : TransferStatus.pending),
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatusKpi(
                  icon: Icons.directions_bus,
                  label: 'En cours',
                  value: inProgressCount,
                  color: AppColors.blue,
                  selected: _filter == TransferStatus.inProgress,
                  onTap: () => setState(() => _filter = _filter == TransferStatus.inProgress ? null : TransferStatus.inProgress),
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatusKpi(
                  icon: Icons.check_circle_outline,
                  label: 'Confirmés',
                  value: confirmedCount,
                  color: AppColors.green,
                  selected: _filter == TransferStatus.confirmed,
                  onTap: () => setState(() => _filter = _filter == TransferStatus.confirmed ? null : TransferStatus.confirmed),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Create button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.createTransfer),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Créer un transfert'),
            ),
          ),
          const SizedBox(height: 12),

          // List
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Transferts récents',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Aucun transfert', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => TransferCard(
                      transfer: filtered[i],
                      onConfirmArrival: filtered[i].status == TransferStatus.inProgress
                          ? () => state.confirmTransferArrival(filtered[i].id)
                          : null,
                      onMarkDeparted: filtered[i].status == TransferStatus.pending
                          ? () => state.markTransferDeparted(filtered[i].id)
                          : null,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusKpi extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusKpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppColors.divider, width: selected ? 1.5 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color, height: 1.1)),
          ],
        ),
      ),
    );
  }
}
