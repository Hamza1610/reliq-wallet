import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/ldk/ldk_models.dart';
import '../../../data/push/push_models.dart';
import '../../../data/storage/payment_history_service.dart';
import '../../providers/payment_claim_provider.dart';
import '../../providers/tts_provider.dart';
import '../../providers/wallet_providers.dart';
import '../../widgets/reliq_button.dart';
import '../activity/activity_screen.dart';
import '../receive/receive_screen.dart';
import '../send/send_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PaymentHistoryService _historyService = PaymentHistoryService();
  List<PaymentActivity> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final list = await _historyService.getActivities();
    if (mounted) {
      setState(() {
        _recentActivity = list.take(5).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<ActivePaymentClaim>>(paymentClaimProvider, (prev, next) {
      if (next.any((c) => c.isSucceeded)) {
        _loadRecent();
      }
    });

    final walletState = ref.watch(walletProvider);
    final walletNotifier = ref.read(walletProvider.notifier);
    final activeClaims = ref.watch(paymentClaimProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Reliq',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                walletState.network.name.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              walletState.isVoiceEnabled
                  ? Icons.volume_up_outlined
                  : Icons.volume_off_outlined,
              color: walletState.isVoiceEnabled
                  ? AppColors.lightningGold
                  : AppColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Toggle Voice Feedback',
            onPressed: () {
              walletNotifier.toggleVoice();
              final isEnabled = !walletState.isVoiceEnabled;
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEnabled
                        ? 'Voice feedback enabled (${walletState.language.toUpperCase()})'
                        : 'Voice feedback muted',
                  ),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Intermittent Claim Banner
            if (activeClaims.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: activeClaims.map((claim) {
                    final isClaiming = claim.isClaiming || claim.isPending;
                    final isSuccess = claim.isSucceeded;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? AppColors.success.withOpacity(0.12)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSuccess
                              ? AppColors.success.withOpacity(0.3)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isClaiming)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.lightningGold,
                              ),
                            )
                          else if (isSuccess)
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: AppColors.success,
                            )
                          else
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: AppColors.error,
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isClaiming
                                      ? 'Claiming Offline Payment...'
                                      : isSuccess
                                          ? 'Payment Claimed'
                                          : 'Claim Failed',
                                  style: TextStyle(
                                    color: isSuccess
                                        ? AppColors.success
                                        : AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${Formatters.formatSats(claim.amountSats)} · ${claim.description}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (!isClaiming)
                            GestureDetector(
                              onTap: () {
                                ref
                                    .read(paymentClaimProvider.notifier)
                                    .dismissClaim(claim.paymentHash);
                                _loadRecent();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Top Section: Hero Balance & Quick Voice Readout
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: InkWell(
                onTap: () {
                  final tts = ref.read(ttsServiceProvider);
                  tts.speakBalance(walletState.balance.totalSats);

                  final text = walletState.language == 'ha'
                      ? 'Kudaden ku sun kai sats ${Formatters.formatSats(walletState.balance.totalSats)}'
                      : 'Your balance is ${Formatters.formatSats(walletState.balance.totalSats)}';
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.volume_up,
                              color: AppColors.lightningGold, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(text)),
                        ],
                      ),
                      backgroundColor: AppColors.surfaceElevated,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Balance',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.volume_up_outlined,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.formatSats(walletState.balance.totalSats),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 38,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1.0,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '⚡ ${Formatters.formatSats(walletState.balance.lightningSats)}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (walletState.balance.onchainSats > 0) ...[
                            const SizedBox(width: 12),
                            Text(
                              '⛓ ${Formatters.formatSats(walletState.balance.onchainSats)}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Primary Action Row: Receive & Send
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ReliqButton(
                      label: 'Receive',
                      icon: Icons.arrow_downward_rounded,
                      variant: ReliqButtonVariant.primary,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReceiveScreen(),
                          ),
                        );
                        _loadRecent();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ReliqButton(
                      label: 'Send',
                      icon: Icons.arrow_upward_rounded,
                      variant: ReliqButtonVariant.secondary,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SendScreen(),
                          ),
                        );
                        _loadRecent();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Activity Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ActivityScreen(),
                        ),
                      );
                      _loadRecent();
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Activity List or Clean Empty State
            Expanded(
              child: _recentActivity.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 32,
                            color: AppColors.textMuted.withOpacity(0.5),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No transactions yet',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      itemCount: _recentActivity.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tx = _recentActivity[index];
                        final isReceived = tx.isReceived;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isReceived
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  size: 16,
                                  color: isReceived
                                      ? AppColors.success
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isReceived ? 'Received' : 'Sent',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tx.description.isEmpty
                                          ? (isReceived ? 'Invoice paid' : 'Payment')
                                          : tx.description,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isReceived ? '+' : '-'} ${Formatters.formatSats(tx.amountSats)}',
                                style: TextStyle(
                                  color: isReceived
                                      ? AppColors.success
                                      : AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Minimal Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: walletState.isNodeRunning
                              ? AppColors.success
                              : AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        walletState.isNodeRunning ? 'LDK Node active' : 'Syncing...',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Self-Custodial',
                    style: TextStyle(
                      color: AppColors.textMuted.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
