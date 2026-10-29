import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/wallet_providers.dart';
import '../../widgets/reliq_button.dart';
import '../home/home_screen.dart';

class BackupSeedScreen extends ConsumerStatefulWidget {
  final String mnemonic;
  final List<String> words;

  const BackupSeedScreen({
    super.key,
    required this.mnemonic,
    required this.words,
  });

  @override
  ConsumerState<BackupSeedScreen> createState() => _BackupSeedScreenState();
}

class _BackupSeedScreenState extends ConsumerState<BackupSeedScreen> {
  late final List<int> _challengeIndices;
  final Map<int, String> _selectedAnswers = {};
  late final Map<int, List<String>> _optionsPerChallenge;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _setupChallenges();
  }

  void _setupChallenges() {
    final rand = Random();
    final indices = <int>{};
    while (indices.length < 3 && indices.length < widget.words.length) {
      indices.add(rand.nextInt(widget.words.length));
    }
    _challengeIndices = indices.toList()..sort();

    _optionsPerChallenge = {};
    for (final index in _challengeIndices) {
      final correctWord = widget.words[index];
      final options = <String>{correctWord};

      final shuffledOtherWords = List<String>.from(widget.words)..shuffle(rand);
      for (final w in shuffledOtherWords) {
        if (options.length >= 4) break;
        options.add(w);
      }

      _optionsPerChallenge[index] = options.toList()..shuffle(rand);
    }
  }

  bool get _isVerificationComplete {
    if (_selectedAnswers.length < _challengeIndices.length) return false;
    for (final index in _challengeIndices) {
      if (_selectedAnswers[index] != widget.words[index]) {
        return false;
      }
    }
    return true;
  }

  Future<void> _handleConfirm() async {
    if (!_isVerificationComplete) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(walletProvider.notifier)
          .confirmBackupAndCreateWallet(widget.mnemonic);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize node: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify Backup'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Verify words',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select the corresponding word from your written paper backup.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _challengeIndices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final targetIndex = _challengeIndices[i];
                    final options = _optionsPerChallenge[targetIndex] ?? [];
                    final selected = _selectedAnswers[targetIndex];

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected != null
                              ? (selected == widget.words[targetIndex]
                                  ? AppColors.success
                                  : AppColors.error)
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Word #${targetIndex + 1}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: options.map((word) {
                              final isSelected = selected == word;
                              return ChoiceChip(
                                label: Text(word),
                                selected: isSelected,
                                selectedColor: AppColors.textPrimary,
                                backgroundColor: AppColors.background,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.border,
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppColors.background
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      _selectedAnswers[targetIndex] = word;
                                    } else {
                                      _selectedAnswers.remove(targetIndex);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ReliqButton(
                label: 'Confirm & Launch Wallet',
                variant: ReliqButtonVariant.primary,
                isLoading: _isSubmitting,
                onTap: (_isVerificationComplete && !_isSubmitting)
                    ? _handleConfirm
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
