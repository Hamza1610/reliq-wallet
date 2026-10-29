import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/network_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/nearby/nearby_models.dart';
import '../../providers/currency_provider.dart';
import '../../providers/nearby_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/wallet_providers.dart';
import '../onboarding/welcome_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final walletNotifier = ref.read(walletProvider.notifier);
    final storage = ref.read(secureStorageProvider);
    final themeMode = ref.watch(themeProvider);
    final currencyState = ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSectionHeader('APPEARANCE & THEME'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppColors.lightningGold,
              size: 20,
            ),
            title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(themeMode == ThemeMode.dark ? 'Dark Mode (Charcoal)' : 'Light Mode (Clean White)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              activeColor: AppColors.lightningGold,
              onChanged: (_) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            ),
          ),
          const Divider(height: 32),

          _buildSectionHeader('CURRENCY & PRICING'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.lightningGold, size: 20),
            title: const Text('Primary Currency', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(currencyState.isNgn ? 'Everyday Mode (₦ Nigerian Naira)' : 'Pro Bitcoin Mode (⚡ Satoshis)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            trailing: Switch(
              value: currencyState.isNgn,
              activeColor: AppColors.lightningGold,
              onChanged: (_) {
                ref.read(currencyProvider.notifier).toggleMode();
              },
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('NGN Exchange Rate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(
              currencyState.ngnRatePerSat != null
                  ? '₦ ${(currencyState.ngnRatePerSat! * 100000000).toStringAsFixed(0)} / BTC (₦ ${currencyState.ngnRatePerSat!.toStringAsFixed(2)} / sat)'
                  : 'No rate loaded. Tap to refresh or set custom.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.lightningGold),
              onPressed: () async {
                await ref.read(currencyProvider.notifier).fetchLiveRate();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refreshed live exchange rate')),
                  );
                }
              },
            ),
            onTap: () => _showCustomRateDialog(context, ref),
          ),
          const Divider(height: 32),

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

          _buildSectionHeader('TESTING & FAUCET'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.electric_bolt_rounded, color: AppColors.lightningGold, size: 20),
            title: const Text('Fund Wallet (+100,000 sats)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: const Text('Credits permanent test funds directly to your wallet', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            onTap: () async {
              await walletNotifier.fundWallet(
                amountSats: 100000,
                isOnchain: true,
                note: 'Regtest Faucet Funding',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funded +100,000 sats permanently!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bluetooth_connected_rounded, color: AppColors.lightningGold, size: 20),
            title: const Text('Test Nearby Confirm (Bluetooth)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: const Text('Tests signed Bluetooth confirmation reception', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            onTap: () {
              final payload = NearbyPayload.create(
                paymentHash: 'test_${DateTime.now().millisecondsSinceEpoch}',
                amountMsat: 5000 * 1000,
                senderId: 'Reliq_Merchant_Stall',
              );
              ref.read(nearbyConfirmServiceProvider).deliverPayloadForTesting(payload);
              Navigator.pop(context);
            },
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

  void _showCustomRateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Set NGN Rate per Sat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter rate in Naira (e.g. 1.50 for ₦1.50/sat or ₦150,000,000/BTC):',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '1.50',
                prefixText: '₦ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                ref.read(currencyProvider.notifier).setCustomRate(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
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
            Icon(Icons.shield_outlined, color: AppColors.lightningGold, size: 22),
            SizedBox(width: 8),
            Text('Recovery Phrase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Write down these 12 words in order and keep them in a safe place. Anyone with these words can access your funds.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(words.length, (i) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${i + 1}. ${words[i]}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
            child: const Text('Close', style: TextStyle(color: AppColors.lightningGold, fontWeight: FontWeight.w600)),
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
        title: const Text('Reset Wallet?', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
        content: const Text(
          'This will delete your local wallet keys. You will lose your funds unless you have backed up your 12-word recovery phrase.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
            child: const Text('Reset', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
