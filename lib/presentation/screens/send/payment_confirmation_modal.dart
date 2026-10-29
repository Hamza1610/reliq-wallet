import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/ldk/ldk_models.dart';
import '../../providers/wallet_providers.dart';

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
        // Refresh balance immediately
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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Confirm Payment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sendIndigoSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt, color: AppColors.sendIndigo, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Lightning',
                        style: TextStyle(
                          color: AppColors.sendIndigo,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text(
                    'YOU ARE PAYING',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.formatSats(widget.decoded.amountSats),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'For: ${widget.decoded.description}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Fee and Balance Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Network Fee Ceiling:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text('+2 sats', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Spendable Balance:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(Formatters.formatSats(spendableSats),
                    style: TextStyle(
                      color: hasSufficientBalance ? AppColors.textPrimary : AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    )),
              ],
            ),

            if (!hasSufficientBalance) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Insufficient spendable Lightning balance.',
                        style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sendIndigo,
                foregroundColor: Colors.white,
              ),
              onPressed: (hasSufficientBalance && !_isProcessing) ? _executePayment : null,
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Confirm & Send Now'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
