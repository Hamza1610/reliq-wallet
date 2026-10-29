import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/ldk/ldk_models.dart';
import '../../../data/storage/payment_history_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final PaymentHistoryService _historyService = PaymentHistoryService();
  List<PaymentActivity> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });
    final items = await _historyService.getActivities();
    if (mounted) {
      setState(() {
        _activities = items;
        _isLoading = false;
      });
    }
  }

  void _showDetailModal(PaymentActivity item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Text(
              item.isReceived ? 'Payment Received' : 'Payment Sent',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              Formatters.formatSats(item.amountSats),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                letterSpacing: -1.0,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: item.isReceived ? AppColors.success : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              'Date & Time',
              DateFormat('MMM d, yyyy · h:mm a').format(item.timestamp),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              'Description',
              item.description.isEmpty ? 'Lightning transaction' : item.description,
            ),
            const SizedBox(height: 10),
            _buildDetailRow('Status', item.status.name.toUpperCase()),
            if (item.paymentHash != null) ...[
              const SizedBox(height: 10),
              _buildDetailRow(
                'Payment Hash',
                Formatters.truncateAddress(item.paymentHash!, start: 8, end: 8),
                copyValue: item.paymentHash,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {String? copyValue}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (copyValue != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: copyValue));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
            )
          : _activities.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppColors.textPrimary,
                  backgroundColor: AppColors.surfaceElevated,
                  onRefresh: _loadActivities,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: _activities.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _activities[index];
                      final isReceive = item.isReceived;

                      return InkWell(
                        onTap: () => _showDetailModal(item),
                        child: Padding(
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
                                  isReceive
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  color: isReceive ? AppColors.success : AppColors.textPrimary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.description.isEmpty
                                          ? (isReceive ? 'Received' : 'Sent')
                                          : item.description,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMM d · h:mm a').format(item.timestamp),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isReceive ? '+' : '-'} ${Formatters.formatSats(item.amountSats)}',
                                style: TextStyle(
                                  color: isReceive ? AppColors.success : AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 40),
            SizedBox(height: 16),
            Text(
              'No Payments Yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Incoming and outgoing transactions will appear here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
