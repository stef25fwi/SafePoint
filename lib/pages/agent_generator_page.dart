import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/app_colors.dart';
import '../models/enums.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';

class AgentGeneratorPage extends StatefulWidget {
  const AgentGeneratorPage({super.key});

  @override
  State<AgentGeneratorPage> createState() => _AgentGeneratorPageState();
}

class _AgentGeneratorPageState extends State<AgentGeneratorPage> {
  final _displayNameCtrl = TextEditingController();
  UserRole? _selectedRole;
  String? _generatedCode;
  String? _generatedPassword;
  bool _showPassword = false;

  final Map<UserRole, String> _roleLabels = {
    UserRole.superAdmin: 'Super Admin',
    UserRole.prefectureAdmin: 'Préfecture / COD',
    UserRole.regionAdmin: 'Région',
    UserRole.communeAdmin: 'Mairie / Commune',
    UserRole.refugeManager: 'Responsable centre',
    UserRole.agent: 'Agent accueil',
    UserRole.readOnlyObserver: 'Observateur',
    UserRole.crisisCell: 'Cellule de crise',
    UserRole.auditor: 'Auditeur',
  };

  List<UserRole> _getAvailableRoles(UserRole currentRole) {
    switch (currentRole) {
      case UserRole.superAdmin:
        return UserRole.values.toList();
      case UserRole.prefectureAdmin:
      case UserRole.regionAdmin:
        return [
          UserRole.regionAdmin,
          UserRole.communeAdmin,
          UserRole.refugeManager,
          UserRole.agent,
          UserRole.readOnlyObserver,
          UserRole.crisisCell,
          UserRole.auditor,
        ];
      case UserRole.communeAdmin:
        return [
          UserRole.refugeManager,
          UserRole.agent,
          UserRole.readOnlyObserver,
        ];
      case UserRole.refugeManager:
        return [UserRole.agent, UserRole.readOnlyObserver];
      default:
        return [];
    }
  }

  void _generateCode() {
    if (_displayNameCtrl.text.isEmpty || _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir le nom et sélectionner un rôle'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    const uuid = Uuid();
    final code = 'AG${uuid.v4().substring(0, 8).toUpperCase()}';
    final password = _generateRandomPassword();

    setState(() {
      _generatedCode = code;
      _generatedPassword = password;
      _showPassword = true;
    });
  }

  String _generateRandomPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%';
    final random = List<int>.generate(12, (_) => _random.nextInt(chars.length));
    return random.map((i) => chars[i]).join();
  }

  final _random = Random();

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copié dans le presse-papiers'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _printCode() {
    // TODO: Implémenter l'impression avec la package 'printing'
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impression en cours...'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final availableRoles = _getAvailableRoles(state.currentRole);
    final canCreate = availableRoles.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(
              title: 'safepointapp.',
              subtitle: 'Générateur de compte agent',
              showBack: true,
              showNotification: false,
            ),
            if (!canCreate)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.red),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outlined, color: AppColors.red, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vous n\'avez pas la permission de créer des comptes agents.',
                          style: TextStyle(color: AppColors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Créer un nouveau compte agent',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _displayNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nom complet *',
                          prefixIcon: Icon(Icons.person_outline),
                          hintText: 'Ex : Jean DUPONT',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Rôle d\'accès *',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<UserRole>(
                            value: _selectedRole,
                            isExpanded: true,
                            hint: const Padding(
                              padding: EdgeInsets.only(left: 12),
                              child: Text('Sélectionner un rôle'),
                            ),
                            items: availableRoles.map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(_roleLabels[role] ?? role.name),
                                ),
                              );
                            }).toList(),
                            onChanged: canCreate ? (v) => setState(() => _selectedRole = v) : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_generatedCode == null)
                        ElevatedButton.icon(
                          onPressed: _generateCode,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Générer un compte'),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.greenLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.green),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '✓ Compte généré avec succès',
                                    style: TextStyle(
                                      color: AppColors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _CodeField(
                                    label: 'Code agent',
                                    value: _generatedCode!,
                                    onCopy: _copyToClipboard,
                                  ),
                                  const SizedBox(height: 12),
                                  _PasswordField(
                                    label: 'Mot de passe temporaire',
                                    value: _generatedPassword!,
                                    showPassword: _showPassword,
                                    onToggleVisibility: () => setState(() => _showPassword = !_showPassword),
                                    onCopy: _copyToClipboard,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '⚠️ Le mot de passe s\'affiche une seule fois. Notez-le ou copiez-le maintenant.',
                                    style: TextStyle(fontSize: 12, color: AppColors.orange),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _printCode,
                                    icon: const Icon(Icons.print),
                                    label: const Text('Imprimer'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => setState(() => _generatedCode = null),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Nouveau'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CodeField extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onCopy;

  const _CodeField({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.content_copy_outlined, size: 18),
            onPressed: () => onCopy(value),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final String value;
  final bool showPassword;
  final VoidCallback onToggleVisibility;
  final Function(String) onCopy;

  const _PasswordField({
    required this.label,
    required this.value,
    required this.showPassword,
    required this.onToggleVisibility,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  showPassword ? value : '•' * value.length,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
            ),
            onPressed: onToggleVisibility,
          ),
          IconButton(
            icon: const Icon(Icons.content_copy_outlined, size: 18),
            onPressed: () => onCopy(value),
          ),
        ],
      ),
    );
  }
}
