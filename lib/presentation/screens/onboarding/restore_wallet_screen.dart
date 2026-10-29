import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/wallet_providers.dart';
import '../../widgets/reliq_button.dart';
import '../home/home_screen.dart';

class RestoreWalletScreen extends ConsumerStatefulWidget {
  const RestoreWalletScreen({super.key});

  @override
  ConsumerState<RestoreWalletScreen> createState() => _RestoreWalletScreenState();
}

class _RestoreWalletScreenState extends ConsumerState<RestoreWalletScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isValid = false;
  bool _isRestoring = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateInput() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _isValid = false;
        _errorMessage = null;
      });
      return;
    }

    final words = text.split(RegExp(r'\s+'));
    if (words.length != 12 && words.length != 24) {
      setState(() {
        _isValid = false;
        _errorMessage =
            'Phrase must contain exactly 12 or 24 words (currently: ${words.length})';
      });
      return;
    }

    final isValidBip39 = ref.read(walletProvider.notifier).validateMnemonic(text);
    setState(() {
      _isValid = isValidBip39;
      _errorMessage =
          isValidBip39 ? null : 'Words do not form a valid BIP39 checksum';
    });
  }

  Future<void> _handleRestore() async {
    if (!_isValid) return;

    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    try {
      await ref.read(walletProvider.notifier).restoreWallet(_controller.text);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to restore: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Restore Wallet'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your 12 or 24-word recovery phrase, separated by single spaces.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 4,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'word1 word2 word3 ...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(14),
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
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              ReliqButton(
                label: 'Restore Wallet',
                variant: ReliqButtonVariant.primary,
                isLoading: _isRestoring,
                onTap: (_isValid && !_isRestoring) ? _handleRestore : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
