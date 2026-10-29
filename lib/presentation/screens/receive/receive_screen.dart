import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/wallet_providers.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _currentInvoice;
  String? _onchainAddress;
  bool _isGenerating = false;

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

    final ldk = ref.read(ldkNodeServiceProvider);
    final sats = amountSats ?? int.tryParse(_amountController.text) ?? 1000;
    final desc = _descController.text.trim().isEmpty ? 'Reliq Payment' : _descController.text.trim();

    try {
      final inv = ldk.createInvoice(
        amountSats: sats,
        description: desc,
        expirySecs: 3600,
      );
      setState(() {
        _currentInvoice = inv;
        _amountController.text = sats.toString();
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate invoice: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 10),
            Text('$label copied to clipboard!'),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Bitcoin'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.lightningGold,
          labelColor: AppColors.lightningGold,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'Lightning (Instant)'),
            Tab(text: 'On-Chain (BDK)'),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // QR Code Card
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.receiveGreen.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _isGenerating || _currentInvoice == null
                  ? const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.black),
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
          const SizedBox(height: 16),

          // Truncated invoice + Copy button
          if (_currentInvoice != null)
            InkWell(
              onTap: () => _copyToClipboard(_currentInvoice!, 'Lightning Invoice'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: AppColors.lightningGold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Formatters.truncateAddress(_currentInvoice!, start: 12, end: 12),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.copy_rounded, color: AppColors.lightningGold, size: 20),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Quick Amount Selection Chips
          const Text(
            'SELECT AMOUNT (SATS)',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
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
                backgroundColor: isSelected ? AppColors.lightningGold : AppColors.surface,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.lightningGold : AppColors.border,
                ),
                onPressed: () {
                  _amountController.text = amount.toString();
                  _generateLightningInvoice(amountSats: amount);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Custom amount & note entry
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Custom Amount (sats)',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.lightningGold),
                onPressed: () => _generateLightningInvoice(),
              ),
            ),
            onSubmitted: (_) => _generateLightningInvoice(),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _descController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Payment Note / Item Name (Optional)',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              hintText: 'e.g. Tomatoes, Bag of rice',
              hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onSubmitted: (_) => _generateLightningInvoice(),
          ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed: () {
              if (_currentInvoice != null) {
                _copyToClipboard(_currentInvoice!, 'Lightning Invoice');
              }
            },
            icon: const Icon(Icons.copy_rounded, color: Colors.black),
            label: const Text('Copy Invoice'),
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.activityBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.activityBlue.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.activityBlue, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'On-chain deposits settle via Bitcoin miners and fund your BDK wallet directly.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // On-Chain QR
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.activityBlue.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _onchainAddress == null
                  ? const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(child: CircularProgressIndicator(color: Colors.black)),
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

          if (_onchainAddress != null)
            InkWell(
              onTap: () => _copyToClipboard(_onchainAddress!, 'On-Chain Address'),
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
                    const Icon(Icons.account_balance_wallet_outlined,
                        color: AppColors.activityBlue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _onchainAddress!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.copy_rounded, color: AppColors.activityBlue, size: 20),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.activityBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (_onchainAddress != null) {
                _copyToClipboard(_onchainAddress!, 'On-Chain Address');
              }
            },
            icon: const Icon(Icons.copy_rounded, color: Colors.white),
            label: const Text('Copy On-Chain Address'),
          ),
        ],
      ),
    );
  }
}
