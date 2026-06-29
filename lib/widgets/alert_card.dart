import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/alert_model.dart';
import '../models/enums.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onTreat;
  final VoidCallback? onResolve;
  final VoidCallback? onSee;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTreat,
    this.onResolve,
    this.onSee,
  });

  Color get _borderColor {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return AppColors.red;
      case AlertSeverity.warning:
        return AppColors.orange;
      case AlertSeverity.info:
        return AppColors.blue;
    }
  }

  Color get _iconBgColor {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return AppColors.redLight;
      case AlertSeverity.warning:
        return AppColors.orangeLight;
      case AlertSeverity.info:
        return AppColors.blueLight;
    }
  }

  Color get _iconColor {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return AppColors.red;
      case AlertSeverity.warning:
        return AppColors.orange;
      case AlertSeverity.info:
        return AppColors.blue;
    }
  }

  IconData get _icon {
    switch (alert.type) {
      case 'child_without_adult':
        return Icons.child_care;
      case 'medical_need':
        return Icons.medical_services_outlined;
      case 'family_separated':
        return Icons.group_off;
      case 'stock_low':
        return Icons.inventory_2_outlined;
      case 'shelter_capacity_high':
        return Icons.warning_amber;
      default:
        return Icons.warning_outlined;
    }
  }

  Color get _titleColor {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return AppColors.red;
      case AlertSeverity.warning:
        return AppColors.orange;
      case AlertSeverity.info:
        return AppColors.blue;
    }
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(alert.createdAt);
    if (diff.inMinutes < 60) {
      final h = alert.createdAt.hour.toString().padLeft(2, '0');
      final m = alert.createdAt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${diff.inHours}h';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: _borderColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (alert.location != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        alert.location!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (alert.status == AlertStatus.open && onTreat != null)
                      _ActionButton(
                        label: 'Traiter',
                        color: _borderColor,
                        onTap: onTreat!,
                      ),
                    if (alert.status == AlertStatus.inProgress && onResolve != null) ...[
                      _ActionButton(
                        label: 'Résoudre',
                        color: AppColors.green,
                        onTap: onResolve!,
                      ),
                    ],
                    if (alert.type == 'stock_low' && onSee != null)
                      _ActionButton(
                        label: 'Voir',
                        color: AppColors.blue,
                        onTap: onSee!,
                        outlined: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: outlined ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
