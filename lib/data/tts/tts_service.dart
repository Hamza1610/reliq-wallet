import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'voice_prompts.dart';

/// Abstract engine interface for speech synthesis.
/// Allows swapping between mock engine in tests/simulations and native ONNX/platform TTS.
abstract class TtsEngine {
  Future<void> speak(String text, {required String language});
  Future<void> stop();
  void dispose();
}

/// Real hardware & platform TTS engine wrapping flutter_tts (Piper / Sherpa-ONNX / OS TTS).
class FlutterTtsEngine implements TtsEngine {
  final FlutterTts _flutterTts;
  bool _isConfigured = false;

  FlutterTtsEngine({FlutterTts? flutterTts})
      : _flutterTts = flutterTts ?? FlutterTts();

  Future<void> _ensureConfigured() async {
    if (_isConfigured) return;
    try {
      // 0.48 on Android provides a natural, intelligible, human speaking cadence
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isConfigured = true;
    } catch (e) {
      debugPrint('[FlutterTtsEngine] Config fallback: $e');
    }
  }

  @override
  Future<void> speak(String text, {required String language}) async {
    await _ensureConfigured();
    try {
      if (language.toLowerCase() == 'ha') {
        dynamic isAvailable = await _flutterTts.isLanguageAvailable('ha-NG');
        if (isAvailable == 1 || isAvailable == true) {
          await _flutterTts.setLanguage('ha-NG');
        } else {
          await _flutterTts.setLanguage('ha');
        }
      } else {
        await _flutterTts.setLanguage('en-US');
      }
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('[FlutterTtsEngine] Speak error: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('[FlutterTtsEngine] Stop error: $e');
    }
  }

  @override
  void dispose() {}
}

/// In-memory & logging speech synthesis engine for development, web/desktop testing,
/// and offline headless environments.
class LogTtsEngine implements TtsEngine {
  final List<String> spokenHistory = [];
  String? lastSpokenText;
  String? lastLanguage;

  @override
  Future<void> speak(String text, {required String language}) async {
    lastSpokenText = text;
    lastLanguage = language;
    spokenHistory.add('[$language] $text');
    debugPrint('[TTS Speaking] ($language): $text');
  }

  @override
  Future<void> stop() async {
    debugPrint('[TTS Stopped]');
  }

  @override
  void dispose() {}
}

/// Main TTS Service coordinating voice feedback across Reliq.
/// Respects user toggle (muted / unmuted) and selected language ('en' / 'ha').
class TtsService {
  final TtsEngine _engine;
  bool isVoiceEnabled;
  String language;
  bool _isInitialized = false;

  final _speakEventsController = StreamController<String>.broadcast();
  Stream<String> get speakEvents => _speakEventsController.stream;

  TtsService({
    TtsEngine? engine,
    FlutterTts? flutterTts,
    bool? isVoiceEnabled,
    String? language,
  })  : _engine = engine ?? (flutterTts != null ? FlutterTtsEngine(flutterTts: flutterTts) : FlutterTtsEngine()),
        isVoiceEnabled = isVoiceEnabled ?? true,
        language = language ?? 'en';

  TtsEngine get engine => _engine;
  bool get isMuted => !isVoiceEnabled;
  bool get isInitialized => _isInitialized;
  String get currentLanguage => language;

  void setMuted(bool muted) {
    isVoiceEnabled = !muted;
    if (muted) {
      stop();
    }
  }

  Future<void> init() async {
    _isInitialized = true;
  }

  Future<void> setLanguage(String lang) async {
    language = lang;
  }

  void dispose() {
    _speakEventsController.close();
    _engine.dispose();
  }

  /// Speaks arbitrary text if voice feedback is enabled.
  Future<void> speak(String text) async {
    if (!isVoiceEnabled || text.trim().isEmpty) return;

    _speakEventsController.add(text);
    await _engine.speak(text, language: language);
  }

  /// Speaks current wallet balance in the user's configured language.
  Future<void> speakBalance(int amountSats, [String? lang]) async {
    final effectiveLang = lang ?? language;
    final prompt = VoicePrompts.balancePrompt(
      amountSats: amountSats,
      language: effectiveLang,
    );
    if (!isVoiceEnabled) return;
    _speakEventsController.add(prompt);
    await _engine.speak(prompt, language: effectiveLang);
  }

  /// Speaks an arbitrary announcement (e.g. for Bluetooth Nearby confirmation).
  Future<void> speakCustom(String text, {String? language}) async {
    final effectiveLang = language ?? this.language;
    if (!isVoiceEnabled) return;
    _speakEventsController.add(text);
    await _engine.speak(text, language: effectiveLang);
  }

  /// Speaks confirmation when an inbound payment is received.
  Future<void> speakPaymentReceived(
    int amountSats, {
    String? note,
    String? language,
  }) async {
    final effectiveLang = language ?? this.language;
    final prompt = VoicePrompts.paymentReceivedPrompt(
      amountSats: amountSats,
      language: effectiveLang,
      note: note,
    );
    if (!isVoiceEnabled) return;
    _speakEventsController.add(prompt);
    await _engine.speak(prompt, language: effectiveLang);
  }

  /// Speaks confirmation when an outbound payment is sent.
  Future<void> speakPaymentSent(
    int amountSats, {
    String? note,
    String? language,
  }) async {
    final effectiveLang = language ?? this.language;
    final prompt = VoicePrompts.paymentSentPrompt(
      amountSats: amountSats,
      language: effectiveLang,
      note: note,
    );
    if (!isVoiceEnabled) return;
    _speakEventsController.add(prompt);
    await _engine.speak(prompt, language: effectiveLang);
  }

  /// Speaks confirmation when an offline held payment is claimed.
  Future<void> speakOfflineClaimed(int amountSats, [String? lang]) async {
    final effectiveLang = lang ?? language;
    final prompt = VoicePrompts.offlineClaimedPrompt(
      amountSats: amountSats,
      language: effectiveLang,
    );
    if (!isVoiceEnabled) return;
    _speakEventsController.add(prompt);
    await _engine.speak(prompt, language: effectiveLang);
  }

  /// Speaks error notifications.
  Future<void> speakError(String reason, [String? lang]) async {
    final effectiveLang = lang ?? language;
    final prompt = VoicePrompts.errorPrompt(
      reason: reason,
      language: effectiveLang,
    );
    if (!isVoiceEnabled) return;
    _speakEventsController.add(prompt);
    await _engine.speak(prompt, language: effectiveLang);
  }

  /// Speaks language changed notification.
  Future<void> speakLanguageChanged(String newLanguage) async {
    final prompt = VoicePrompts.languageChanged(newLanguage);
    language = newLanguage;
    if (!isVoiceEnabled) return;
    _speakEventsController.add(prompt);
    await _engine.speak(prompt, language: newLanguage);
  }

  /// Speaks voice toggle state (activated or muted).
  Future<void> speakVoiceToggled(bool enabled, [String? lang]) async {
    final effectiveLang = lang ?? language;
    final prompt = VoicePrompts.voiceToggled(enabled, effectiveLang);
    _speakEventsController.add(prompt);
    await _engine.speak(prompt, language: effectiveLang);
  }

  /// Speaks invoice created notification.
  Future<void> speakInvoiceCreated(int sats, [String? lang]) async {
    final effectiveLang = lang ?? language;
    final prompt = VoicePrompts.invoiceCreated(sats, effectiveLang);
    if (!isVoiceEnabled) return;
    _speakEventsController.add(prompt);
    await _engine.speak(prompt, language: effectiveLang);
  }

  /// Stops current speech playback.
  Future<void> stop() async {
    await _engine.stop();
  }
}
