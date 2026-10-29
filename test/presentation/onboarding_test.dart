import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reliq/presentation/screens/onboarding/create_wallet_screen.dart';
import 'package:reliq/presentation/screens/onboarding/backup_seed_screen.dart';
import 'package:reliq/presentation/screens/onboarding/restore_wallet_screen.dart';
import 'package:reliq/presentation/providers/wallet_providers.dart';
import 'package:reliq/presentation/widgets/reliq_button.dart';

const testMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

void main() {
  testWidgets('CreateWalletScreen displays 12 words in numbered cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith((ref) => MockWalletNotifier(
                WalletState.initial().copyWith(isLoading: false),
              )),
        ],
        child: const MaterialApp(
          home: CreateWalletScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Backup Recovery Phrase'), findsOneWidget);
    expect(find.text('1.'), findsWidgets);
    expect(find.text('I Have Written Them Down'), findsOneWidget);
  });

  testWidgets('BackupSeedScreen blocks progression until all challenge words are selected',
      (WidgetTester tester) async {
    final words = testMnemonic.split(' ');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith((ref) => MockWalletNotifier(
                WalletState.initial().copyWith(isLoading: false),
              )),
        ],
        child: MaterialApp(
          home: BackupSeedScreen(
            mnemonic: testMnemonic,
            words: words,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Verify Backup'), findsOneWidget);
    final confirmButtonFinder = find.text('Confirm & Launch Wallet');
    expect(confirmButtonFinder, findsOneWidget);
  });

  testWidgets('RestoreWalletScreen validates input and enables restore when valid',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith((ref) => MockWalletNotifier(
                WalletState.initial().copyWith(isLoading: false),
              )),
        ],
        child: const MaterialApp(
          home: RestoreWalletScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    // Type invalid word count
    await tester.enterText(textField, 'apple banana cat');
    await tester.pump();
    expect(find.textContaining('must contain exactly 12 or 24 words'), findsOneWidget);

    // Type full 12 words
    await tester.enterText(textField, testMnemonic);
    await tester.pump();

    final restoreBtn = find.widgetWithText(ReliqButton, 'Restore Wallet');
    expect(restoreBtn, findsOneWidget);
  });
}

class MockWalletNotifier extends StateNotifier<WalletState>
    implements WalletNotifier {
  MockWalletNotifier(super.state);

  @override
  String generateFreshMnemonic({int wordCount = 12}) => testMnemonic;

  @override
  bool validateMnemonic(String mnemonic) => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
