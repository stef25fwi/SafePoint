import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/app_routes.dart';
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
          routes: {
            AppRoutes.login: (_) => const LoginPage(),
            AppRoutes.shell: (_) => const MainShellPage(),
            AppRoutes.personForm: (_) => const PersonFormPage(),
            AppRoutes.personDetail: (_) => const PersonDetailPage(),
            AppRoutes.families: (_) => const FamiliesPage(),
            AppRoutes.transfers: (_) => const TransfersPage(),
            AppRoutes.createTransfer: (_) => const CreateTransferPage(),
            AppRoutes.crisisActivation: (_) => const CrisisActivationPage(),
            AppRoutes.shelterDetail: (_) => const ShelterDetailPage(),
            AppRoutes.agentGenerator: (_) => const AgentGeneratorPage(),
          },
        ),
      ),
    );
  }
}
