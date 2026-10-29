import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/nearby/nearby_confirm_service.dart';
import '../../data/nearby/nearby_models.dart';
import 'tts_provider.dart';
import 'wallet_providers.dart';

final nearbyConfirmServiceProvider = Provider<NearbyConfirmService>((ref) {
  final service = NearbyConfirmService();
  ref.onDispose(() => service.dispose());
  return service;
});

class NearbyConfirmNotifier extends StateNotifier<List<NearbyPayload>> {
  final NearbyConfirmService _service;
  final Ref _ref;
  StreamSubscription? _sub;

  NearbyConfirmNotifier(this._service, this._ref) : super([]) {
    _sub = _service.incomingConfirmations.listen((payload) {
      _handleIncoming(payload);
    });
  }

  void _handleIncoming(NearbyPayload payload) {
    // Add to active notifications
    state = [payload, ...state];

    // Announce via TTS voice
    final wallet = _ref.read(walletProvider);
    if (wallet.isVoiceEnabled) {
      final tts = _ref.read(ttsServiceProvider);
      final lang = wallet.language;
      final text = lang == 'ha'
          ? 'An karbi shaidar biya ta Bluetooth: satoshi ${payload.amountSats}'
          : 'Bluetooth payment confirmation received: ${payload.amountSats} sats';
      tts.speakCustom(text, language: lang);
    }
  }

  void dismissConfirmation(String paymentHash) {
    state = state.where((p) => p.paymentHash != paymentHash).toList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final nearbyConfirmProvider =
    StateNotifierProvider<NearbyConfirmNotifier, List<NearbyPayload>>((ref) {
  final service = ref.watch(nearbyConfirmServiceProvider);
  return NearbyConfirmNotifier(service, ref);
});

