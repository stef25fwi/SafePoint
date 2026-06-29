import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/enums.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;
  final bool outlined;

  const StatusBadge({
    super.key,
    required this.label,
    required this.textColor,
    required this.bgColor,
    this.outlined = false,
  });

  factory StatusBadge.fromPersonStatus(PersonStatus status) {
    switch (status) {
      case PersonStatus.present:
        return const StatusBadge(
          label: 'Présent(e)',
          textColor: AppColors.greenText,
          bgColor: AppColors.greenLight,
        );
      case PersonStatus.nonPointee:
        return const StatusBadge(
          label: 'Non pointé(e)',
          textColor: AppColors.grayText,
          bgColor: AppColors.grayLight,
        );
      case PersonStatus.aVerifier:
        return const StatusBadge(
          label: 'Suivi requis',
          textColor: AppColors.orangeText,
          bgColor: AppColors.orangeLight,
        );
      case PersonStatus.transfertEnAttente:
        return const StatusBadge(
          label: 'Transfert en attente',
          textColor: AppColors.blueText,
          bgColor: AppColors.blueLight,
          outlined: true,
        );
      case PersonStatus.transfertEnCours:
        return const StatusBadge(
          label: 'Transfert en cours',
          textColor: AppColors.blueText,
          bgColor: AppColors.blueLight,
        );
      case PersonStatus.transferee:
        return const StatusBadge(
          label: 'Transféré(e)',
          textColor: AppColors.purpleText,
          bgColor: AppColors.purpleLight,
        );
      case PersonStatus.sortieTemporaire:
        return const StatusBadge(
          label: 'Sortie temp.',
          textColor: AppColors.orangeText,
          bgColor: AppColors.orangeLight,
        );
      case PersonStatus.sortieDefinitive:
        return const StatusBadge(
          label: 'Sorti(e)',
          textColor: AppColors.grayText,
          bgColor: AppColors.grayLight,
        );
      case PersonStatus.hospitalisee:
        return const StatusBadge(
          label: 'Hospitalisé(e)',
          textColor: AppColors.redText,
          bgColor: AppColors.redLight,
        );
    }
  }

  factory StatusBadge.fromTransferStatus(TransferStatus status) {
    switch (status) {
      case TransferStatus.pending:
        return const StatusBadge(
          label: 'En attente',
          textColor: AppColors.orangeText,
          bgColor: AppColors.orangeLight,
        );
      case TransferStatus.inProgress:
        return const StatusBadge(
          label: 'En cours',
          textColor: AppColors.blueText,
          bgColor: AppColors.blueLight,
        );
      case TransferStatus.confirmed:
        return const StatusBadge(
          label: 'Confirmé',
          textColor: AppColors.greenText,
          bgColor: AppColors.greenLight,
        );
      case TransferStatus.cancelled:
        return const StatusBadge(
          label: 'Annulé',
          textColor: AppColors.grayText,
          bgColor: AppColors.grayLight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: outlined
            ? Border.all(color: textColor.withValues(alpha: 0.4))
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class FamilyStatusBadge extends StatelessWidget {
  final bool isSeparated;
  final bool isToVerify;

  const FamilyStatusBadge({
    super.key,
    this.isSeparated = false,
    this.isToVerify = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSeparated) {
      return const StatusBadge(
        label: 'Séparée',
        textColor: AppColors.orangeText,
        bgColor: AppColors.orangeLight,
      );
    }
    if (isToVerify) {
      return const StatusBadge(
        label: 'À vérifier',
        textColor: Color(0xFFD97706),
        bgColor: Color(0xFFFEF3C7),
      );
    }
    return const StatusBadge(
      label: 'Complète',
      textColor: AppColors.greenText,
      bgColor: AppColors.greenLight,
    );
  }
}
