import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import '../models/enums.dart';
import '../models/transfer_model.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/departure_dialog.dart';
import '../widgets/status_badge.dart';

/// Fiche d'un transfert : origine/destination, convoi (véhicule +
/// chauffeur joignable), chronologie des états et personnes concernées.
/// Ouverte depuis la liste des transferts ou la notification « transfert
/// entrant » du centre destinataire.
class TransferDetailPage extends StatelessWidget {
  const TransferDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final transferId = ModalRoute.of(context)!.settings.arguments as String;
    final state = context.watch<AppState>();
    final transfer = state.getTransferById(transferId);

    if (transfer == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgPage,
        body: Column(
          children: [
            AppHeader(
              title: 'safepointapp.',
              subtitle: 'Transfert',
              showBack: true,
              showNotification: false,
            ),
            Expanded(
              child: Center(child: Text('Transfert introuvable')),
            ),
          ],
        ),
      );
    }

    final fmt = DateFormat('dd/MM • HH:mm');
    final persons = transfer.personIds
        .map(state.getPersonById)
        .where((p) => p != null)
        .toList();
    final isDestination = transfer.toShelterId == state.currentShelterId;
    final canAct = state.canValidateTransfers;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          AppHeader(
            title: 'safepointapp.',
            subtitle: 'Transfert – ${transfer.displayName}',
            showBack: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Statut + trajet
                _Card(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Statut du transfert',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                        ),
                        StatusBadge.fromTransferStatus(transfer.status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _Endpoint(
                            label: 'Origine',
                            name: transfer.fromShelterName,
                            color: AppColors.orange,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward,
                              size: 20, color: AppColors.textSecondary),
                        ),
                        Expanded(
                          child: _Endpoint(
                            label: 'Destination',
                            name: transfer.toShelterName,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Convoi (véhicule + chauffeur)
                _Card(
                  children: [
                    const _CardTitle(
                        icon: Icons.local_shipping_outlined, text: 'Convoi'),
                    const SizedBox(height: 12),
                    if (transfer.status == TransferStatus.pending)
                      const Text(
                        'Les informations du convoi seront renseignées au '
                        'départ du transfert.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      )
                    else ...[
                      _InfoRow(
                        icon: Icons.directions_bus_outlined,
                        label: 'Transport',
                        value: transfer.transportMode ?? 'Non précisé',
                      ),
                      _InfoRow(
                        icon: Icons.pin_outlined,
                        label: 'Immatriculation',
                        value: transfer.vehicleRegistration ?? 'Non précisée',
                      ),
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Chauffeur',
                        value: transfer.driverName ?? 'Non précisé',
                      ),
                      if (transfer.driverPhone != null)
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Téléphone',
                          value: transfer.driverPhone!,
                          onTap: () => _call(transfer.driverPhone!),
                          actionIcon: Icons.call,
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // Chronologie
                _Card(
                  children: [
                    const _CardTitle(icon: Icons.timeline, text: 'Chronologie'),
                    const SizedBox(height: 12),
                    _TimelineStep(
                      done: true,
                      label: 'Transfert créé',
                      time: fmt.format(transfer.createdAt),
                    ),
                    _TimelineStep(
                      done: transfer.departedAt != null,
                      label: 'Départ du convoi',
                      time: transfer.departedAt != null
                          ? fmt.format(transfer.departedAt!)
                          : 'En attente',
                    ),
                    _TimelineStep(
                      done: transfer.arrivalConfirmedAt != null,
                      label: 'Arrivée confirmée',
                      time: transfer.arrivalConfirmedAt != null
                          ? fmt.format(transfer.arrivalConfirmedAt!)
                          : 'En attente',
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Personnes
                _Card(
                  children: [
                    _CardTitle(
                        icon: Icons.people_outline,
                        text: 'Personnes (${persons.length})'),
                    const SizedBox(height: 4),
                    ...persons.map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.person,
                                  size: 18, color: AppColors.blue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(p!.fullName,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary)),
                              ),
                              StatusBadge.fromPersonStatus(p.status),
                            ],
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 20),

                // Actions
                if (canAct && transfer.status == TransferStatus.pending) ...[
                  ElevatedButton.icon(
                    onPressed: () => _markDeparted(context, transfer),
                    icon: const Icon(Icons.local_shipping),
                    label: const Text('Marquer le départ'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                  ),
                ],
                if (canAct && transfer.status == TransferStatus.inProgress) ...[
                  ElevatedButton.icon(
                    onPressed: () => state.confirmTransferArrival(transfer.id),
                    icon: const Icon(Icons.check_circle),
                    label: Text(isDestination
                        ? 'Confirmer la réception'
                        : 'Confirmer l\'arrivée'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.green),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markDeparted(
      BuildContext context, TransferModel transfer) async {
    final state = context.read<AppState>();
    final info = await showDepartureDialog(context);
    if (info == null) return;
    state.markTransferDeparted(
      transfer.id,
      transportMode: info.transportMode,
      vehicleRegistration: info.vehicleRegistration,
      driverName: info.driverName,
      driverPhone: info.driverPhone,
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  const _CardTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.navy),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

class _Endpoint extends StatelessWidget {
  final String label;
  final String name;
  final Color color;
  const _Endpoint(
      {required this.label, required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.business, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final IconData? actionIcon;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text('$label : ',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
          if (onTap != null && actionIcon != null)
            IconButton(
              onPressed: onTap,
              icon: Icon(actionIcon, size: 20, color: AppColors.green),
              tooltip: 'Appeler',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final bool done;
  final String label;
  final String time;
  final bool isLast;

  const _TimelineStep({
    required this.done,
    required this.label,
    required this.time,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.green : AppColors.divider;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 20, color: done ? AppColors.green : AppColors.textHint),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: color),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: done
                            ? AppColors.textPrimary
                            : AppColors.textSecondary)),
                Text(time,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
