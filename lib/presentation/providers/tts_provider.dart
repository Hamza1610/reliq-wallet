import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/tts/tts_service.dart';

/// Singleton TTS Service provider
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

