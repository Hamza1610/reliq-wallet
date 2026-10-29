import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/reliq_button.dart';
import 'create_wallet_screen.dart';
import 'restore_wallet_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Minimal Brand Mark
              const Text(
                'Reliq',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Self-custodial Lightning for everyday reliability',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 36),

              // Clean minimalist features list
              _buildFeatureRow(
                icon: Icons.shield_outlined,
                title: 'Self-custodial',
                subtitle: 'Keys stay encrypted on your device. Only you control your money.',
              ),
              const SizedBox(height: 20),
              _buildFeatureRow(
                icon: Icons.offline_bolt_outlined,
                title: 'Offline receive ready',
                subtitle: 'Accepts inbound payments and settles when your connection resumes.',
              ),
              const SizedBox(height: 20),
              _buildFeatureRow(
                icon: Icons.record_voice_over_outlined,
                title: 'Voice accessibility',
                subtitle: 'Clear audio confirmations in Hausa and English for trades.',
              ),

              const Spacer(flex: 3),

              // Action buttons
              ReliqButton(
                label: 'Create New Wallet',
                icon: Icons.arrow_forward_rounded,
                variant: ReliqButtonVariant.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateWalletScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              ReliqButton(
                label: 'Restore Existing Wallet',
                variant: ReliqButtonVariant.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RestoreWalletScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.lightningGold,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
