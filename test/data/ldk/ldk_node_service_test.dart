import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:reliq/data/ldk/ldk_models.dart';
import 'package:reliq/data/ldk/ldk_node_service.dart';

void main() {
  group('LdkNodeService FFI Integration Tests', () {
    late LdkNodeService service;

    setUp(() {
      // Find the compiled .so library
      final candidates = [
        './native/lib/libreliq_native.so',
        '../native/lib/libreliq_native.so',
        '/home/maheer-wsl/.cargo-target/reliq/release/libreliq_native.so',
      ];
      String? libPath;
      for (final p in candidates) {
        if (File(p).existsSync()) {
          libPath = p;
          break;
        }
      }
      expect(libPath, isNotNull, reason: 'libreliq_native.so must exist');
      final lib = DynamicLibrary.open(libPath!);
      service = LdkNodeService(customLib: lib);
    });

    tearDown(() {
      service.dispose();
    });

    test('generateMnemonic generates valid 12-word phrase', () {
      final mnemonic = service.generateMnemonic(wordCount: 12);
      expect(mnemonic.isNotEmpty, isTrue);
      final words = mnemonic.split(' ');
      expect(words.length, equals(12));
      expect(service.validateMnemonic(mnemonic), isTrue);
    });

    test('generateMnemonic generates valid 24-word phrase', () {
      final mnemonic = service.generateMnemonic(wordCount: 24);
      expect(mnemonic.isNotEmpty, isTrue);
      final words = mnemonic.split(' ');
      expect(words.length, equals(24));
      expect(service.validateMnemonic(mnemonic), isTrue);
    });

    test('validateMnemonic rejects invalid seed phrases', () {
      expect(service.validateMnemonic('invalid word test error'), isFalse);
      expect(service.validateMnemonic(''), isFalse);
    });

    test('Node lifecycle: init, start, balance, and stop', () async {
      const config = NodeConfig(
        network: NetworkType.signet,
        esploraUrl: 'https://mutinynet.com/api',
        storageDir: '/tmp/reliq_flutter_test',
        mnemonic:
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      );

      service.initNode(config);
      expect(service.isInitialized, isTrue);

      await service.startNode();
      expect(service.isRunning, isTrue);

      final balance = service.getBalances();
      expect(balance.lightningSats, equals(0));
      expect(balance.onchainSats, equals(0));
      expect(balance.totalSats, equals(0));

      final address = service.getNewOnchainAddress();
      expect(address.startsWith('tb1q'), isTrue);

      final invoice = service.createInvoice(amountSats: 2500, description: 'Coffee');
      expect(invoice.startsWith('lntb'), isTrue);

      final payResult = await service.sendPayment(invoice);
      expect(payResult.isSuccess, isTrue);
      expect(payResult.paymentHash, isNotNull);

      final decoded = service.decodeInvoice(invoice);
      expect(decoded.isValid, isTrue);
      expect(decoded.amountSats, equals(2500));
      expect(decoded.network, equals('signet'));

      final invalidDecoded = service.decodeInvoice('invalid_bolt11_string');
      expect(invalidDecoded.isValid, isFalse);

      await service.stopNode();
      expect(service.isRunning, isFalse);
    });
  });
}
