import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reliq/presentation/screens/receive/receive_screen.dart';
import 'package:reliq/presentation/screens/send/payment_confirmation_modal.dart';
import 'package:reliq/presentation/screens/activity/activity_screen.dart';
import 'package:reliq/presentation/providers/wallet_providers.dart';
import 'package:reliq/data/ldk/ldk_models.dart';
import 'package:reliq/data/ldk/ldk_node_service.dart';

class MockLdkNodeService implements LdkNodeService {
  @override
  bool get isInitialized => true;

  @override
  String createInvoice({
    required int amountSats,
    String? description,
    int expirySecs = 3600,
  }) {
    return 'lntb${amountSats}u1preliqfakeinvoice';
  }

  @override
  String getNewOnchainAddress() {
    return 'tb1qmockreliqaddress00000000000000000000000000';
  }

  @override
  DecodedInvoice decodeInvoice(String invoice) {
    return const DecodedInvoice(
      isValid: true,
      amountSats: 2500,
      description: 'Market Vegetables',
      network: 'signet',
    );
  }

  @override
  Future<PaymentResult> sendPayment(String invoice) async {
    return const PaymentResult(status: 'succeeded', feeSats: 2);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ReceiveScreen renders Lightning tab, QR, and quick amount chips',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ldkNodeServiceProvider.overrideWithValue(MockLdkNodeService()),
          walletProvider.overrideWith((ref) => MockWalletNotifier(
                WalletState.initial().copyWith(
                  hasWallet: true,
                  balance: const WalletBalance(lightningSats: 10000, onchainSats: 5000),
                ),
              )),
        ],
        child: const MaterialApp(
          home: ReceiveScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Receive'), findsOneWidget);
    expect(find.text('Lightning'), findsOneWidget);
    expect(find.text('On-Chain'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('+1,000 sats'), findsOneWidget);
    expect(find.text('+5,000 sats'), findsOneWidget);

    // Switch to On-Chain tab
    await tester.tap(find.text('On-Chain'));
    await tester.pumpAndSettle();

    expect(find.textContaining('tb1qmockreliqaddress'), findsOneWidget);
    expect(find.text('Copy Address'), findsOneWidget);
  });

  testWidgets('PaymentConfirmationModal shows breakdown, fee, and allows payment when funded',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ldkNodeServiceProvider.overrideWithValue(MockLdkNodeService()),
          walletProvider.overrideWith((ref) => MockWalletNotifier(
                WalletState.initial().copyWith(
                  hasWallet: true,
                  balance: const WalletBalance(lightningSats: 10000, onchainSats: 0),
                ),
              )),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PaymentConfirmationModal(
              invoice: 'lntb2500u1preliqfakeinvoice',
              decoded: DecodedInvoice(
                isValid: true,
                amountSats: 2500,
                description: 'Market Vegetables',
                network: 'signet',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Confirm Payment'), findsOneWidget);
    expect(find.text('2,500 sats'), findsOneWidget);
    expect(find.text('Market Vegetables'), findsOneWidget);
    expect(find.text('2 sats'), findsOneWidget);

    final payButton = find.text('Confirm & Send');
    expect(payButton, findsOneWidget);
  });

  testWidgets('ActivityScreen displays empty state when no payments recorded',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: ActivityScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('No Payments Yet'), findsOneWidget);
  });
}

class MockWalletNotifier extends StateNotifier<WalletState>
    implements WalletNotifier {
  MockWalletNotifier(super.state);

  @override
  void refreshBalance() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
