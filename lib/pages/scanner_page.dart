import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_routes.dart';
import '../models/checkin_model.dart';
import '../models/enums.dart';
import '../models/family_model.dart';
import '../models/person_model.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/status_badge.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin {
  // ── Tab 1 : QR Code ──────────────────────────────────────────
  PersonModel? _scannedPerson;
  bool _scanning = false;
  bool _flashOn = false;
  late AnimationController _scanAnim;
  late Animation<double> _scanPosition;
  String? _qrSuccess;

  // ── Tab 2 : Recherche manuelle ───────────────────────────────
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  PersonModel? _selectedPerson;
  String? _searchSuccess;

  // ── Tab 3 : Pointage familial ────────────────────────────────
  String? _familyPointageId;
  Set<String> _familyChecked = {};
  String? _familySuccess;

  @override
  void initState() {
    super.initState();
    _scanAnim =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _scanPosition = Tween<double>(begin: 0.0, end: 1.0).animate(_scanAnim);
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.trim()));
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── QR methods ───────────────────────────────────────────────
  void _simulateScan() {
    final persons = context.read<AppState>().allPersons;
    if (persons.isEmpty) return;
    setState(() {
      _scanning = true;
      _scannedPerson = null;
      _qrSuccess = null;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _scannedPerson = persons.firstWhere(
          (p) => p.status == PersonStatus.present,
          orElse: () => persons.first,
        );
      });
    });
  }

  void _doQrCheckin(CheckinType type) {
    if (_scannedPerson == null) return;
    final name = _scannedPerson!.fullName;
    context.read<AppState>().createCheckin(personId: _scannedPerson!.id, type: type);
    setState(() {
      _qrSuccess = '${type.label} enregistré pour $name';
      _scannedPerson = null;
    });
  }

  // ── Search methods ───────────────────────────────────────────
  List<PersonModel> _searchResults(List<PersonModel> all) {
    if (_searchQuery.isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return all
        .where((p) =>
            p.lastName.toLowerCase().contains(q) ||
            p.firstName.toLowerCase().contains(q) ||
            (p.originCommune?.toLowerCase().contains(q) ?? false) ||
            p.id.startsWith(q))
        .take(10)
        .toList();
  }

  void _doSearchCheckin(CheckinType type) {
    if (_selectedPerson == null) return;
    final name = _selectedPerson!.fullName;
    context
        .read<AppState>()
        .createCheckin(personId: _selectedPerson!.id, type: type);
    setState(() {
      _searchSuccess = '${type.label} enregistré pour $name';
      _selectedPerson = null;
    });
  }

  // ── Family methods ───────────────────────────────────────────
  void _expandFamily(String familyId, List<PersonModel> members) {
    setState(() {
      _familyPointageId = familyId;
      _familyChecked = members.map((m) => m.id).toSet();
      _familySuccess = null;
    });
  }

  void _collapseFamily() {
    setState(() {
      _familyPointageId = null;
      _familyChecked = {};
    });
  }

  void _doFamilyCheckin() {
    if (_familyPointageId == null || _familyChecked.isEmpty) return;
    final state = context.read<AppState>();
    final family = state.getFamilyById(_familyPointageId!);
    final count = _familyChecked.length;
    state.createFamilyCheckin(
      personIds: _familyChecked.toList(),
      familyId: _familyPointageId!,
      type: CheckinType.presence,
    );
    setState(() {
      _familySuccess =
          '$count présence(s) enregistrée(s) – ${family?.displayName ?? "Famille"}';
      _familyPointageId = null;
      _familyChecked = {};
    });
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final recentCheckins = state.recentCheckins.take(3).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        body: Column(
          children: [
            AppHeader(
              title: 'safepointapp.',
              subtitle: 'Centre d\'hébergement – ${state.currentShelter.name}',
              showBack: false,
              alertCount: state.openAlerts.length,
            ),

            // Title + TabBar in a white header
            const ColoredBox(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pointage',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          Text('3 méthodes disponibles',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  TabBar(
                    labelColor: AppColors.navy,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.navy,
                    indicatorWeight: 2.5,
                    labelStyle:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    tabs: [
                      Tab(icon: Icon(Icons.qr_code_scanner, size: 20), text: 'QR Code'),
                      Tab(icon: Icon(Icons.search, size: 20), text: 'Recherche'),
                      Tab(icon: Icon(Icons.family_restroom, size: 20), text: 'Famille'),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _buildQrTab(recentCheckins, state),
                  _buildSearchTab(state),
                  _buildFamilyTab(state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Tab 1 : QR Code scanner
  // ══════════════════════════════════════════════════════════════
  Widget _buildQrTab(List<CheckinModel> recentCheckins, AppState state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Camera viewfinder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onTap: _simulateScan,
                child: Container(
                  height: 200,
                  color: const Color(0xFF1A1A2E),
                  child: Stack(
                    children: [
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner,
                                size: 44, color: Colors.white54),
                            SizedBox(height: 8),
                            Text('Positionnez le QR code dans le cadre',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            SizedBox(height: 4),
                            Text('Appuyez pour simuler un scan',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _scanning
                              ? AnimatedBuilder(
                                  animation: _scanPosition,
                                  builder: (_, __) => Align(
                                    alignment: Alignment(
                                        0, (_scanPosition.value * 2) - 1),
                                    child: Container(
                                        height: 3,
                                        color: const Color(0xFF00FF88)
                                            .withValues(alpha: 0.8)),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 16,
                        child: _CameraBtn(
                          icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                          label: 'Flash',
                          onTap: () => setState(() => _flashOn = !_flashOn),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        top: 16,
                        child: _CameraBtn(
                          icon: Icons.image_outlined,
                          label: 'Galerie',
                          onTap: _simulateScan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_qrSuccess != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SuccessBanner(message: _qrSuccess!),
            ),

          if (_scannedPerson != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _ScannedPersonCard(person: _scannedPerson!),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ActionGrid(
                onCheckin: _doQrCheckin,
                onTransfer: () => Navigator.pushNamed(
                    context, AppRoutes.createTransfer,
                    arguments: [_scannedPerson!.id]),
              ),
            ),
          ],
          const SizedBox(height: 14),

          if (recentCheckins.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _RecentScansCard(recentCheckins: recentCheckins, state: state),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Tab 2 : Recherche manuelle
  // ══════════════════════════════════════════════════════════════
  Widget _buildSearchTab(AppState state) {
    final results = _searchResults(state.allPersons);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Nom, prénom, commune, numéro de fiche…',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _selectedPerson = null;
                          _searchSuccess = null;
                        });
                      })
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.blue, width: 1.5)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),

        if (_searchSuccess != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SuccessBanner(message: _searchSuccess!),
          ),

        if (_selectedPerson != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ScannedPersonCard(person: _selectedPerson!),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ActionGrid(
              onCheckin: _doSearchCheckin,
              onTransfer: () => Navigator.pushNamed(
                  context, AppRoutes.createTransfer,
                  arguments: [_selectedPerson!.id]),
            ),
          ),
          const SizedBox(height: 8),
        ],

        Expanded(
          child: _searchQuery.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search,
                          size: 48, color: AppColors.textHint),
                      SizedBox(height: 10),
                      Text(
                        'Tapez un nom, prénom ou\nnuméro de fiche',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : results.isEmpty
                  ? const Center(
                      child: Text('Aucune personne trouvée',
                          style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final p = results[i];
                        final selected = _selectedPerson?.id == p.id;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedPerson = selected ? null : p;
                            _searchSuccess = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.blueLight
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppColors.blue
                                    : AppColors.divider,
                                width: selected ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1))
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                      color: AppColors.grayLight,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.person,
                                      color: AppColors.grayText, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p.fullName,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary)),
                                      Text(
                                        '${p.originCommune ?? "—"} · ${p.currentZone ?? "?"} · N° ${p.id.length > 8 ? p.id.substring(0, 8) : p.id}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge.fromPersonStatus(p.status),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Tab 3 : Pointage familial
  // ══════════════════════════════════════════════════════════════
  Widget _buildFamilyTab(AppState state) {
    final families = state.currentFamilies;

    return Column(
      children: [
        if (_familySuccess != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _SuccessBanner(message: _familySuccess!),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tapez « Pointer » pour pointer toute une famille. Décochez les absents avant de confirmer.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: families.isEmpty
              ? const Center(
                  child: Text('Aucune famille enregistrée',
                      style: TextStyle(color: AppColors.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  itemCount: families.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final family = families[i];
                    final members = state.getFamilyMembers(family.id);
                    final isExpanded = _familyPointageId == family.id;
                    return _FamilyPointageCard(
                      family: family,
                      members: members,
                      isExpanded: isExpanded,
                      checkedIds: isExpanded ? _familyChecked : const {},
                      onExpand: () => isExpanded
                          ? _collapseFamily()
                          : _expandFamily(family.id, members),
                      onToggleMember: (id) => setState(() {
                        if (_familyChecked.contains(id)) {
                          _familyChecked.remove(id);
                        } else {
                          _familyChecked.add(id);
                        }
                      }),
                      onConfirm: _doFamilyCheckin,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Shared widgets
// ════════════════════════════════════════════════════════════════

class _SuccessBanner extends StatelessWidget {
  final String message;
  const _SuccessBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppColors.greenText,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ScannedPersonCard extends StatelessWidget {
  final PersonModel person;
  const _ScannedPersonCard({required this.person});

  static final _vulnLabels = <String, (String, IconData, Color)>{
    'personne_agee': ('Âgé(e)', Icons.elderly, AppColors.orange),
    'pmr': ('PMR', Icons.accessible, AppColors.blue),
    'enfant': ('Enfant', Icons.child_care, AppColors.purple),
    'enceinte': ('Enceinte', Icons.pregnant_woman, AppColors.green),
    'sans_papiers': ('Sans papiers', Icons.badge_outlined, AppColors.orange),
    'isolement': ('Isolé(e)', Icons.person_off_outlined, AppColors.red),
  };

  @override
  Widget build(BuildContext context) {
    final flags = person.vulnerabilityFlags
        .where(_vulnLabels.containsKey)
        .take(3)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: AppColors.greenLight, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: AppColors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person.fullName,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(
                      '${person.currentZone ?? "Zone ?"} · ${person.originCommune ?? "Commune ?"}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.green.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 14, color: AppColors.green),
                    SizedBox(width: 4),
                    Text('Reconnu',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.greenText,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          if (flags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: flags.map((key) {
                final info = _vulnLabels[key]!;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: info.$3.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(info.$2, size: 12, color: info.$3),
                      const SizedBox(width: 4),
                      Text(info.$1,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: info.$3)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final void Function(CheckinType) onCheckin;
  final VoidCallback onTransfer;

  const _ActionGrid({required this.onCheckin, required this.onTransfer});

  CheckinType get _mealType {
    final h = DateTime.now().hour;
    if (h < 10) return CheckinType.mealBreakfast;
    if (h < 15) return CheckinType.mealLunch;
    return CheckinType.mealDinner;
  }

  String get _mealLabel {
    final h = DateTime.now().hour;
    if (h < 10) return 'Petit-déj.';
    if (h < 15) return 'Déjeuner';
    return 'Dîner';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.0,
            children: [
              _ScanAction(
                  icon: Icons.how_to_reg,
                  label: 'Présence',
                  color: AppColors.green,
                  onTap: () => onCheckin(CheckinType.presence)),
              _ScanAction(
                  icon: Icons.restaurant_outlined,
                  label: _mealLabel,
                  color: AppColors.orange,
                  onTap: () => onCheckin(_mealType)),
              _ScanAction(
                  icon: Icons.bed_outlined,
                  label: 'Nuit',
                  color: AppColors.blue,
                  onTap: () => onCheckin(CheckinType.night)),
              _ScanAction(
                  icon: Icons.exit_to_app,
                  label: 'Sortie temp.',
                  color: AppColors.grayText,
                  onTap: () => onCheckin(CheckinType.exitTemporary)),
              _ScanAction(
                  icon: Icons.local_hospital_outlined,
                  label: 'Secours',
                  color: AppColors.purple,
                  onTap: () => onCheckin(CheckinType.medical)),
              _ScanAction(
                  icon: Icons.swap_horiz,
                  label: 'Transfert',
                  color: AppColors.navy,
                  onTap: onTransfer),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => onCheckin(CheckinType.exitFinal),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.red),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sortie définitive',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _RecentScansCard extends StatelessWidget {
  final List<CheckinModel> recentCheckins;
  final AppState state;
  const _RecentScansCard(
      {required this.recentCheckins, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          const Row(
            children: [
              Icon(Icons.access_time_filled, size: 18, color: AppColors.navy),
              SizedBox(width: 8),
              Text('Derniers pointages',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          ...recentCheckins.map((c) {
            final person = state.getPersonById(c.personId);
            final h = c.createdAt.hour.toString().padLeft(2, '0');
            final m = c.createdAt.minute.toString().padLeft(2, '0');
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                        color: AppColors.greenLight, shape: BoxShape.circle),
                    child: const Icon(Icons.person,
                        color: AppColors.green, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(person?.fullName ?? 'Inconnu',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text(c.type.label,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text('$h:$m',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FamilyPointageCard extends StatelessWidget {
  final FamilyModel family;
  final List<PersonModel> members;
  final bool isExpanded;
  final Set<String> checkedIds;
  final VoidCallback onExpand;
  final void Function(String) onToggleMember;
  final VoidCallback onConfirm;

  const _FamilyPointageCard({
    required this.family,
    required this.members,
    required this.isExpanded,
    required this.checkedIds,
    required this.onExpand,
    required this.onToggleMember,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isExpanded
            ? Border.all(color: AppColors.blue, width: 1.5)
            : Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? AppColors.blueLight
                        : AppColors.purpleLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.family_restroom,
                      size: 20,
                      color: isExpanded
                          ? AppColors.blue
                          : AppColors.purpleText),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(family.displayName,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      Text(
                        '${family.membersCount} membre(s) · ${family.assignedZone ?? "Zone ?"}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onExpand,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? AppColors.blueLight
                          : AppColors.navy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isExpanded ? 'Annuler' : 'Pointer',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isExpanded ? AppColors.blue : Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Expanded member list
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.divider),
            if (members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Aucun membre enregistré',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              )
            else
              ...members.map((m) {
                final checked = checkedIds.contains(m.id);
                return GestureDetector(
                  onTap: () => onToggleMember(m.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          checked
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: checked ? AppColors.blue : AppColors.textHint,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.fullName,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: checked
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary)),
                              if (m.ageApprox != null)
                                Text('${m.ageApprox} ans',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        StatusBadge.fromPersonStatus(m.status),
                      ],
                    ),
                  ),
                );
              }),
            if (members.isNotEmpty) ...[
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Text(
                      '${checkedIds.length}/${members.length} sélectionné(s)',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: checkedIds.isEmpty ? null : onConfirm,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Confirmer la présence'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CameraBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CameraBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ScanAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ScanAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
