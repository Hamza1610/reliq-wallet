import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/ldk/ldk_models.dart';
import '../../providers/currency_provider.dart';
import '../../providers/wallet_providers.dart';
import '../../widgets/reliq_button.dart';

class OnchainConfirmationModal extends ConsumerStatefulWidget {
  final String address;

  const OnchainConfirmationModal({
    super.key,
    required this.address,
  });

  static Future<PaymentResult?> show(
    BuildContext context, {
    required String address,
  }) {
    return showModalBottomSheet<PaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OnchainConfirmationModal(address: address),
    );
  }

  @override
  ConsumerState<OnchainConfirmationModal> createState() =>
      _OnchainConfirmationModalState();
}

class _OnchainConfirmationModalState
    extends ConsumerState<OnchainConfirmationModal> {
  final TextEditingController _amountController = TextEditingController(text: '10000');
  final int _feeSats = 141; // Typical Native SegWit fee
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _executeOnchain() async {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid satoshi amount');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await ref.read(walletProvider.notifier).sendOnchainPayment(
            address: widget.address,
            amountSats: amount,
            feeRateSatPerVb: 1,
            note: 'On-chain Transfer',
          );

      if (mounted) {
        if (result.isSuccess) {
          Navigator.pop(context, result);
        } else {
          setState(() {
            _errorMessage = result.error ?? 'Transaction failed';
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final currencyState = ref.watch(currencyProvider);
    final onchainSats = walletState.balance.onchainSats;
    final enteredAmount = int.tryParse(_amountController.text) ?? 0;
    final totalRequired = enteredAmount + _feeSats;
    final hasSufficient = onchainSats >= totalRequired;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.link_rounded, color: AppColors.lightningGold, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Bitcoin On-Chain Transfer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Destination Address Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECIPIENT ADDRESS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  widget.address,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Amount Input
          const Text(
            'AMOUNT (SATOSHIS)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceElevated,
              hintText: 'Enter satoshis',
              suffixText: 'sats',
              suffixStyle: const TextStyle(fontWeight: FontWeight.w600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),

          // Quick Amount Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [5000, 10000, 25000, 50000].map((amt) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(
                      currencyState.isNgn && currencyState.ngnRatePerSat != null
                          ? Formatters.formatNgn(amt * currencyState.ngnRatePerSat!)
                          : '${amt ~/ 1000}k sats',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppColors.surfaceElevated,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: () {
                      setState(() {
                        _amountController.text = amt.toString();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Balance & Fee Breakdown
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Available On-Chain', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text(Formatters.formatSats(onchainSats), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Network Fee (1 sat/vB)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text('~$_feeSats sats', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Deductible', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(
                      Formatters.formatSats(totalRequired),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: hasSufficient ? AppColors.lightningGold : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],

          const SizedBox(height: 20),

          ReliqButton(
            label: _isProcessing
                ? 'Broadcasting Transaction...'
                : (hasSufficient ? 'Confirm & Send On-Chain' : 'Insufficient On-Chain Balance'),
            icon: Icons.send_rounded,
            variant: hasSufficient ? ReliqButtonVariant.primary : ReliqButtonVariant.secondary,
            isLoading: _isProcessing,
            onTap: (!hasSufficient || _isProcessing) ? null : _executeOnchain,
          ),
        ],
      ),
    );
  }
}

