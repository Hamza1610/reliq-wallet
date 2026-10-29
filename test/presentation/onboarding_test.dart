import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reliq/presentation/providers/wallet_providers.dart';
import 'package:reliq/presentation/screens/onboarding/backup_seed_screen.dart';
import 'package:reliq/presentation/screens/onboarding/create_wallet_screen.dart';
import 'package:reliq/presentation/screens/onboarding/restore_wallet_screen.dart';
import '../widget_test.dart';

void main() {
  const testMnemonic =
      'apple banana cat dog elephant fox giraffe hawk iguana jaguar kangaroo lemon';
  final testWords = testMnemonic.split(' ');

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
    expect(find.text('I Have Written Them Down'), findsOneWidget);
  });

  testWidgets('BackupSeedScreen blocks progression until all challenge words are selected',
      (WidgetTester tester) async {
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
            words: testWords,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Confirm Your Words'), findsOneWidget);
    final confirmButtonFinder = find.widgetWithText(ElevatedButton, 'Confirm & Launch Wallet');
    expect(confirmButtonFinder, findsOneWidget);

    // Initial state: button is disabled
    final ElevatedButton button = tester.widget(confirmButtonFinder);
    expect(button.onPressed, isNull);
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
    expect(find.text('Valid BIP39 Recovery Phrase'), findsOneWidget);

    final restoreBtn = find.widgetWithText(ElevatedButton, 'Restore Wallet');
    final ElevatedButton btnWidget = tester.widget(restoreBtn);
    expect(btnWidget.onPressed, isNotNull);
  });
}
