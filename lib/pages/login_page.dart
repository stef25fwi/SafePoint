import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_routes.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/crisis_banner.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _agentCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _error;
  String _selectedShelterId = 'shelter_1';

  final List<Map<String, String>> _shelters = [
    {'id': 'shelter_1', 'name': 'Gymnase de Baie-Mahault'},
    {'id': 'shelter_2', 'name': 'Centre de Capesterre'},
    {'id': 'shelter_3', 'name': 'Salle de Basse-Terre'},
  ];

  @override
  void dispose() {
    _agentCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_agentCodeController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    context.read<AppState>().login(_agentCodeController.text, _selectedShelterId);
    Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
  }

  Future<void> _enableOfflineMode() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    context.read<AppState>().login('offline', _selectedShelterId, offline: true);
    Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Logo + Title
              const Column(
                children: [
                  VolcanoLogo(size: 80),
                  SizedBox(height: 16),
                  Text(
                    'safepointapp.',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Accès sécurisé – Gestion de crise',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const CrisisBanner(label: 'Événement actif : Éruption volcanique – Soufrière'),
              const SizedBox(height: 20),

              // Form card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Agent code
                      const Text('Code agent', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _agentCodeController,
                        decoration: const InputDecoration(
                          hintText: 'Entrez votre code agent',
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      const Text('Mot de passe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Entrez votre mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _signIn(),
                      ),
                      const SizedBox(height: 16),

                      // Shelter selector
                      const Text('Centre affecté', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedShelterId,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                            items: _shelters.map((s) {
                              return DropdownMenuItem<String>(
                                value: s['id'],
                                child: Row(
                                  children: [
                                    const Icon(Icons.business_outlined, size: 18, color: AppColors.blue),
                                    const SizedBox(width: 10),
                                    Text(s['name']!, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedShelterId = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Remember + forgot
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v!),
                              activeColor: AppColors.blue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Se souvenir de moi', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                          const Spacer(),
                          GestureDetector(
                            child: const Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(fontSize: 13, color: AppColors.blue, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
                      ],
                      const SizedBox(height: 20),

                      // Sign in button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Se connecter'),
                      ),
                      const SizedBox(height: 12),

                      // Offline button
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _enableOfflineMode,
                        icon: const Icon(Icons.wifi_off_outlined),
                        label: const Text('Mode hors connexion'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Info features
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Column(
                    children: [
                      _FeatureItem(
                        icon: Icons.shield_outlined,
                        color: AppColors.blue,
                        title: 'Connexion sécurisée',
                        subtitle: 'Vos données sont protégées et chiffrées.',
                      ),
                      SizedBox(height: 14),
                      _FeatureItem(
                        icon: Icons.sync,
                        color: AppColors.green,
                        title: 'Synchronisation automatique',
                        subtitle: 'Les données sont mises à jour en temps réel.',
                      ),
                      SizedBox(height: 14),
                      _FeatureItem(
                        icon: Icons.wifi_outlined,
                        color: AppColors.orange,
                        title: 'Utilisable hors ligne',
                        subtitle: 'Accédez aux fonctionnalités essentielles sans réseau.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
