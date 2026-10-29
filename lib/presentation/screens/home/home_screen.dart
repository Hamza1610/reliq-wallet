import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/tts/voice_prompts.dart';
import '../../providers/wallet_providers.dart';
import '../../widgets/large_action_button.dart';
import '../activity/activity_screen.dart';
import '../receive/receive_screen.dart';
import '../send/send_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final walletNotifier = ref.read(walletProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.lightningGold.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt,
                color: AppColors.lightningGold,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Reliq'),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                walletState.network.name.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.lightningGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Phase 3: LSP Sync & Background Claim Banner
              if (walletState.lspSyncStatus != null || walletState.isSyncingLsp) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: walletState.isSyncingLsp
                        ? AppColors.surfaceElevated
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: walletState.isSyncingLsp
                          ? AppColors.lightningGold.withOpacity(0.4)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (walletState.isSyncingLsp)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.lightningGold,
                          ),
                        )
                      else
                        const Icon(
                          Icons.cloud_done,
                          color: AppColors.success,
                          size: 16,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          walletState.isSyncingLsp
                              ? 'Syncing with LSP in background...'
                              : (walletState.lspSyncStatus ?? 'LSP Connected'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!walletState.isSyncingLsp)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.refresh, size: 16, color: AppColors.lightningGold),
                          onPressed: () => walletNotifier.syncLspPendingPayments(),
                        ),
                    ],
                  ),
                ),
              ],

              // Balance Display Area (Tap to speak)
              InkWell(
                onTap: () {
                  walletNotifier.speakCurrentBalance();
                  final text = VoicePrompts.balance(
                    walletState.balance.totalSats,
                    walletState.language,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.volume_up, color: AppColors.lightningGold),
                          const SizedBox(width: 12),
                          Expanded(child: Text(text)),
                        ],
                      ),
                      backgroundColor: AppColors.surfaceElevated,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E232E), Color(0xFF151922)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.lightningGold.withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'TOTAL BALANCE',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.formatSats(walletState.balance.totalSats),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.volume_up_outlined,
                            size: 16,
                            color: AppColors.lightningGold,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(tap to hear)',
                            style: TextStyle(
                              color: AppColors.lightningGold.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMiniBalance(
                            'Lightning',
                            Formatters.formatSats(walletState.balance.lightningSats),
                            AppColors.lightningGold,
                          ),
                          const SizedBox(width: 16),
                          Container(width: 1, height: 16, color: AppColors.border),
                          const SizedBox(width: 16),
                          _buildMiniBalance(
                            'On-Chain (BDK)',
                            Formatters.formatSats(walletState.balance.onchainSats),
                            AppColors.activityBlue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // The 4 Action Blocks (2x2 Grid)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: LargeActionButton(
                              title: 'RECEIVE',
                              subtitle: 'Generate QR',
                              icon: Icons.qr_code_2_rounded,
                              accentColor: AppColors.receiveGreen,
                              surfaceColor: AppColors.receiveGreenSurface,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ReceiveScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: LargeActionButton(
                              title: 'SEND',
                              subtitle: 'Scan or Paste',
                              icon: Icons.arrow_outward_rounded,
                              accentColor: AppColors.sendIndigo,
                              surfaceColor: AppColors.sendIndigoSurface,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SendScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: LargeActionButton(
                              title: 'ACTIVITY',
                              subtitle: 'History',
                              icon: Icons.history_rounded,
                              accentColor: AppColors.activityBlue,
                              surfaceColor: AppColors.activityBlueSurface,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ActivityScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: LargeActionButton(
                              title: 'VOICE',
                              subtitle: walletState.isVoiceEnabled
                                  ? 'ACTIVE (${walletState.language.toUpperCase()})'
                                  : 'MUTED',
                              icon: walletState.isVoiceEnabled
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              accentColor: AppColors.voiceAmber,
                              surfaceColor: AppColors.voiceAmberSurface,
                              onTap: () {
                                walletNotifier.toggleVoice();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Node status footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: walletState.isNodeRunning ? AppColors.success : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      walletState.isNodeRunning
                          ? 'LDK + BDK Engine Online'
                          : 'Node Syncing...',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBalance(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
