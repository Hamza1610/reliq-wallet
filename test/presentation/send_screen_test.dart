import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reliq/presentation/screens/send/send_screen.dart';
import 'package:reliq/presentation/widgets/reliq_button.dart';
import 'package:reliq/presentation/providers/wallet_providers.dart';
import 'package:reliq/data/ldk/ldk_models.dart';
import 'package:reliq/data/ldk/ldk_node_service.dart';

class MockLdkNodeService implements LdkNodeService {
  @override
  bool get isInitialized => true;

  @override
  DecodedInvoice decodeInvoice(String invoice) {
    if (invoice.startsWith('ln')) {
      return const DecodedInvoice(
        isValid: true,
        amountSats: 1000,
        description: 'Test Payment',
        network: 'signet',
      );
    }
    return DecodedInvoice.invalid('Invalid invoice prefix');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('SendScreen renders properly and button triggers action on tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ldkNodeServiceProvider.overrideWithValue(MockLdkNodeService()),
          walletProvider.overrideWith((ref) => MockWalletNotifier(
                WalletState.initial().copyWith(hasWallet: true),
              )),
        ],
        child: const MaterialApp(
          home: SendScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Send button initially displays "Paste from Clipboard"
    expect(find.text('Paste from Clipboard'), findsOneWidget);

    // Tap button
    await tester.tap(find.widgetWithText(ReliqButton, 'Paste from Clipboard'));
    await tester.pump();

    // Enter invoice text
    final input = find.byType(TextField);
    await tester.enterText(input, 'lntb1000u1mockinvoice');
    await tester.pump();

    // Verify button text updates dynamically to "Continue to Pay"
    expect(find.text('Continue to Pay'), findsOneWidget);

    // Tap "Continue to Pay"
    await tester.tap(find.widgetWithText(ReliqButton, 'Continue to Pay'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Payment confirmation bottom sheet opens
    expect(find.text('Confirm Payment'), findsOneWidget);
    expect(find.text('1,000 sats'), findsOneWidget);
  });
}

class MockWalletNotifier extends StateNotifier<WalletState>
    implements WalletNotifier {
  MockWalletNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
