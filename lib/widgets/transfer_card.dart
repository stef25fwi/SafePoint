import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/transfer_model.dart';
import '../models/enums.dart';
import 'status_badge.dart';

class TransferCard extends StatelessWidget {
  final TransferModel transfer;
  final VoidCallback? onConfirmArrival;
  final VoidCallback? onMarkDeparted;

  const TransferCard({
    super.key,
    required this.transfer,
    this.onConfirmArrival,
    this.onMarkDeparted,
  });

  IconData get _icon {
    switch (transfer.status) {
      case TransferStatus.pending:
        return Icons.schedule;
      case TransferStatus.inProgress:
        return Icons.directions_bus;
      case TransferStatus.confirmed:
        return Icons.check_circle;
      case TransferStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color get _iconColor {
    switch (transfer.status) {
      case TransferStatus.pending:
        return AppColors.orange;
      case TransferStatus.inProgress:
        return AppColors.blue;
      case TransferStatus.confirmed:
        return AppColors.green;
      case TransferStatus.cancelled:
        return AppColors.grayText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: _iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  transfer.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusBadge.fromTransferStatus(transfer.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Origine',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.business,
                            size: 14, color: _iconColor.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            transfer.fromShelterName,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward,
                    size: 18, color: AppColors.textSecondary),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Destination',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.business,
                            size: 14,
                            color: AppColors.green.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            transfer.toShelterName,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                transfer.departedAt != null
                    ? 'Départ : Aujourd\'hui • ${fmt.format(transfer.departedAt!)}'
                    : transfer.departurePlannedAt != null
                        ? 'Départ prévu : Aujourd\'hui • ${fmt.format(transfer.departurePlannedAt!)}'
                        : 'Heure non définie',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          if (transfer.arrivalConfirmedAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 14, color: AppColors.green),
                const SizedBox(width: 4),
                Text(
                  'Arrivée confirmée • ${fmt.format(transfer.arrivalConfirmedAt!)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.green),
                ),
              ],
            ),
          ],
          if (transfer.status == TransferStatus.inProgress &&
              onConfirmArrival != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onConfirmArrival,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  side: const BorderSide(color: AppColors.blue),
                  foregroundColor: AppColors.blue,
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('Confirmer l\'arrivée'),
              ),
            ),
          ],
          if (transfer.status == TransferStatus.pending &&
              onMarkDeparted != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onMarkDeparted,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  backgroundColor: AppColors.blue,
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('Marquer départ'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
