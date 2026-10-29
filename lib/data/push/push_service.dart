import 'package:firebase_messaging/firebase_messaging.dart';
import '../ldk/lsp_client.dart';

/// Phase 3 — FCM Push Notification Service.
///
/// Handles Firebase Cloud Messaging token lifecycle and silent push wake-up
/// events that drive the background Lightning inbound claim pipeline.
class PushService {
  final FirebaseMessaging _messaging;
  final LspClient? _lspClient;

  PushService({FirebaseMessaging? messaging, LspClient? lspClient})
      : _messaging = messaging ?? FirebaseMessaging.instance,
        _lspClient = lspClient;

  /// Initializes Firebase Messaging and resolves the device push token.
  Future<void> initialize() async {
    await _messaging.getToken();
  }

  /// Returns the resolved FCM push token for this device.
  Future<String?> getToken() async {
    return _messaging.getToken();
  }

  /// Subscribes to Reliq push topics (e.g. inbound claim notifications).
  Future<void> subscribeToInboundClaims() async {
    await _messaging.subscribeToTopic('reliq_push');
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
  /// through the LSP client.
  Future<bool> handleBackgroundClaim(String paymentHash) async {
    if (_lspClient == null) {
      return false;
    }
    return _lspClient!.claimInboundPayment(paymentHash);
  }
}
