import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/app_routes.dart';
import 'core/responsive.dart';
import 'services/app_state.dart';
import 'pages/login_page.dart';
import 'pages/main_shell_page.dart';
import 'pages/person_form_page.dart';
import 'pages/person_detail_page.dart';
import 'pages/families_page.dart';
import 'pages/transfers_page.dart';
import 'pages/create_transfer_page.dart';
import 'pages/crisis_activation_page.dart';
import 'pages/shelter_detail_page.dart';
import 'pages/agent_generator_page.dart';
import 'pages/analytics_page.dart';

class SafePointApp extends StatelessWidget {
  const SafePointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (ctx, state, _) => MaterialApp(
          title: 'safepointapp.',
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          initialRoute: state.isLoggedIn ? AppRoutes.shell : AppRoutes.login,
          // Le shell gère sa propre responsivité (rail desktop / bottom nav
          // mobile). Les pages autonomes sont centrées et bornées sur grand
          // écran via ResponsiveAppFrame ; sur mobile, c'est un passe-plat.
          routes: {
            AppRoutes.login: (_) => const ResponsiveAppFrame(child: LoginPage()),
            AppRoutes.shell: (_) => const MainShellPage(),
            AppRoutes.personForm: (_) =>
                const ResponsiveAppFrame(child: PersonFormPage()),
            AppRoutes.personDetail: (_) =>
                const ResponsiveAppFrame(child: PersonDetailPage()),
            AppRoutes.families: (_) =>
                const ResponsiveAppFrame(child: FamiliesPage()),
            AppRoutes.transfers: (_) =>
                const ResponsiveAppFrame(child: TransfersPage()),
            AppRoutes.createTransfer: (_) =>
                const ResponsiveAppFrame(child: CreateTransferPage()),
            AppRoutes.crisisActivation: (_) =>
                const ResponsiveAppFrame(child: CrisisActivationPage()),
            AppRoutes.shelterDetail: (_) =>
                const ResponsiveAppFrame(child: ShelterDetailPage()),
            AppRoutes.agentGenerator: (_) =>
                const ResponsiveAppFrame(child: AgentGeneratorPage()),
            AppRoutes.analytics: (_) =>
                const ResponsiveAppFrame(maxWidth: 1100, child: AnalyticsPage()),
          },
        ),
      ),
    );
  }
}
