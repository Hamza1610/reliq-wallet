import 'dart:ffi';
import 'package:flutter_test/flutter_test.dart';
import 'package:reliq/background/background_service.dart';
import 'package:reliq/data/ldk/lsp_client.dart';

class StubLspClient implements LspClient {
  final bool claimResult;
  String? claimedHash;
  @override
  Pointer<Void>? nodeHandle;

  StubLspClient({this.claimResult = true, this.nodeHandle});

  @override
  Future<bool> claimInboundPayment(String paymentHash) async {
    claimedHash = paymentHash;
    return claimResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('BackgroundService Unit Tests', () {
    test('backgroundClaimEntry returns false for empty payment hash', () async {
      final res = await backgroundClaimEntry('');
      expect(res, isFalse);
    });

    test('backgroundClaimEntry delegates to active lspClient when handle present', () async {
      final stub = StubLspClient(claimResult: true, nodeHandle: Pointer.fromAddress(0x1234));
      final res = await backgroundClaimEntry(
        'target_payment_hash_xyz',
        lspClient: stub,
      );

      expect(res, isTrue);
      expect(stub.claimedHash, equals('target_payment_hash_xyz'));
    });
  });
}
