import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reliq/app.dart';
import 'package:reliq/data/ldk/ldk_models.dart';
import 'package:reliq/presentation/providers/wallet_providers.dart';

void main() {
  testWidgets('ReliqApp launches and displays Welcome Screen when no wallet exists',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith((ref) => MockWalletNotifier(
                WalletState(
                  isLoading: false,
                  hasWallet: false,
                  isNodeRunning: false,
                  balance: const WalletBalance(lightningSats: 0, onchainSats: 0),
                  network: NetworkType.signet,
                  isVoiceEnabled: true,
                  language: 'en',
                ),
              )),
        ],
        child: const ReliqApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Reliq'), findsOneWidget);
    expect(find.text('Self-Custodial Lightning for Everyday Reliability'), findsOneWidget);
    expect(find.text('Create New Wallet'), findsOneWidget);
    expect(find.text('Restore Existing Wallet'), findsOneWidget);
  });

  testWidgets('ReliqApp displays Home Screen with 4 action blocks when wallet exists',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith((ref) => MockWalletNotifier(
                WalletState(
                  isLoading: false,
                  hasWallet: true,
                  isNodeRunning: true,
                  balance: const WalletBalance(lightningSats: 15000, onchainSats: 5000),
                  network: NetworkType.signet,
                  isVoiceEnabled: true,
                  language: 'en',
                ),
              )),
        ],
        child: const ReliqApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Reliq'), findsOneWidget);
    expect(find.text('20,000 sats'), findsOneWidget);
    expect(find.text('RECEIVE'), findsOneWidget);
    expect(find.text('SEND'), findsOneWidget);
    expect(find.text('ACTIVITY'), findsOneWidget);
    expect(find.text('VOICE'), findsOneWidget);
    expect(find.text('LDK + BDK Engine Online'), findsOneWidget);
  });
}

class MockWalletNotifier extends StateNotifier<WalletState>
    implements WalletNotifier {
  MockWalletNotifier(super.state);

  @override
  String generateFreshMnemonic({int wordCount = 12}) =>
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

  @override
  bool validateMnemonic(String mnemonic) => true;

  @override
  Future<void> confirmBackupAndCreateWallet(String mnemonic) async {
    state = state.copyWith(hasWallet: true);
  }

  @override
  Future<void> restoreWallet(String mnemonic) async {
    state = state.copyWith(hasWallet: true);
  }

  @override
  void refreshBalance() {}

  @override
  Future<void> toggleVoice() async {
    state = state.copyWith(isVoiceEnabled: !state.isVoiceEnabled);
  }

  @override
  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
  }
}
