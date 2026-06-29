import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_routes.dart';
import '../models/person_model.dart';
import '../models/enums.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/person_card.dart';

class PersonsPage extends StatefulWidget {
  const PersonsPage({super.key});

  @override
  State<PersonsPage> createState() => _PersonsPageState();
}

class _PersonsPageState extends State<PersonsPage> {
  PersonFilter _filter = PersonFilter.all;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PersonModel> _filteredPersons(AppState state) {
    var persons = state.allPersons;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      persons = persons.where((p) =>
        p.fullName.toLowerCase().contains(q) ||
        (p.originCommune?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    switch (_filter) {
      case PersonFilter.present:
        return persons.where((p) => p.status == PersonStatus.present).toList();
      case PersonFilter.vulnerable:
        return persons.where((p) => p.isVulnerable).toList();
      case PersonFilter.families:
        return persons.where((p) => p.familyId != null).toList();
      case PersonFilter.notChecked:
        return persons.where((p) => p.status == PersonStatus.nonPointee).toList();
      case PersonFilter.all:
        return persons;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final persons = _filteredPersons(state);
    final alertCount = state.openAlerts.length;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          AppHeader(
            title: 'Personnes recensées',
            subtitle: 'Centre : ${state.currentShelter.name}',
            alertCount: alertCount,
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher une personne',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(label: 'Tous', filter: PersonFilter.all, current: _filter, onTap: (f) => setState(() => _filter = f)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Présents', filter: PersonFilter.present, current: _filter, dot: AppColors.green, onTap: (f) => setState(() => _filter = f)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Vulnérables', filter: PersonFilter.vulnerable, current: _filter, dot: AppColors.orange, onTap: (f) => setState(() => _filter = f)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Familles', filter: PersonFilter.families, current: _filter, dot: AppColors.purple, onTap: (f) => setState(() => _filter = f)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Non pointés', filter: PersonFilter.notChecked, current: _filter, dot: AppColors.grayText, onTap: (f) => setState(() => _filter = f)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: persons.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search, size: 48, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text('Aucune personne trouvée', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: persons.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 82),
                    itemBuilder: (ctx, i) => PersonCard(
                      person: persons[i],
                      onTap: () => Navigator.pushNamed(ctx, AppRoutes.personDetail, arguments: persons[i].id),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.personForm),
        backgroundColor: AppColors.navy,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final PersonFilter filter;
  final PersonFilter current;
  final Color? dot;
  final Function(PersonFilter) onTap;

  const _FilterChip({
    required this.label,
    required this.filter,
    required this.current,
    this.dot,
    required this.onTap,
  });

  bool get isSelected => filter == current;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.navy : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null && !isSelected) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
