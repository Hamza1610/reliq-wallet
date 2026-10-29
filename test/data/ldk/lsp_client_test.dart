import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:reliq/data/ldk/ldk_models.dart';
import 'package:reliq/data/ldk/ldk_node_service.dart';
import 'package:reliq/data/ldk/lsp_client.dart';

void main() {
  group('LspClient Integration Tests', () {
    late LdkNodeService nodeService;
    late LspClient lspClient;

    setUp(() async {
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
      nodeService = LdkNodeService(customLib: lib);

      final tempDir = Directory.systemTemp.createTempSync('reliq_lsp_test_');
      final mnemonic = nodeService.generateMnemonic();
      final config = NodeConfig(
        network: NetworkType.signet,
        esploraUrl: 'https://mutinynet.com/api',
        storageDir: tempDir.path,
        mnemonic: mnemonic,
      );

      nodeService.initNode(config);
      await nodeService.startNode();

      lspClient = nodeService.createLspClient();
    });

    tearDown(() async {
      try {
        await nodeService.stopNode();
        nodeService.dispose();
      } catch (_) {}
    });

    test('createInboundInvoice returns clean BOLT11 invoice string (not raw JSON)', () {
      final invoice = lspClient.createInboundInvoice(
        amountSats: 2500,
        description: 'LSP Test Payment',
        inboundLiquiditySats: 25000,
      );

      expect(invoice.isNotEmpty, isTrue);
      // Must start with lightning prefix, NOT raw JSON brace '{'
      expect(invoice.startsWith('lntb'), isTrue);
      expect(invoice.startsWith('{'), isFalse);
    });

    test('createInboundInvoiceDetails returns parsed metadata map', () {
      final details = lspClient.createInboundInvoiceDetails(
        amountSats: 5000,
        description: 'Market Groceries',
        inboundLiquiditySats: 50000,
      );

      expect(details['status'], equals('created'));
      expect(details['invoice'], isNotNull);
      expect(details['invoice'].toString().startsWith('lntb'), isTrue);
      expect(details['amount_sats'], equals(5000));
      expect(details['inbound_liquidity_sats'], equals(50000));
    });

    test('claimInboundPayment claims pending HTLC successfully', () async {
      const dummyHash = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
      final claimed = await lspClient.claimInboundPayment(dummyHash);
      expect(claimed, isTrue);
    });

    test('getPendingInboundPayments returns list of pending items', () async {
      final pending = await lspClient.getPendingInboundPayments();
      expect(pending, isA<List<PendingInboundPayment>>());
    });
  });
}
