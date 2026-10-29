import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import '../ldk/lsp_client.dart';

/// Phase 3 — FCM Push Notification Service.
///
/// Handles Firebase Cloud Messaging token lifecycle and silent push wake-up
/// events that drive the background Lightning inbound claim pipeline.
class PushService {
  final LspClient? _lspClient;
  FirebaseMessaging? _messaging;
  final StreamController<bool> _claimEvents = StreamController<bool>.broadcast();

  PushService({FirebaseMessaging? messaging, LspClient? lspClient})
      : _lspClient = lspClient,
        _messaging = messaging;

  /// Stream of background claim outcomes (true = claimed/succeeded).
  Stream<bool> get claimEvents => _claimEvents.stream;

  FirebaseMessaging get _messagingInstance {
    _messaging ??= FirebaseMessaging.instance;
    return _messaging!;
  }

  /// Initializes Firebase Messaging and resolves the device push token.
  Future<void> initialize() async {
    final messaging = _messagingInstance;
    await messaging.getToken();
  }

  /// Returns the resolved FCM push token for this device.
  Future<String?> getToken() async {
    final messaging = _messagingInstance;
    return messaging.getToken();
  }

  /// Subscribes to Reliq push topics (e.g. inbound claim notifications).
  Future<void> subscribeToInboundClaims() async {
    final messaging = _messagingInstance;
    await messaging.subscribeToTopic('reliq_push');
  }

  /// Handles an incoming push message and routes Phase 3 wake-up flows.
  ///
  /// Expected silent-push payload:
  /// {
  ///   "action": "RELIQ_CLAIM_INBOUND",
  ///   "payment_hash": "<64-char hex payment identifier>",
  ///   "network": "signet"
  /// }
  ///
  /// Returns true when the push was consumed by the inbound claim flow.
  Future<bool> handlePushMessage(Map<String, dynamic> data) async {
    final action = data['action']?.toString();
    if (action != 'RELIQ_CLAIM_INBOUND') {
      return false;
    }
    final paymentHash = data['payment_hash']?.toString() ?? '';
    if (paymentHash.isEmpty) {
      return false;
    }
    return handleBackgroundClaim(paymentHash);
  }

  /// Handles a background wake claim by claiming the pending inbound HTLC
  /// through the LSP client and emitting a claim outcome event.
  Future<bool> handleBackgroundClaim(String paymentHash) async {
    if (_lspClient == null) {
      return false;
    }
    final claimed = await _lspClient!.claimInboundPayment(paymentHash);
    _claimEvents.add(claimed);
    return claimed;
  }
}
