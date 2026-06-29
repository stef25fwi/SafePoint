import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../models/enums.dart';
import '../services/app_state.dart';
import 'dashboard_page.dart';
import 'persons_page.dart';
import 'scanner_page.dart';
import 'alerts_page.dart';
import 'reports_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => MainShellPageState();
}

class MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  final _pages = const [
    DashboardPage(),
    PersonsPage(),
    ScannerPage(),
    AlertsPage(),
    ReportsPage(),
  ];

  void setTab(int index) {
    setState(() => _currentIndex = index);
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.agentAccueil:
        return AppColors.blue;
      case UserRole.responsableCentre:
        return AppColors.green;
      case UserRole.celluleCrise:
        return AppColors.orange;
      case UserRole.prefectureLecture:
        return AppColors.purple;
      case UserRole.admin:
        return AppColors.red;
    }
  }

  // ── Layout desktop : rail latéral + contenu centré large ──────────
  Widget _buildWide(
      BuildContext context, AppState state, int alertCount, bool canScan) {
    final roleColor = _roleColor(state.currentRole);
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => _onSelect(context, i, canScan),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.blueLight,
            selectedIconTheme: const IconThemeData(color: AppColors.navy),
            selectedLabelTextStyle: const TextStyle(
                color: AppColors.navy, fontWeight: FontWeight.w600),
            unselectedIconTheme:
                const IconThemeData(color: AppColors.grayText),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.navy,
                    child: Icon(Icons.volcano, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.badge_outlined, size: 14, color: roleColor),
                  ),
                ],
              ),
            ),
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Accueil'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: Text('Personnes'),
              ),
              NavigationRailDestination(
                icon: Icon(canScan ? Icons.qr_code_scanner : Icons.lock_outline),
                selectedIcon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scanner'),
              ),
              NavigationRailDestination(
                icon: Badge(
                  isLabelVisible: alertCount > 0,
                  label: Text(alertCount > 99 ? '99+' : '$alertCount'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                selectedIcon: const Icon(Icons.notifications),
                label: const Text('Alertes'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Rapports'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: ResponsiveCenter(
              maxWidth: 1100,
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSelect(BuildContext context, int index, bool canScan) {
    if (index == 2 && !canScan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accès réservé aux agents de pointage'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final alertCount = state.openAlerts.length;
    final canScan = state.canCheckIn;

    // Desktop / grande tablette : rail de navigation latéral, contenu large.
    if (context.isDesktop) {
      return _buildWide(context, state, alertCount, canScan);
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Role indicator strip
          Container(
            width: double.infinity,
            color: _roleColor(state.currentRole).withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.badge_outlined,
                    size: 12, color: _roleColor(state.currentRole)),
                const SizedBox(width: 4),
                Text(
                  state.currentRole.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _roleColor(state.currentRole),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                height: 60,
                child: Row(
                  children: [
                    _NavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: 'Accueil',
                      index: 0,
                      current: _currentIndex,
                      onTap: () => setTab(0),
                    ),
                    _NavItem(
                      icon: Icons.group_outlined,
                      activeIcon: Icons.group,
                      label: 'Personnes',
                      index: 1,
                      current: _currentIndex,
                      onTap: () => setTab(1),
                    ),
                    // Scanner center button (locked for prefectureLecture)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!canScan) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Accès réservé aux agents de pointage'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          setTab(2);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: !canScan
                                    ? AppColors.grayText
                                    : _currentIndex == 2
                                        ? AppColors.blue
                                        : AppColors.navy,
                                shape: BoxShape.circle,
                                boxShadow: canScan
                                    ? [
                                        BoxShadow(
                                          color: AppColors.navy
                                              .withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                canScan
                                    ? Icons.qr_code_scanner
                                    : Icons.lock_outline,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Scanner',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: !canScan
                                    ? AppColors.textHint
                                    : _currentIndex == 2
                                        ? AppColors.blue
                                        : AppColors.grayText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _NavItemWithBadge(
                      icon: Icons.notifications_outlined,
                      activeIcon: Icons.notifications,
                      label: 'Alertes',
                      index: 3,
                      current: _currentIndex,
                      badge: alertCount,
                      onTap: () => setTab(3),
                    ),
                    _NavItem(
                      icon: Icons.bar_chart_outlined,
                      activeIcon: Icons.bar_chart,
                      label: 'Rapports',
                      index: 4,
                      current: _currentIndex,
                      onTap: () => setTab(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  bool get isActive => index == current;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? AppColors.navy : AppColors.grayText,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.navy : AppColors.grayText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemWithBadge extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final int badge;
  final VoidCallback onTap;

  const _NavItemWithBadge({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.badge,
    required this.onTap,
  });

  bool get isActive => index == current;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 24,
                  color: isActive ? AppColors.navy : AppColors.grayText,
                ),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.navy : AppColors.grayText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
