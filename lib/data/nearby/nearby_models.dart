import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Structured, versioned, cryptographically signed payload for Nearby Confirm.
/// Conforms to Section 4 of the Reliq Nearby Confirm Technical Specification.
class NearbyPayload {
  final int version;
  final String paymentHash;
  final int amountMsat;
  final int timestamp;
  final String senderId;
  final String signature;

  const NearbyPayload({
    this.version = 1,
    required this.paymentHash,
    required this.amountMsat,
    required this.timestamp,
    required this.senderId,
    required this.signature,
  });

  int get amountSats => amountMsat ~/ 1000;

  /// Checks if the message is fresh (within 5 minutes = 300 seconds)
  bool isFresh({int maxSkewSeconds = 300}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (now - timestamp).abs() <= maxSkewSeconds;
  }

  /// Generates HMAC-SHA256 signature over payload canonical string
  static String computeSignature({
    required int version,
    required String paymentHash,
    required int amountMsat,
    required int timestamp,
    required String senderId,
    required String secret,
  }) {
    final canonical = '$version:$paymentHash:$amountMsat:$timestamp:$senderId';
    final key = utf8.encode(secret);
    final bytes = utf8.encode(canonical);
    final hmacSha256 = Hmac(sha256, key);
    return hmacSha256.convert(bytes).toString();
  }

  /// Creates a signed payload
  factory NearbyPayload.create({
    required String paymentHash,
    required int amountMsat,
    required String senderId,
    String secret = 'reliq_nearby_signing_key_v1',
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final signature = computeSignature(
      version: 1,
      paymentHash: paymentHash,
      amountMsat: amountMsat,
      timestamp: timestamp,
      senderId: senderId,
      secret: secret,
    );

    return NearbyPayload(
      version: 1,
      paymentHash: paymentHash,
      amountMsat: amountMsat,
      timestamp: timestamp,
      senderId: senderId,
      signature: signature,
    );
  }

  /// Verifies signature against payload fields
  bool verifySignature({String secret = 'reliq_nearby_signing_key_v1'}) {
    final expected = computeSignature(
      version: version,
      paymentHash: paymentHash,
      amountMsat: amountMsat,
      timestamp: timestamp,
      senderId: senderId,
      secret: secret,
    );
    return expected == signature;
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'payment_hash': paymentHash,
        'amount_msat': amountMsat,
        'timestamp': timestamp,
        'sender_id': senderId,
        'signature': signature,
      };

  factory NearbyPayload.fromJson(Map<String, dynamic> json) {
    return NearbyPayload(
      version: json['version'] as int? ?? 1,
      paymentHash: json['payment_hash'] as String? ?? '',
      amountMsat: json['amount_msat'] as int? ?? 0,
      timestamp: json['timestamp'] as int? ?? 0,
      senderId: json['sender_id'] as String? ?? '',
      signature: json['signature'] as String? ?? '',
    );
  }

  Uint8List toBytes() => Uint8List.fromList(utf8.encode(jsonEncode(toJson())));

  factory NearbyPayload.fromBytes(Uint8List bytes) {
    final jsonStr = utf8.decode(bytes);
    return NearbyPayload.fromJson(jsonDecode(jsonStr));
  }
}

