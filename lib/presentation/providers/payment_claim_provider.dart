import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/push/push_models.dart';
import '../../data/push/push_service.dart';
import 'tts_provider.dart';
import 'wallet_providers.dart';

/// Push service singleton provider
final pushServiceProvider = Provider<PushService>((ref) {
  final ldkService = ref.watch(ldkNodeServiceProvider);
  final lspClient = ref.watch(lspClientProvider);
  final service = PushService(ldkService: ldkService, lspClient: lspClient);
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Active payment claims state notifier that listens to the PushService stream
class PaymentClaimNotifier extends StateNotifier<List<ActivePaymentClaim>> {
  final PushService _pushService;
  final Ref _ref;

  PaymentClaimNotifier(this._pushService, this._ref) : super([]) {
    _pushService.claimsStream.listen(_onClaimUpdated);
  }

  void _onClaimUpdated(ActivePaymentClaim claim) {
    final updatedList = List<ActivePaymentClaim>.from(state);
    final index = updatedList.indexWhere((c) => c.paymentHash == claim.paymentHash);

    if (index != -1) {
      updatedList[index] = claim;
    } else {
      updatedList.insert(0, claim);
    }

    state = updatedList;

    // When a claim succeeds, automatically refresh wallet balance and speak audio confirmation
    if (claim.isSucceeded) {
      _ref.read(walletProvider.notifier).refreshBalance();
      _ref.read(ttsServiceProvider).speakOfflineClaimed(claim.amountSats);
    }
  }

  /// Manually trigger a simulation of an incoming held payment (for demo & offline testing)
  Future<ActivePaymentClaim> simulateIncomingPayment({
    required int amountSats,
    String? description,
  }) async {
    return _pushService.simulateIncomingHeldPayment(
      amountSats: amountSats,
      description: description,
    );
  }

  /// Clear succeeded or failed claims from the active list
  void dismissClaim(String paymentHash) {
    state = state.where((c) => c.paymentHash != paymentHash).toList();
  }
}

final paymentClaimProvider =
    StateNotifierProvider<PaymentClaimNotifier, List<ActivePaymentClaim>>((ref) {
  final pushService = ref.watch(pushServiceProvider);
  return PaymentClaimNotifier(pushService, ref);
});

/// Convenience provider returning whether any claim is currently claiming
final isActivelyClaimingPaymentProvider = Provider<bool>((ref) {
  final claims = ref.watch(paymentClaimProvider);
  return claims.any((claim) => claim.isClaiming || claim.isPending);
});

