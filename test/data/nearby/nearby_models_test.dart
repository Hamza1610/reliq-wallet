import 'package:flutter_test/flutter_test.dart';
import 'package:reliq/data/nearby/nearby_models.dart';

void main() {
  group('NearbyPayload Tests', () {
    test('creates and verifies valid payload signature', () {
      final payload = NearbyPayload.create(
        paymentHash: 'abcdef0123456789abcdef0123456789',
        amountMsat: 5000 * 1000,
        senderId: 'merchant_stall_01',
      );

      expect(payload.version, equals(1));
      expect(payload.amountSats, equals(5000));
      expect(payload.isFresh(), isTrue);
      expect(payload.verifySignature(), isTrue);
    });

    test('rejects tampered payload', () {
      final payload = NearbyPayload.create(
        paymentHash: 'hash1',
        amountMsat: 5000 * 1000,
        senderId: 'merchant_stall_01',
      );

      final tampered = NearbyPayload(
        version: payload.version,
        paymentHash: payload.paymentHash,
        amountMsat: 999999 * 1000, // Tampered amount
        timestamp: payload.timestamp,
        senderId: payload.senderId,
        signature: payload.signature,
      );

      expect(tampered.verifySignature(), isFalse);
    });

    test('serializes and deserializes bytes properly', () {
      final original = NearbyPayload.create(
        paymentHash: '1234567890abcdef',
        amountMsat: 2500 * 1000,
        senderId: 'buyer_device_02',
      );

      final bytes = original.toBytes();
      final reconstructed = NearbyPayload.fromBytes(bytes);

      expect(reconstructed.paymentHash, equals(original.paymentHash));
      expect(reconstructed.amountSats, equals(2500));
      expect(reconstructed.signature, equals(original.signature));
      expect(reconstructed.verifySignature(), isTrue);
    });

    test('rejects stale payload (> 300s old)', () {
      final staleTimestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 500;
      final stale = NearbyPayload(
        version: 1,
        paymentHash: 'old_hash',
        amountMsat: 1000,
        timestamp: staleTimestamp,
        senderId: 'sender',
        signature: 'dummy',
      );

      expect(stale.isFresh(), isFalse);
    });
  });
}

