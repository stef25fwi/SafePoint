import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/enums.dart';
import '../models/shelter_model.dart';
import '../models/stock_entry_model.dart';
import '../models/stock_transfer_model.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/stock_entry_form.dart';
import '../widgets/stock_transfer_form.dart';

// ── Stock item descriptor ─────────────────────────────────────────────────────

class _StockItem {
  final String key;
  final String label;
  final IconData icon;
  final String unit;
  final int minThreshold;

  const _StockItem(this.key, this.label, this.icon, this.unit,
      this.minThreshold);
}

const _stockItems = [
  _StockItem('eau', 'Eau', Icons.water_drop, 'litres', 200),
  _StockItem('repas', 'Repas', Icons.restaurant, 'portions', 50),
  _StockItem('couvertures', 'Couvertures', Icons.airline_seat_flat_angled, '', 30),
  _StockItem('lits', 'Lits', Icons.bed, '', 20),
  _StockItem('masques', 'Masques', Icons.masks, '', 50),
  _StockItem('couches', 'Couches', Icons.child_care, '', 20),
  _StockItem('medicaments', 'Médicaments d\'urgence', Icons.medical_services, 'kits', 5),
];

const _presetZones = [
  'Dortoir A', 'Dortoir B', 'Dortoir C',
  'Espace familles', 'Zone PMR', 'Infirmerie',
  'Zone animaux', 'Zone repas', 'Cuisine',
  'Sanitaires', 'Accueil', 'Administration',
];

// ── Page ──────────────────────────────────────────────────────────────────────

class ShelterDetailPage extends StatefulWidget {
  const ShelterDetailPage({super.key});

  @override
  State<ShelterDetailPage> createState() => _ShelterDetailPageState();
}

class _ShelterDetailPageState extends State<ShelterDetailPage> {
  final _zoneCtrl = TextEditingController();
  final _agentCtrl = TextEditingController();

  @override
  void dispose() {
    _zoneCtrl.dispose();
    _agentCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final shelterId =
        ModalRoute.of(context)!.settings.arguments as String;
    final state = context.watch<AppState>();
    final shelter = state.shelters.firstWhere((s) => s.id == shelterId);
    final canEdit = state.canEditShelter;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        body: Column(
          children: [
            AppHeader(
              title: 'safepointapp.',
              subtitle: shelter.commune,
              showBack: true,
              alertCount: state.openAlerts.length,
            ),

            // Shelter header card
            _ShelterHeaderCard(
              shelter: shelter,
              canEdit: canEdit,
              onStatusChange: (s) =>
                  state.updateShelterStatus(shelterId, s),
            ),

            // Tab bar
            const ColoredBox(
              color: Colors.white,
              child: TabBar(
                labelColor: AppColors.navy,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.navy,
                indicatorWeight: 2.5,
                labelStyle: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(
                      icon: Icon(Icons.info_outline, size: 18),
                      text: 'Infos'),
                  Tab(
                      icon: Icon(Icons.grid_view, size: 18),
                      text: 'Zones'),
                  Tab(
                      icon: Icon(Icons.people_outline, size: 18),
                      text: 'Équipe'),
                  Tab(
                      icon: Icon(Icons.inventory_2_outlined, size: 18),
                      text: 'Stocks'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _buildInfoTab(shelter, state),
                  _buildZonesTab(shelter, canEdit, state, shelterId),
                  _buildTeamTab(shelter, canEdit, state, shelterId),
                  _buildStocksTab(shelter, canEdit, state, shelterId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1 : Infos ──────────────────────────────────────────────

  Widget _buildInfoTab(ShelterModel shelter, AppState state) {
    final occupancy = state.occupancyOf(shelter.id);
    final placesRestantes = state.placesRestantesOf(shelter.id);
    final pct = state.capacityPercentOf(shelter.id).clamp(0.0, 1.0);
    final color =
        pct > 0.9 ? AppColors.red : pct > 0.7 ? AppColors.orange : AppColors.green;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _InfoCard(children: [
            _InfoRow(
                icon: Icons.business_outlined,
                label: 'Nom du centre',
                value: shelter.name),
            _InfoRow(
                icon: Icons.location_city_outlined,
                label: 'Commune',
                value: shelter.commune),
            _InfoRow(
                icon: Icons.place_outlined,
                label: 'Adresse',
                value: shelter.address),
          ]),
          const SizedBox(height: 14),

          // Capacity card
          _InfoCard(children: [
            Row(
              children: [
                const Icon(Icons.people, size: 18, color: AppColors.navy),
                const SizedBox(width: 8),
                const Text('Capacité',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const Spacer(),
                Text(
                  '$occupancy / ${shelter.capacity}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.divider,
                color: color,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(pct * 100).toStringAsFixed(0)} % occupé',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  '$placesRestantes place(s) libre(s)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 14),

          // Status
          _InfoCard(children: [
            Row(
              children: [
                const Icon(Icons.toggle_on_outlined,
                    size: 18, color: AppColors.navy),
                const SizedBox(width: 8),
                const Text('Statut',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const Spacer(),
                _ShelterStatusChip(shelter.status),
              ],
            ),
          ]),
        ],
      ),
    );
  }

  // ── Tab 2 : Zones ──────────────────────────────────────────────

  Widget _buildZonesTab(
      ShelterModel shelter, bool canEdit, AppState state, String shelterId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.grid_view,
                          size: 18, color: AppColors.navy),
                      const SizedBox(width: 8),
                      Text(
                        'Zones (${shelter.zones.length})',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      if (canEdit)
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Ajouter'),
                          onPressed: () => _showAddZoneSheet(
                              context, shelter, state, shelterId),
                        ),
                    ],
                  ),
                ),
                if (shelter.zones.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Aucune zone définie',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...shelter.zones.asMap().entries.map((entry) {
                    final isLast = entry.key == shelter.zones.length - 1;
                    final zone = entry.value;
                    return Column(
                      children: [
                        if (entry.key > 0)
                          const Divider(height: 1, indent: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: AppColors.blue,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(zone,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary)),
                              ),
                              if (canEdit)
                                GestureDetector(
                                  onTap: () => state.removeShelterZone(
                                      shelterId, zone),
                                  child: const Icon(Icons.close,
                                      size: 18,
                                      color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        if (isLast) const SizedBox(height: 4),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddZoneSheet(BuildContext context, ShelterModel shelter,
      AppState state, String shelterId) async {
    _zoneCtrl.clear();
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    const Text('Ajouter une zone',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // Preset zones
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetZones.map((z) {
                    final already = shelter.zones.contains(z);
                    return GestureDetector(
                      onTap: already
                          ? null
                          : () {
                              state.addShelterZone(shelterId, z);
                              Navigator.pop(ctx);
                              messenger.showSnackBar(SnackBar(
                                content: Text('Zone "$z" ajoutée'),
                                duration: const Duration(seconds: 2),
                              ));
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: already
                              ? AppColors.grayLight
                              : AppColors.blueLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: already
                                ? AppColors.divider
                                : AppColors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (already)
                              const Icon(Icons.check,
                                  size: 14, color: AppColors.grayText)
                            else
                              const Icon(Icons.add,
                                  size: 14, color: AppColors.blue),
                            const SizedBox(width: 6),
                            Text(z,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: already
                                        ? AppColors.textSecondary
                                        : AppColors.blue,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Custom name
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _zoneCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Nom personnalisé…',
                          prefixIcon: Icon(Icons.edit_outlined,
                              color: AppColors.textSecondary),
                        ),
                        onChanged: (_) => setSheet(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _zoneCtrl.text.trim().isEmpty
                          ? null
                          : () {
                              final zone = _zoneCtrl.text.trim();
                              state.addShelterZone(shelterId, zone);
                              Navigator.pop(ctx);
                              messenger.showSnackBar(SnackBar(
                                content: Text('Zone "$zone" ajoutée'),
                                duration: const Duration(seconds: 2),
                              ));
                            },
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 3 : Équipe ─────────────────────────────────────────────

  Widget _buildTeamTab(
      ShelterModel shelter, bool canEdit, AppState state, String shelterId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Responsable
          Container(
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
                    const Icon(Icons.manage_accounts_outlined,
                        size: 18, color: AppColors.navy),
                    const SizedBox(width: 8),
                    const Text('Responsable du site',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const Spacer(),
                    if (canEdit)
                      TextButton(
                        onPressed: () =>
                            _showEditResponsableDialog(context, shelter, state, shelterId),
                        child: const Text('Modifier'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (shelter.responsableName == null)
                  const Text('Non défini',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic))
                else ...[
                  _PersonRow(
                    icon: Icons.person,
                    value: shelter.responsableName!,
                    color: AppColors.navy,
                  ),
                  if (shelter.responsablePhone != null) ...[
                    const SizedBox(height: 8),
                    _PersonRow(
                      icon: Icons.phone_outlined,
                      value: shelter.responsablePhone!,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Agents
          Container(
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined,
                          size: 18, color: AppColors.navy),
                      const SizedBox(width: 8),
                      Text(
                        'Agents affectés (${shelter.agentNames.length})',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      if (canEdit)
                        TextButton.icon(
                          icon: const Icon(Icons.person_add_outlined, size: 18),
                          label: const Text('Ajouter'),
                          onPressed: () => _showAddAgentDialog(
                              context, state, shelterId),
                        ),
                    ],
                  ),
                ),
                if (shelter.agentNames.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aucun agent affecté',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  ...shelter.agentNames.asMap().entries.map((e) {
                    final agentName = e.value;
                    return Column(
                      children: [
                        if (e.key > 0)
                          const Divider(height: 1, indent: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                    color: AppColors.blueLight,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.person,
                                    color: AppColors.blue, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(agentName,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary)),
                              ),
                              if (canEdit)
                                GestureDetector(
                                  onTap: () => state.removeShelterAgent(
                                      shelterId, agentName),
                                  child: const Icon(Icons.close,
                                      size: 18,
                                      color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditResponsableDialog(BuildContext context,
      ShelterModel shelter, AppState state, String shelterId) async {
    final nameCtrl =
        TextEditingController(text: shelter.responsableName ?? '');
    final phoneCtrl =
        TextEditingController(text: shelter.responsablePhone ?? '');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Responsable du site'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nom', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone_outlined)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              state.updateShelterResponsable(
                shelterId,
                name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    phoneCtrl.dispose();
  }

  Future<void> _showAddAgentDialog(
      BuildContext context, AppState state, String shelterId) async {
    _agentCtrl.clear();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ajouter un agent'),
        content: TextField(
          controller: _agentCtrl,
          decoration: const InputDecoration(
            hintText: 'Nom de l\'agent',
            prefixIcon: Icon(Icons.person_add_outlined),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final name = _agentCtrl.text.trim();
              if (name.isNotEmpty) {
                state.addShelterAgent(shelterId, name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  // ── Tab 4 : Stocks ─────────────────────────────────────────────

  Widget _buildStocksTab(
      ShelterModel shelter, bool canEdit, AppState state, String shelterId) {
    final lowItems = _stockItems.where((item) {
      final qty = shelter.stock[item.key] ?? 0;
      return qty < item.minThreshold;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Alert if any low stock
          if (lowItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.orangeLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${lowItems.length} ressource(s) sous le seuil minimum : ${lowItems.map((i) => i.label).join(', ')}',
                      style: const TextStyle(
                          color: AppColors.orangeText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Stock list
          Container(
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
            child: Column(
              children: _stockItems.asMap().entries.map((e) {
                final item = e.value;
                final qty = shelter.stock[item.key] ?? 0;
                final isLow = qty < item.minThreshold;
                final isCritical = qty == 0;
                final itemColor = isCritical
                    ? AppColors.red
                    : isLow
                        ? AppColors.orange
                        : AppColors.green;

                return Column(
                  children: [
                    if (e.key > 0)
                      const Divider(height: 1, indent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: itemColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, size: 20, color: itemColor),
                          ),
                          const SizedBox(width: 12),

                          // Label + unit
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.label,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                                if (item.unit.isNotEmpty)
                                  Text(item.unit,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary)),
                              ],
                            ),
                          ),

                          // Controls
                          if (canEdit) ...[
                            _StockBtn(
                              icon: Icons.remove,
                              onTap: qty > 0
                                  ? () => state.updateShelterStock(
                                      shelterId, item.key, qty - 1)
                                  : null,
                            ),
                            const SizedBox(width: 6),
                          ],
                          SizedBox(
                            width: 44,
                            child: Text(
                              '$qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: itemColor,
                              ),
                            ),
                          ),
                          if (canEdit) ...[
                            const SizedBox(width: 6),
                            _StockBtn(
                              icon: Icons.add,
                              onTap: () => state.updateShelterStock(
                                  shelterId, item.key, qty + 1),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          // ── Transferts de stock entre centres ─────────────────────
          const SizedBox(height: 22),
          _buildStockTransfersSection(state, canEdit, shelterId),

          // ── Traçabilité : entrées de stock ────────────────────────
          const SizedBox(height: 22),
          _buildStockEntriesSection(state, canEdit, shelterId),

          if (!canEdit) ...[
            const SizedBox(height: 12),
            const Text(
              'Modification des stocks réservée au Responsable de centre',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Transferts de stock entre centres ────────────────────────────

  Widget _buildStockTransfersSection(
      AppState state, bool canEdit, String shelterId) {
    final transfers = state.stockTransfersOf(shelterId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.swap_horiz,
                size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Transferts entre centres',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
            ),
            if (transfers.isNotEmpty)
              Text(
                '${transfers.length}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Suivi du nombre de produits déplacés vers ou depuis ce centre.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),

        if (transfers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.bgPage,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Aucun transfert en cours.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          )
        else
          Container(
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
            child: Column(
              children: transfers.asMap().entries.map((e) {
                return Column(
                  children: [
                    if (e.key > 0) const Divider(height: 1, indent: 16),
                    _StockTransferTile(
                      transfer: e.value,
                      viewerShelterId: shelterId,
                      canEdit: canEdit,
                      onDepart: () =>
                          state.markStockTransferDeparted(e.value.id),
                      onConfirm: () =>
                          state.confirmStockTransferArrival(e.value.id),
                      onCancel: () => _confirmCancelTransfer(state, e.value),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmCancelTransfer(
      AppState state, StockTransferModel transfer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler le transfert ?'),
        content: Text(
            '${transfer.quantity} ${transfer.unit} de ${transfer.label} seront restitués au stock de ${transfer.fromShelterName}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Retour')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Annuler le transfert'),
          ),
        ],
      ),
    );
    if (ok == true) state.cancelStockTransfer(transfer.id);
  }

  // ── Entrées de stock (traçabilité : datage, provenance, photo) ──

  Widget _buildStockEntriesSection(
      AppState state, bool canEdit, String shelterId) {
    final entries = state.stockEntriesOf(shelterId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Entrées de stock',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
            ),
            if (entries.isNotEmpty)
              Text(
                '${entries.length}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Traçabilité des lots reçus : date d\'entrée, provenance, étiquette.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),

        if (canEdit) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showStockEntryForm(context, shelterId),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: const Text('Ajouter une entrée'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.navy),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showStockTransferForm(context, shelterId),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Transférer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    side: const BorderSide(color: AppColors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.bgPage,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Aucune entrée enregistrée pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          )
        else
          Container(
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
            child: Column(
              children: entries.asMap().entries.map((e) {
                return Column(
                  children: [
                    if (e.key > 0) const Divider(height: 1, indent: 16),
                    _StockEntryTile(
                      entry: e.value,
                      canEdit: canEdit,
                      onDelete: () => _confirmDeleteEntry(state, e.value),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDeleteEntry(
      AppState state, StockEntryModel entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'entrée ?'),
        content: Text(
            '« ${entry.label} » (${entry.quantity}) sera retiré du stock tracé.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) state.removeStockEntry(entry.id);
  }
}

// ════════════════════════════════════════════════════════════════
// Sub-widgets
// ════════════════════════════════════════════════════════════════

class _ShelterHeaderCard extends StatelessWidget {
  final ShelterModel shelter;
  final bool canEdit;
  final void Function(ShelterStatus) onStatusChange;

  const _ShelterHeaderCard(
      {required this.shelter,
      required this.canEdit,
      required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.business, color: AppColors.blue, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shelter.name,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  shelter.address,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: canEdit
                ? () => _showStatusDialog(context)
                : null,
            child: _ShelterStatusChip(shelter.status),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatusDialog(BuildContext context) async {
    await showDialog<ShelterStatus>(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Changer le statut'),
        children: ShelterStatus.values.map((s) {
          return SimpleDialogOption(
            onPressed: () {
              onStatusChange(s);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                _ShelterStatusChip(s),
                const SizedBox(width: 12),
                if (s == ShelterStatus.open)
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: AppColors.green)
                else if (s == ShelterStatus.full)
                  const Icon(Icons.warning_rounded,
                      size: 16, color: AppColors.orange)
                else if (s == ShelterStatus.closed)
                  const Icon(Icons.cancel_outlined,
                      size: 16, color: AppColors.red)
                else
                  const Icon(Icons.hourglass_top,
                      size: 16, color: AppColors.blue),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ShelterStatusChip extends StatelessWidget {
  final ShelterStatus status;
  const _ShelterStatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ShelterStatus.open => ('Ouvert', AppColors.green),
      ShelterStatus.full => ('Complet', AppColors.orange),
      ShelterStatus.closed => ('Fermé', AppColors.red),
      ShelterStatus.preparation => ('Préparation', AppColors.blue),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

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
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _PersonRow(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(value,
            style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }
}

class _StockBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StockBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.bgPage : AppColors.grayLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null
              ? AppColors.textPrimary
              : AppColors.textHint,
        ),
      ),
    );
  }
}

// ── Une entrée de stock tracée (date, provenance, photo, agent) ──

class _StockEntryTile extends StatelessWidget {
  final StockEntryModel entry;
  final bool canEdit;
  final VoidCallback onDelete;

  const _StockEntryTile({
    required this.entry,
    required this.canEdit,
    required this.onDelete,
  });

  static const _months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final expired = entry.expiryDate != null &&
        entry.expiryDate!.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vignette photo d'étiquette (ou pictogramme)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.bgPage,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: entry.photoBytes != null
                ? Image.memory(entry.photoBytes!, fit: BoxFit.cover)
                : (entry.photoUrl != null
                    ? Image.network(entry.photoUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.inventory_2_outlined,
                        size: 22, color: AppColors.textHint)),
          ),
          const SizedBox(width: 12),

          // Détails
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.label,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      '${entry.quantity >= 0 ? '+' : ''}${entry.quantity}${entry.unit.isNotEmpty ? ' ${entry.unit}' : ''}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: entry.quantity >= 0
                              ? AppColors.green
                              : AppColors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _chip(Icons.event, _fmt(entry.dateEntree)),
                    if (entry.provenance != null &&
                        entry.provenance!.isNotEmpty)
                      _chip(Icons.local_shipping_outlined, entry.provenance!),
                    if (entry.expiryDate != null)
                      _chip(
                        Icons.hourglass_bottom,
                        'Périme ${_fmt(entry.expiryDate!)}',
                        color: expired ? AppColors.red : AppColors.orange,
                      ),
                    if (entry.hasPhoto)
                      _chip(Icons.photo_camera_outlined, 'Étiquette'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Saisi par ${entry.addedBy}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),

          if (canEdit)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.textHint,
              tooltip: 'Supprimer',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, {Color color = AppColors.textSecondary}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

// ── Un transfert de stock entre deux centres, avec statut et actions ──

class _StockTransferTile extends StatelessWidget {
  final StockTransferModel transfer;
  final String viewerShelterId;
  final bool canEdit;
  final VoidCallback onDepart;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _StockTransferTile({
    required this.transfer,
    required this.viewerShelterId,
    required this.canEdit,
    required this.onDepart,
    required this.onConfirm,
    required this.onCancel,
  });

  (Color, Color, String) get _statusStyle {
    switch (transfer.status) {
      case TransferStatus.pending:
        return (AppColors.orangeLight, AppColors.orangeText, 'En préparation');
      case TransferStatus.inProgress:
        return (AppColors.blueLight, AppColors.blueText, 'En transit');
      case TransferStatus.confirmed:
        return (AppColors.greenLight, AppColors.greenText, 'Réceptionné');
      case TransferStatus.cancelled:
        return (AppColors.grayLight, AppColors.grayText, 'Annulé');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOutgoing = transfer.fromShelterId == viewerShelterId;
    final isIncoming = transfer.toShelterId == viewerShelterId;
    final (bgColor, textColor, statusLabel) = _statusStyle;
    final active = transfer.status == TransferStatus.pending ||
        transfer.status == TransferStatus.inProgress;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transfer.label,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      isOutgoing
                          ? 'Vers ${transfer.toShelterName}'
                          : 'Depuis ${transfer.fromShelterName}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                '${transfer.quantity}${transfer.unit.isNotEmpty ? ' ${transfer.unit}' : ''}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
              ),
              const Spacer(),
              if (canEdit && active) ...[
                if (isOutgoing && transfer.status == TransferStatus.pending)
                  TextButton(
                    onPressed: onDepart,
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                    child: const Text('Marquer parti',
                        style: TextStyle(fontSize: 12)),
                  ),
                if (isIncoming)
                  TextButton(
                    onPressed: onConfirm,
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.green),
                    child: const Text('Confirmer réception',
                        style: TextStyle(fontSize: 12)),
                  ),
                if (isOutgoing)
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.red),
                    child:
                        const Text('Annuler', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
