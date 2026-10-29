import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/tts_provider.dart';
import '../../providers/wallet_providers.dart';
import '../../widgets/reliq_button.dart';
import 'payment_confirmation_modal.dart';

class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final TextEditingController _invoiceController = TextEditingController();
  MobileScannerController? _scannerController;

  bool _isProcessing = false;
  bool _isTorchOn = false;
  bool _isCameraSupported = false;

  @override
  void initState() {
    super.initState();
    _invoiceController.addListener(() {
      if (mounted) setState(() {});
    });

    // Check if running on supported mobile camera platforms (Android / iOS)
    _isCameraSupported = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (_isCameraSupported) {
      _scannerController = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _scannerController?.dispose();
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
          // Speak payment sent voice prompt
          ref.read(ttsServiceProvider).speakPaymentSent(
                decoded.amountSats,
                note: decoded.description,
              );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('Payment sent successfully'),
                ],
              ),
              backgroundColor: AppColors.surfaceElevated,
            ),
          );
          Navigator.pop(context);
        } else if (result != null && !result.isSuccess) {
          ref.read(ttsServiceProvider).speakError(result.error ?? 'Payment failed');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${result.error ?? "Unknown error"}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      _invoiceController.text = text;
      _handleInvoice(text);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Send Payment'),
        actions: [
          if (_isCameraSupported)
            IconButton(
              icon: Icon(
                _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _isTorchOn ? AppColors.lightningGold : AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () {
                _scannerController?.toggleTorch();
                setState(() {
                  _isTorchOn = !_isTorchOn;
                });
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scanner view on mobile, or clean placeholder on Linux desktop/web
            Expanded(
              flex: 5,
              child: _isCameraSupported && _scannerController != null
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        MobileScanner(
                          controller: _scannerController!,
                          onDetect: _onDetect,
                        ),
                        // Reticle overlay
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        Positioned(
                          bottom: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Align QR inside the frame',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceElevated,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 30,
                                color: AppColors.lightningGold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Scan or Paste Invoice',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Camera scanning is available on mobile devices.\nPaste or enter the Lightning invoice below.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Manual invoice entry sheet
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Invoice or Address',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _invoiceController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'lnbc... or lntb...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste_rounded,
                            color: AppColors.textSecondary, size: 18),
                        onPressed: _pasteFromClipboard,
                      ),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _handleInvoice(val.trim());
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ReliqButton(
                    label: _invoiceController.text.isEmpty
                        ? 'Paste from Clipboard'
                        : 'Continue to Pay',
                    icon: _invoiceController.text.isEmpty
                        ? Icons.paste_rounded
                        : Icons.arrow_forward_rounded,
                    variant: ReliqButtonVariant.primary,
                    isLoading: _isProcessing,
                    onTap: () {
                      if (_invoiceController.text.trim().isNotEmpty) {
                        _handleInvoice(_invoiceController.text.trim());
                      } else {
                        _pasteFromClipboard();
                      }
                    },
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
