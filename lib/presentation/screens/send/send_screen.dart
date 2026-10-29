import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/wallet_providers.dart';
import 'payment_confirmation_modal.dart';

class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final TextEditingController _invoiceController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();

  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _invoiceController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final val = barcode.rawValue;
      if (val != null && val.trim().isNotEmpty) {
        _handleInvoice(val.trim());
        break;
      }
    }
  }

  Future<void> _handleInvoice(String invoice) async {
    setState(() {
      _isProcessing = true;
    });

    final ldk = ref.read(ldkNodeServiceProvider);
    final decoded = ldk.decodeInvoice(invoice);

    if (!decoded.isValid) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded.error ?? 'Invalid Lightning invoice'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (mounted) {
      final result = await PaymentConfirmationModal.show(
        context,
        invoice: invoice,
        decoded: decoded,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (result != null && result.isSuccess) {
          ref.read(walletProvider.notifier).speakPaymentSent(decoded.amountSats);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 10),
                  Text('Payment sent successfully! Hash: ${result.paymentHash?.substring(0, 10)}...'),
                ],
              ),
              backgroundColor: AppColors.surfaceElevated,
            ),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _invoiceController.text = text;
      _handleInvoice(text);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Payment'),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? AppColors.lightningGold : Colors.white,
            ),
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Camera scanner view
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                  ),
                  // Reticle overlay
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.lightningGold,
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.qr_code_scanner, color: AppColors.lightningGold, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Point camera at Lightning QR',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Manual fallback sheet
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'OR PASTE INVOICE STRING',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _invoiceController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'lnbc... or lntb...',
                        hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste_rounded, color: AppColors.lightningGold),
                          onPressed: _pasteFromClipboard,
                        ),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          _handleInvoice(val.trim());
                        }
                      },
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sendIndigo,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (_invoiceController.text.trim().isNotEmpty) {
                          _handleInvoice(_invoiceController.text.trim());
                        } else {
                          _pasteFromClipboard();
                        }
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      label: Text(_invoiceController.text.isEmpty ? 'Paste from Clipboard' : 'Continue to Pay'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
