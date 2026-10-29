import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reliq/data/ldk/ldk_models.dart';
import 'package:reliq/data/push/push_models.dart';
import 'package:reliq/presentation/providers/payment_claim_provider.dart';
import 'package:reliq/presentation/providers/wallet_providers.dart';
import 'package:reliq/presentation/screens/home/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HomeScreen renders claiming banner when active intermittent claim exists',
      (tester) async {
    final claim = ActivePaymentClaim(
      paymentHash: 'test_hash_123',
      amountSats: 5000,
      description: 'Grain Sack Sale',
      receivedAt: DateTime.now(),
      status: PaymentClaimStatus.claiming,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith((ref) => MockWalletNotifier()),
          paymentClaimProvider.overrideWith((ref) => MockClaimNotifier([claim])),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify claim banner elements are visible
    expect(find.text('Claiming Offline Payment...'), findsOneWidget);
    expect(find.textContaining('5,000 sats · Grain Sack Sale'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('HomeScreen shows succeeded claim state and allows dismissal',
      (tester) async {
    final succeededClaim = ActivePaymentClaim(
      paymentHash: 'test_hash_success',
      amountSats: 12000,
      description: 'Market Produce',
      receivedAt: DateTime.now(),
      status: PaymentClaimStatus.succeeded,
    );

    final mockNotifier = MockClaimNotifier([succeededClaim]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith((ref) => MockWalletNotifier()),
          paymentClaimProvider.overrideWith((ref) => mockNotifier),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Payment Claimed'), findsOneWidget);
    expect(find.textContaining('12,000 sats · Market Produce'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    // Tap dismiss icon
    final dismissIcon = find.byIcon(Icons.close_rounded);
    expect(dismissIcon, findsOneWidget);
    await tester.tap(dismissIcon);
    await tester.pumpAndSettle();

    // Verify state was cleared
    expect(find.text('Payment Claimed'), findsNothing);
  });
}

class MockWalletNotifier extends StateNotifier<WalletState> implements WalletNotifier {
  MockWalletNotifier()
      : super(
          const WalletState(
            isLoading: false,
            hasWallet: true,
            isNodeRunning: true,
            balance: WalletBalance(
              lightningSats: 50000,
              onchainSats: 0,
            ),
            network: NetworkType.signet,
            isVoiceEnabled: true,
            language: 'en',
          ),
        );

  @override
  void refreshBalance() {}

  @override
  Future<void> toggleVoice() async {}

  @override
  Future<void> setLanguage(String lang) async {}

  @override
  Future<void> confirmBackupAndCreateWallet(String mnemonic) async {}

  @override
  String generateFreshMnemonic({int wordCount = 12}) => 'abandon ' * 11 + 'about';

  @override
  Future<void> resetWallet() async {}

  @override
  Future<void> restoreWallet(String mnemonic) async {}

  @override
  bool validateMnemonic(String mnemonic) => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockClaimNotifier extends StateNotifier<List<ActivePaymentClaim>>
    implements PaymentClaimNotifier {
  MockClaimNotifier(super.initialState);

  @override
  void dismissClaim(String paymentHash) {
    state = state.where((c) => c.paymentHash != paymentHash).toList();
  }

  @override
  Future<ActivePaymentClaim> simulateIncomingPayment({
    required int amountSats,
    String? description,
  }) async {
    return state.first;
  }
}
