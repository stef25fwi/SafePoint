import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/enums.dart';
import '../models/family_model.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/status_badge.dart';

class FamiliesPage extends StatefulWidget {
  const FamiliesPage({super.key});

  @override
  State<FamiliesPage> createState() => _FamiliesPageState();
}

class _FamiliesPageState extends State<FamiliesPage> {
  FamilyFilter _filter = FamilyFilter.all;
  String _search = '';

  List<FamilyModel> _filtered(List<FamilyModel> families) {
    var list = families;
    if (_search.isNotEmpty) {
      list = list.where((f) => f.displayName.toLowerCase().contains(_search.toLowerCase())).toList();
    }
    switch (_filter) {
      case FamilyFilter.separated:
        return list.where((f) => f.isSeparated).toList();
      case FamilyFilter.childrenAlone:
        return list.where((f) => f.hasChildrenAlone).toList();
      case FamilyFilter.complete:
        return list.where((f) => !f.isSeparated && !f.hasChildrenAlone).toList();
      case FamilyFilter.all:
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final families = _filtered(state.currentFamilies);
    final completeCount = state.currentFamilies.where((f) => !f.isSeparated).length;
    final separatedCount = state.currentFamilies.where((f) => f.isSeparated).length;
    final childAloneCount = state.currentFamilies.where((f) => f.hasChildrenAlone).length;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          AppHeader(
            title: 'safepointapp.',
            subtitle: 'Centre d\'hébergement – ${state.currentShelter.name}',
            showBack: true,
            alertCount: state.openAlerts.length,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Familles et regroupement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text('${state.currentFamilies.length} groupes familiaux', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Summary KPIs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _FamilyKpi(icon: Icons.family_restroom, label: 'Complètes', value: completeCount, color: AppColors.purple)),
                const SizedBox(width: 10),
                Expanded(child: _FamilyKpi(icon: Icons.group_off, label: 'Séparées', value: separatedCount, color: AppColors.orange)),
                const SizedBox(width: 10),
                Expanded(child: _FamilyKpi(icon: Icons.child_care, label: 'Enfants seuls', value: childAloneCount, color: AppColors.blue)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher une famille',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Filters
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FChip(label: 'Toutes', filter: FamilyFilter.all, current: _filter, onTap: (f) => setState(() => _filter = f)),
                const SizedBox(width: 8),
                _FChip(label: 'Complètes', filter: FamilyFilter.complete, current: _filter, onTap: (f) => setState(() => _filter = f)),
                const SizedBox(width: 8),
                _FChip(label: 'Séparées', filter: FamilyFilter.separated, current: _filter, onTap: (f) => setState(() => _filter = f)),
                const SizedBox(width: 8),
                _FChip(label: 'Enfants seuls', filter: FamilyFilter.childrenAlone, current: _filter, onTap: (f) => setState(() => _filter = f)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: families.isEmpty
                ? const Center(child: Text('Aucune famille trouvée', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: families.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _FamilyCard(
                      family: families[i],
                      state: state,
                      onTap: () {},
                      onMarkSeparated: () {
                        state.markFamilySeparated(families[i].id, !families[i].isSeparated);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FamilyKpi extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _FamilyKpi({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color, height: 1.1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  final FamilyModel family;
  final AppState state;
  final VoidCallback onTap;
  final VoidCallback onMarkSeparated;

  const _FamilyCard({required this.family, required this.state, required this.onTap, required this.onMarkSeparated});

  Color get _iconBgColor {
    if (family.isSeparated) return AppColors.orangeLight;
    if (family.hasChildrenAlone) return AppColors.redLight;
    return AppColors.purpleLight;
  }

  Color get _iconColor {
    if (family.isSeparated) return AppColors.orangeText;
    if (family.hasChildrenAlone) return AppColors.redText;
    return AppColors.purpleText;
  }

  @override
  Widget build(BuildContext context) {
    final members = state.getFamilyMembers(family.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: _iconBgColor, shape: BoxShape.circle),
                child: Icon(Icons.family_restroom, color: _iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${family.displayName} – ${family.membersCount} personne${family.membersCount > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              FamilyStatusBadge(isSeparated: family.isSeparated, isToVerify: family.hasChildrenAlone),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
            ],
          ),
          if (members.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                ...members.take(4).map((m) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.grayLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.person, size: 18, color: AppColors.grayText),
                )),
                if (family.membersCount > 4)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.blueLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(child: Text('+${family.membersCount - 4}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.blue))),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              const Text(
                'Zone assignée : ',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                family.assignedZone ?? 'Non définie',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
              ),
              const Spacer(),
              const Icon(Icons.group_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${family.membersCount} personne${family.membersCount > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FChip extends StatelessWidget {
  final String label;
  final FamilyFilter filter;
  final FamilyFilter current;
  final Function(FamilyFilter) onTap;

  const _FChip({required this.label, required this.filter, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = filter == current;
    return GestureDetector(
      onTap: () => onTap(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AppColors.navy : AppColors.divider),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }
}
