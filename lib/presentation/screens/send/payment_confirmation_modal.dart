import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/ldk/ldk_models.dart';
import '../../providers/wallet_providers.dart';
import '../../widgets/reliq_button.dart';

class PaymentConfirmationModal extends ConsumerStatefulWidget {
  final String invoice;
  final DecodedInvoice decoded;

  const PaymentConfirmationModal({
    super.key,
    required this.invoice,
    required this.decoded,
  });

  static Future<PaymentResult?> show(
    BuildContext context, {
    required String invoice,
    required DecodedInvoice decoded,
  }) {
    return showModalBottomSheet<PaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentConfirmationModal(
        invoice: invoice,
        decoded: decoded,
      ),
    );
  }

  @override
  ConsumerState<PaymentConfirmationModal> createState() =>
      _PaymentConfirmationModalState();
}

class _PaymentConfirmationModalState
    extends ConsumerState<PaymentConfirmationModal> {
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _executePayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final ldk = ref.read(ldkNodeServiceProvider);
      final result = await ldk.sendPayment(widget.invoice);

      if (result.isSuccess) {
        ref.read(walletProvider.notifier).refreshBalance();
        if (mounted) {
          Navigator.pop(context, result);
        }
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Payment dispatch failed';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final spendableSats = walletState.balance.lightningSats;
    final totalRequiredSats = widget.decoded.amountSats + 2; // + 2 sat fee ceiling
    final hasSufficientBalance = spendableSats >= totalRequiredSats;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Confirm Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt, color: AppColors.lightningGold, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Lightning',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount Hero Section
            Center(
              child: Column(
                children: [
                  Text(
                    Formatters.formatSats(widget.decoded.amountSats),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1.0,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.decoded.description.isEmpty
                        ? 'Lightning Payment'
                        : widget.decoded.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Max Network Fee',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      Text(
                        '2 sats',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Balance',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      Text(
                        Formatters.formatSats(spendableSats),
                        style: TextStyle(
                          color: hasSufficientBalance
                              ? AppColors.textPrimary
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (!hasSufficientBalance) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.error, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Insufficient spendable Lightning balance.',
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            ReliqButton(
              label: 'Confirm & Send',
              variant: ReliqButtonVariant.primary,
              isLoading: _isProcessing,
              onTap: (hasSufficientBalance && !_isProcessing) ? _executePayment : null,
            ),
          ],
        ),
      ),
    );
  }
}
