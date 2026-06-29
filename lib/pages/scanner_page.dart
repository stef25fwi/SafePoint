import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_routes.dart';
import '../models/enums.dart';
import '../models/person_model.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  PersonModel? _scannedPerson;
  bool _scanning = false;
  bool _flashOn = false;
  late AnimationController _scanAnim;
  late Animation<double> _scanPosition;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scanPosition = Tween<double>(begin: 0.0, end: 1.0).animate(_scanAnim);
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    super.dispose();
  }

  void _simulateScan() {
    final state = context.read<AppState>();
    final persons = state.allPersons;
    if (persons.isEmpty) return;

    setState(() {
      _scanning = true;
      _scannedPerson = null;
      _successMessage = null;
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

  void _doCheckin(CheckinType type) {
    if (_scannedPerson == null) return;
    context.read<AppState>().createCheckin(personId: _scannedPerson!.id, type: type);
    setState(() {
      _successMessage = '${type.label} enregistré pour ${_scannedPerson!.fullName}';
      _scannedPerson = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final recentCheckins = state.recentCheckins.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          AppHeader(
            title: 'Refuge Volcan',
            subtitle: 'Centre d\'hébergement – ${state.currentShelter.name}',
            showBack: false,
            alertCount: state.openAlerts.length,
          ),

          // Scanner title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scanner QR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text('Pointage rapide', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Camera viewfinder
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GestureDetector(
                        onTap: _simulateScan,
                        child: Container(
                          height: 220,
                          color: const Color(0xFF1A1A2E),
                          child: Stack(
                            children: [
                              // Background shelter scene
                              const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.qr_code_scanner, size: 48, color: Colors.white54),
                                    SizedBox(height: 8),
                                    Text(
                                      'Positionnez le QR code dans le cadre',
                                      style: TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Appuyez pour simuler un scan',
                                      style: TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              // Scan frame
                              Center(
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _scanning
                                      ? AnimatedBuilder(
                                          animation: _scanPosition,
                                          builder: (_, __) => Align(
                                            alignment: Alignment(0, (_scanPosition.value * 2) - 1),
                                            child: Container(
                                              height: 3,
                                              color: const Color(0xFF00FF88).withValues(alpha: 0.8),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              // Controls
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

                  // Success message
                  if (_successMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
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
                              child: Text(_successMessage!, style: const TextStyle(color: AppColors.greenText, fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Scanned person card
                  if (_scannedPerson != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(color: AppColors.greenLight, shape: BoxShape.circle),
                              child: const Icon(Icons.person, color: AppColors.green, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_scannedPerson!.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  Text(
                                    '${_scannedPerson!.familyId != null ? "Famille – " : ""}${_scannedPerson!.currentZone ?? ""} – Statut : ',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.greenLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check, size: 14, color: AppColors.green),
                                  const SizedBox(width: 4),
                                  const Text('QR reconnu', style: TextStyle(fontSize: 12, color: AppColors.greenText, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Action buttons
                  if (_scannedPerson != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.6,
                          children: [
                            _ScanAction(
                              icon: Icons.check_circle,
                              label: 'Valider l\'entrée',
                              color: AppColors.green,
                              onTap: () => _doCheckin(CheckinType.arrival),
                            ),
                            _ScanAction(
                              icon: Icons.restaurant_outlined,
                              label: 'Valider repas',
                              color: AppColors.orange,
                              onTap: () => _doCheckin(CheckinType.mealLunch),
                            ),
                            _ScanAction(
                              icon: Icons.exit_to_app,
                              label: 'Sortie',
                              color: AppColors.red,
                              onTap: () => _doCheckin(CheckinType.exitTemporary),
                            ),
                            _ScanAction(
                              icon: Icons.swap_horiz,
                              label: 'Transfert',
                              color: AppColors.blue,
                              onTap: () {
                                Navigator.pushNamed(context, AppRoutes.createTransfer, arguments: [_scannedPerson!.id]);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),

                  // Recent scans
                  if (recentCheckins.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time_filled, size: 18, color: AppColors.navy),
                                const SizedBox(width: 8),
                                const Expanded(child: Text('Derniers scans', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                                GestureDetector(
                                  child: const Row(
                                    children: [
                                      Text('Voir tout', style: TextStyle(fontSize: 13, color: AppColors.blue, fontWeight: FontWeight.w600)),
                                      Icon(Icons.chevron_right, size: 16, color: AppColors.blue),
                                    ],
                                  ),
                                ),
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
                                      decoration: const BoxDecoration(color: AppColors.greenLight, shape: BoxShape.circle),
                                      child: const Icon(Icons.person, color: AppColors.green, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            person?.fullName ?? 'Personne inconnue',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                          ),
                                          Text(
                                            '${person?.currentZone ?? ""} – ${person?.status.label ?? ""}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text('$h:$m', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CameraBtn({required this.icon, required this.label, required this.onTap});

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
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
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

  const _ScanAction({required this.icon, required this.label, required this.color, required this.onTap});

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
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
