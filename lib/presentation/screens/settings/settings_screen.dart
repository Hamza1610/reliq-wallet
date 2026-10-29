import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/network_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/payment_claim_provider.dart';
import '../../providers/wallet_providers.dart';
import '../onboarding/welcome_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final walletNotifier = ref.read(walletProvider.notifier);
    final storage = ref.read(secureStorageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSectionHeader('VOICE & ACCESSIBILITY'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Voice Feedback', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: const Text('Speaks balance and payment updates offline', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            activeColor: AppColors.lightningGold,
            value: walletState.isVoiceEnabled,
            onChanged: (val) {
              walletNotifier.toggleVoice();
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Language', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(walletState.language == 'ha' ? 'Hausa' : 'English', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            trailing: DropdownButton<String>(
              value: walletState.language,
              dropdownColor: AppColors.surfaceElevated,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontSize: 14))),
                DropdownMenuItem(value: 'ha', child: Text('Hausa', style: TextStyle(fontSize: 14))),
              ],
              onChanged: (val) {
                if (val != null) {
                  walletNotifier.setLanguage(val);
                }
              },
            ),
          ),
          const Divider(height: 32),

          _buildSectionHeader('SECURITY'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.key_rounded, color: AppColors.textPrimary, size: 20),
            title: const Text('Recovery Phrase', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: const Text('Show your 12-word seed phrase', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
            onTap: () async {
              final mnemonic = await storage.getMnemonic();
              if (context.mounted && mnemonic != null) {
                _showSeedDialog(context, mnemonic);
              }
            },
          ),
          const Divider(height: 32),

          _buildSectionHeader('NETWORK & ENGINE'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Network', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(walletState.network.name.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Esplora Backend', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(NetworkConstants.getEsploraUrl(walletState.network), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rapid Gossip Sync (RGS)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(NetworkConstants.getRgsUrl(walletState.network) ?? 'None', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          const Divider(height: 32),

          _buildSectionHeader('OFFLINE & DEMO TOOLS'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.wifi_off_rounded, color: AppColors.lightningGold, size: 20),
            title: const Text('Simulate Offline Inbound', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: const Text('Simulates LSP waking node & claiming held HTLC', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            trailing: const Icon(Icons.play_arrow_rounded, color: AppColors.lightningGold),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulating offline inbound payment (5,000 sats)...'),
                  duration: Duration(seconds: 2),
                ),
              );
              Navigator.pop(context);
              await ref.read(paymentClaimProvider.notifier).simulateIncomingPayment(
                amountSats: 5000,
                description: 'Market Stall Demo Payment',
              );
            },
          ),
          const Divider(height: 32),

          _buildSectionHeader('DANGER ZONE'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            title: const Text('Reset Wallet', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: const Text('Clears local keys. Requires seed phrase to restore.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            onTap: () => _confirmResetWallet(context, ref),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  void _showSeedDialog(BuildContext context, String mnemonic) {
    final words = mnemonic.split(' ');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
            SizedBox(width: 8),
            Text('Recovery Phrase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Keep this private. Anyone with these words can spend your funds.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(words.length, (idx) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${idx + 1}. ${words[idx]}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  void _confirmResetWallet(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reset Wallet?', style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text(
          'This will permanently delete the private keys from this device. '
          'Ensure you have written down your recovery seed before proceeding.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(walletProvider.notifier).resetWallet();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Reset', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
