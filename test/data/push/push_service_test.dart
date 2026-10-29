import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:reliq/data/ldk/ldk_models.dart';
import 'package:reliq/data/ldk/lsp_client.dart';
import 'package:reliq/data/push/push_service.dart';

class FakeLspClient implements LspClient {
  bool shouldSucceed = true;
  String? lastClaimedHash;

  @override
  Future<bool> claimInboundPayment(String paymentHash) async {
    lastClaimedHash = paymentHash;
    return shouldSucceed;
  }

  @override
  String createInboundInvoice({
    required int amountSats,
    String? description,
    int expirySecs = 3600,
    int inboundLiquiditySats = 0,
  }) => 'lntb1000uFakeInvoice';

  @override
  Map<String, dynamic> createInboundInvoiceDetails({
    required int amountSats,
    String? description,
    int expirySecs = 3600,
    int inboundLiquiditySats = 0,
  }) => {'status': 'created', 'invoice': 'lntb1000uFakeInvoice'};

  @override
  Future<List<PendingInboundPayment>> getPendingInboundPayments() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PushService Unit Tests', () {
    late FakeLspClient fakeLsp;
    late PushService pushService;

    setUp(() {
      fakeLsp = FakeLspClient();
      pushService = PushService(lspClient: fakeLsp);
    });

    test('ignores messages with unknown action', () async {
      final handled = await pushService.handlePushMessage({
        'action': 'UNKNOWN_ACTION',
        'payment_hash': 'abcdef',
      });
      expect(handled, isFalse);
      expect(fakeLsp.lastClaimedHash, isNull);
    });

    test('ignores RELIQ_CLAIM_INBOUND message with empty payment_hash', () async {
      final handled = await pushService.handlePushMessage({
        'action': 'RELIQ_CLAIM_INBOUND',
        'payment_hash': '',
      });
      expect(handled, isFalse);
      expect(fakeLsp.lastClaimedHash, isNull);
    });

    test('handles RELIQ_CLAIM_INBOUND and routes claim to LspClient', () async {
      const targetHash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
      final handled = await pushService.handlePushMessage({
        'action': 'RELIQ_CLAIM_INBOUND',
        'payment_hash': targetHash,
        'network': 'signet',
      });

      expect(handled, isTrue);
      expect(fakeLsp.lastClaimedHash, equals(targetHash));
    });

    test('emits claim result into claimEvents stream', () async {
      const targetHash = 'test_hash_123';
      final results = <bool>[];
      final sub = pushService.claimEvents.listen(results.add);

      await pushService.handleBackgroundClaim(targetHash);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(results, equals([true]));
      await sub.cancel();
    });
  });
}
