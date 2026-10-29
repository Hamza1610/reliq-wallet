import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/network_constants.dart';
import '../../../core/theme/app_theme.dart';
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
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSectionHeader('VOICE & ACCESSIBILITY'),
          SwitchListTile(
            title: const Text('Voice Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Speaks balance and payment updates offline'),
            activeColor: AppColors.lightningGold,
            value: walletState.isVoiceEnabled,
            onChanged: (val) {
              walletNotifier.toggleVoice();
            },
          ),
          ListTile(
            title: const Text('Voice Language', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(walletState.language == 'ha' ? 'Hausa' : 'English'),
            trailing: DropdownButton<String>(
              value: walletState.language,
              dropdownColor: AppColors.surfaceElevated,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ha', child: Text('Hausa')),
              ],
              onChanged: (val) {
                if (val != null) {
                  walletNotifier.setLanguage(val);
                }
              },
            ),
          ),
          const Divider(color: AppColors.border, height: 32),

          _buildSectionHeader('SECURITY'),
          ListTile(
            leading: const Icon(Icons.key_rounded, color: AppColors.voiceAmber),
            title: const Text('View Recovery Phrase', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Show your 12-word seed phrase'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final mnemonic = await storage.getMnemonic();
              if (context.mounted && mnemonic != null) {
                _showSeedDialog(context, mnemonic);
              }
            },
          ),
          const Divider(color: AppColors.border, height: 32),

          _buildSectionHeader('NETWORK & ENGINE'),
          ListTile(
            title: const Text('Network', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(walletState.network.name.toUpperCase()),
          ),
          ListTile(
            title: const Text('Esplora Backend', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(NetworkConstants.getEsploraUrl(walletState.network)),
          ),
          ListTile(
            title: const Text('Rapid Gossip Sync (RGS)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(NetworkConstants.getRgsUrl(walletState.network) ?? 'None'),
          ),
          const Divider(color: AppColors.border, height: 32),

          _buildSectionHeader('DANGER ZONE'),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
            title: const Text(
              'Reset & Wipe Wallet',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Permanently deletes keys from this device'),
            onTap: () {
              _showResetDialog(context, ref);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
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
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.voiceAmber),
            SizedBox(width: 8),
            Text('Recovery Phrase'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Make sure nobody is watching your screen. Anyone with these words can steal your funds.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(words.length, (i) {
                    return Chip(
                      label: Text('${i + 1}. ${words[i]}'),
                      backgroundColor: AppColors.surfaceElevated,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Wipe Wallet?'),
        content: const Text(
          'Are you sure you want to delete your wallet from this device? Make sure you have your 12-word seed written down or your funds will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final storage = ref.read(secureStorageProvider);
              final ldk = ref.read(ldkNodeServiceProvider);
              await storage.deleteWallet();
              ldk.dispose();

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Wipe & Reset'),
          ),
        ],
      ),
    );
  }
}
