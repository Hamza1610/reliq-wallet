import '../data/ldk/lsp_client.dart';

/// Phase 3 — Background wake & claim pipeline.
library background_service;

/// Background wake & claim pipeline entrypoint.
///
/// Invoked when the OS wakes the app for an inbound Lightning payment claim
/// (FCM silent push delivery, WorkManager, or background restart). Claims the
/// pending inbound HTLC through the LSP client and settles the payment.
@pragma('vm:entry-point')
Future<bool> backgroundClaimEntry(
  String paymentHash, {
  LspClient? lspClient,
}) async {
  final client = lspClient ?? LspClient();
  if (paymentHash.isEmpty) {
    return false;
  }
  try {
    return await client.claimInboundPayment(paymentHash);
  } catch (_) {
    // Settlement failures are surfaced through the background task status.
    return false;
  }
}
