import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Résultat du sélecteur de lieu : distingue « validé sans précision »
/// (zone null) d'une annulation pure (le showModalBottomSheet renvoie null).
class ZoneSelection {
  final String? zone;
  const ZoneSelection(this.zone);
}

/// Popup de sélection du lieu de pointage dans le centre (dortoir, zone
/// repas…). Renvoie null si l'agent annule, ZoneSelection(zone) sinon —
/// zone null signifiant « sans précision ».
Future<ZoneSelection?> showZonePicker(
  BuildContext context, {
  required List<String> zones,
  required String actionLabel,
}) {
  return showModalBottomSheet<ZoneSelection>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.bgPage,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_outlined, color: AppColors.navy, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lieu du pointage – $actionLabel',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Où se trouve la personne dans le centre ?',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final zone in zones)
                    _ZoneChip(
                      label: zone,
                      onTap: () => Navigator.pop(ctx, ZoneSelection(zone)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(ctx, const ZoneSelection(null)),
              icon: const Icon(Icons.location_off_outlined, size: 18),
              label: const Text('Pointer sans préciser le lieu'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ZoneChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ZoneChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place, size: 15, color: AppColors.blue),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
