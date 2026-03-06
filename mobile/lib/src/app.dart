import 'package:family_digital_heritage_vault/src/core/theme/app_theme.dart';
import 'package:family_digital_heritage_vault/src/features/auth/presentation/login_screen.dart';
import 'package:family_digital_heritage_vault/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:family_digital_heritage_vault/src/features/auth/state/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FamilyVaultApp extends StatelessWidget {
  const FamilyVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Family Digital Heritage Vault',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: auth.isAuthenticated ? const DashboardScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
