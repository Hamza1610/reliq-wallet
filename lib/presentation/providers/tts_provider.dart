import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/tts/tts_service.dart';
import 'wallet_providers.dart';

/// Singleton TTS Service provider
final ttsServiceProvider = Provider<TtsService>((ref) {
  final walletState = ref.watch(walletProvider);
  final service = TtsService(
    isVoiceEnabled: walletState.isVoiceEnabled,
    language: walletState.language,
  );

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

