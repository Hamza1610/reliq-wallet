import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'create_wallet_screen.dart';
import 'restore_wallet_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.lightningGold.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lightningGold, width: 2.5),
                  ),
                  child: const Icon(
                    Icons.bolt,
                    size: 64,
                    color: AppColors.lightningGold,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Reliq',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Self-Custodial Lightning for Everyday Reliability',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(Icons.lock_outline, '100% Self-Custodial (Your Keys)'),
                    const SizedBox(height: 12),
                    _buildFeatureItem(Icons.wifi_off_outlined, 'Built for Intermittent Connectivity'),
                    const SizedBox(height: 12),
                    _buildFeatureItem(Icons.record_voice_over_outlined, 'Offline Voice in English & Hausa'),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateWalletScreen(),
                    ),
                  );
                },
                child: const Text('Create New Wallet'),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RestoreWalletScreen(),
                    ),
                  );
                },
                child: const Text('Restore Existing Wallet'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.lightningGold, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
