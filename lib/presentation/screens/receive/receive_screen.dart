import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/wallet_providers.dart';
import '../../widgets/reliq_button.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _currentInvoice;
  String? _onchainAddress;
  bool _isGenerating = false;
  bool _requestInboundLiquidity = false;
  int _inboundLiquiditySats = 10000;

  final List<int> _quickAmounts = [500, 1000, 2500, 5000, 10000];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOnchainAddress();
      _generateLightningInvoice(amountSats: 1000);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _loadOnchainAddress() {
    try {
      final ldk = ref.read(ldkNodeServiceProvider);
      final addr = ldk.getNewOnchainAddress();
      setState(() {
        _onchainAddress = addr;
      });
    } catch (_) {}
  }

  void _generateLightningInvoice({int? amountSats}) {
    setState(() {
      _isGenerating = true;
    });

    final amt = amountSats ?? int.tryParse(_amountController.text) ?? 1000;
    final desc = _descController.text.trim();

    try {
      String invoice;
      if (_requestInboundLiquidity) {
        invoice = ref.read(walletProvider.notifier).createInboundInvoice(
              amountSats: amt,
              description: desc.isEmpty ? 'Reliq Payment' : desc,
              inboundLiquiditySats: _inboundLiquiditySats,
            );
      } else {
        final ldk = ref.read(ldkNodeServiceProvider);
        invoice = ldk.createInvoice(
          amountSats: amt,
          description: desc.isEmpty ? 'Reliq Payment' : desc,
        );
      }

      setState(() {
        _currentInvoice = invoice;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate invoice: $e')),
      );
    }
  }

  void _copyToClipboard(String data, String label) {
    Clipboard.setData(ClipboardData(text: data));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Receive'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textPrimary,
          indicatorWeight: 2,
          dividerColor: AppColors.borderSubtle,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Lightning'),
            Tab(text: 'On-Chain'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLightningTab(),
          _buildOnchainTab(),
        ],
      ),
    );
  }

  Widget _buildLightningTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // QR Code Display
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                final amt = int.tryParse(_amountController.text) ?? 1000;
                ref.read(ttsServiceProvider).speakInvoiceCreated(amt);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isGenerating || _currentInvoice == null
                    ? const SizedBox(
                        width: 200,
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        ),
                      )
                    : QrImageView(
                        data: _currentInvoice!,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Truncated invoice + Copy row
          if (_currentInvoice != null)
            InkWell(
              onTap: () => _copyToClipboard(_currentInvoice!, 'Lightning Invoice'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: AppColors.lightningGold, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        Formatters.truncateAddress(_currentInvoice!, start: 12, end: 12),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 18),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Quick Amount Selection Chips
          const Text(
            'Amount',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((amount) {
              final isSelected = _amountController.text == amount.toString();
              return ActionChip(
                label: Text('+${Formatters.formatSats(amount)}'),
                backgroundColor:
                    isSelected ? AppColors.textPrimary : AppColors.surface,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.background : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.textPrimary : AppColors.border,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onPressed: () {
                  _amountController.text = amount.toString();
                  _generateLightningInvoice(amountSats: amount);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // LSP Inbound Liquidity Provisioning (LSPS2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _requestInboundLiquidity
                    ? AppColors.lightningGold.withOpacity(0.5)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: AppColors.lightningGold, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LSP Inbound Liquidity (LSPS2)',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Provisions channel if you lack inbound capacity',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _requestInboundLiquidity,
                  activeColor: AppColors.lightningGold,
                  onChanged: (val) {
                    setState(() {
                      _requestInboundLiquidity = val;
                    });
                    _generateLightningInvoice();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Custom amount & note entry
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Custom Amount (sats)',
              labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Note (optional)',
              labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Update invoice button
          ReliqButton(
            label: 'Update Invoice',
            icon: Icons.refresh_rounded,
            variant: ReliqButtonVariant.secondary,
            isLoading: _isGenerating,
            onTap: () => _generateLightningInvoice(),
          ),
        ],
      ),
    );
  }

  Widget _buildOnchainTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // On-Chain Address QR
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _onchainAddress == null
                  ? const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      ),
                    )
                  : QrImageView(
                      data: _onchainAddress!,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Full onchain address display
          if (_onchainAddress != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deposit Address',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    _onchainAddress!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          ReliqButton(
            label: 'Copy Address',
            icon: Icons.copy_rounded,
            variant: ReliqButtonVariant.primary,
            onTap: _onchainAddress == null
                ? null
                : () => _copyToClipboard(_onchainAddress!, 'Bitcoin Address'),
          ),
          const SizedBox(height: 12),
          ReliqButton(
            label: 'Fund Wallet (Faucet +50,000 sats)',
            icon: Icons.electric_bolt_rounded,
            variant: ReliqButtonVariant.secondary,
            onTap: () async {
              await ref.read(walletProvider.notifier).fundWallet(
                amountSats: 50000,
                isOnchain: true,
                note: 'Regtest Faucet Deposit',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funded +50,000 sats to on-chain balance!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
