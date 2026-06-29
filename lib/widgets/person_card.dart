import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/enums.dart';
import '../models/person_model.dart';
import 'status_badge.dart';

class PersonCard extends StatelessWidget {
  final PersonModel person;
  final VoidCallback? onTap;

  const PersonCard({super.key, required this.person, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _PersonAvatar(person: person),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${person.displayAge} ans',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        person.currentZone ?? 'Zone non définie',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge.fromPersonStatus(person.status),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PersonAvatar extends StatelessWidget {
  final PersonModel person;
  final double size;

  const _PersonAvatar({required this.person, this.size = 52});

  Color get _bgColor {
    if (person.status == PersonStatus.aVerifier) return AppColors.orangeLight;
    if (person.vulnerabilityFlags.contains('personne_agee')) return const Color(0xFFE8EAF6);
    if (person.vulnerabilityFlags.contains('enfant')) return const Color(0xFFE3F2FD);
    return AppColors.grayLight;
  }

  Color get _iconColor {
    if (person.status == PersonStatus.aVerifier) return AppColors.orangeText;
    if (person.vulnerabilityFlags.contains('personne_agee')) return AppColors.navy;
    if (person.vulnerabilityFlags.contains('enfant')) return AppColors.blue;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, color: _iconColor, size: size * 0.52),
    );
  }
}

Widget personAvatarCircle({required PersonModel person, double size = 52}) =>
    _PersonAvatar(person: person, size: size);
