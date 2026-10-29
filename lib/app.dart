import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/wallet_providers.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/onboarding/welcome_screen.dart';

class ReliqApp extends ConsumerWidget {
  const ReliqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Reliq',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: _buildHome(walletState),
    );
  }

  Widget _buildHome(WalletState state) {
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.lightningGold.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lightningGold, width: 2),
                ),
                child: const Icon(
                  Icons.bolt,
                  size: 44,
                  color: AppColors.lightningGold,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: AppColors.lightningGold,
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 16),
              const Text(
                'Starting Reliq Engine...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.hasWallet) {
      return const HomeScreen();
    }

    return const WelcomeScreen();
  }
}
