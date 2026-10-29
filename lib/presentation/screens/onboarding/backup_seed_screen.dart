import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/wallet_providers.dart';
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

      // Add decoy words from the phrase
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize wallet: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Backup'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Confirm Your Words',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select the correct word corresponding to each position to prove you wrote down your seed.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _challengeIndices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, i) {
                    final targetIndex = _challengeIndices[i];
                    final options = _optionsPerChallenge[targetIndex] ?? [];
                    final selected = _selectedAnswers[targetIndex];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.lightningGold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: options.map((word) {
                              final isSelected = selected == word;
                              return ChoiceChip(
                                label: Text(word),
                                selected: isSelected,
                                selectedColor: AppColors.lightningGold,
                                backgroundColor: AppColors.surfaceElevated,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
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
              ElevatedButton(
                onPressed: (_isVerificationComplete && !_isSubmitting)
                    ? _handleConfirm
                    : null,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : const Text('Confirm & Launch Wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
