library background_service;

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/constants/network_constants.dart';
import '../data/ldk/ldk_models.dart';
import '../data/ldk/ldk_node_service.dart';
import '../data/ldk/lsp_client.dart';
import '../data/storage/secure_storage_service.dart';

/// Phase 3 — Background wake & claim pipeline.

/// Background wake & claim pipeline entrypoint.
///
/// Invoked when the OS wakes the app for an inbound Lightning payment claim
/// (FCM silent push delivery, WorkManager, or background restart). Claims the
/// pending inbound HTLC through the LSP client and settles the payment.
@pragma('vm:entry-point')
Future<bool> backgroundClaimEntry(
  String paymentHash, {
  LspClient? lspClient,
  LdkNodeService? ldkService,
  SecureStorageService? storageService,
}) async {
  if (paymentHash.isEmpty) {
    return false;
  }

  // 1. If an active LSP client with a valid node handle is supplied, claim directly
  if (lspClient != null && lspClient.nodeHandle != null) {
    try {
      return await lspClient.claimInboundPayment(paymentHash);
    } catch (_) {
      return false;
    }
  }

  // 2. Otherwise initialize node from secure storage for headless background execution
  LdkNodeService? localLdk;
  try {
    final storage = storageService ?? SecureStorageService();
    final hasWallet = await storage.hasWallet();
    if (!hasWallet) return false;

    final mnemonic = await storage.getMnemonic();
    if (mnemonic == null || mnemonic.isEmpty) return false;

    final network = await storage.getNetwork();
    localLdk = ldkService ?? LdkNodeService();

    final docsDir = await getApplicationDocumentsDirectory();
    final storageDir = '${docsDir.path}/ldk_${network.name}';
    final dir = Directory(storageDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final config = NodeConfig(
      network: network,
      esploraUrl: NetworkConstants.getEsploraUrl(network),
      rgsUrl: NetworkConstants.getRgsUrl(network),
      storageDir: storageDir,
      mnemonic: mnemonic,
    );

    localLdk.initNode(config);
    await localLdk.startNode();

    final client = lspClient ?? localLdk.createLspClient();
    if (client.nodeHandle == null) {
      client.nodeHandle = localLdk.rawNodeHandle;
    }

    final claimed = await client.claimInboundPayment(paymentHash);
    return claimed;
  } catch (_) {
    return false;
  } finally {
    try {
      if (localLdk != null && ldkService == null) {
        localLdk.stopNode();
        localLdk.dispose();
      }
    } catch (_) {}
  }
}
