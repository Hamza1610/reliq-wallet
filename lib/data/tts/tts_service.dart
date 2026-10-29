import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'voice_prompts.dart';

/// Offline Text-to-Speech (TTS) Service for Reliq.
///
/// Wraps flutter_tts to provide speech feedback in English and Hausa.
/// Automatically handles platform fallbacks, volume, pitch, and voice-toggle state.
class TtsService {
  final FlutterTts _flutterTts;
  bool _isMuted = false;
  bool _isInitialized = false;
  String _currentLanguage = 'en';

  TtsService({FlutterTts? flutterTts}) : _flutterTts = flutterTts ?? FlutterTts();

  bool get isMuted => _isMuted;
  bool get isInitialized => _isInitialized;
  String get currentLanguage => _currentLanguage;

  /// Sets mute state. When muted, all speak requests return immediately.
  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      stop();
    }
  }

  /// Initializes the TTS engine with accessible defaults (0.85 rate for clarity).
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setSpeechRate(0.85);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setErrorHandler((msg) {
        debugPrint('[TtsService] Error handler: $msg');
      });

      await setLanguage(_currentLanguage);
      _isInitialized = true;
    } catch (e) {
      debugPrint('[TtsService] Init fallback: $e');
      _isInitialized = true;
    }
  }

  /// Configures language locale ('en' -> 'en-US', 'ha' -> 'ha-NG' or 'ha').
  Future<void> setLanguage(String lang) async {
    _currentLanguage = lang;
    try {
      if (lang.toLowerCase() == 'ha') {
        dynamic isAvailable = await _flutterTts.isLanguageAvailable('ha-NG');
        if (isAvailable == 1 || isAvailable == true) {
          await _flutterTts.setLanguage('ha-NG');
        } else {
          await _flutterTts.setLanguage('ha');
        }
      } else {
        await _flutterTts.setLanguage('en-US');
      }
    } catch (e) {
      debugPrint('[TtsService] setLanguage fallback: $e');
    }
  }

  /// Speaks raw text string if not muted.
  Future<void> speak(String text) async {
    if (_isMuted) return;
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('[TtsService] speak fallback: $e');
    }
  }

  /// Immediately halts speech synthesis.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('[TtsService] stop fallback: $e');
    }
  }

  /// Speaks the wallet balance in the designated language.
  Future<void> speakBalance(int sats, [String? language]) async {
    final lang = language ?? _currentLanguage;
    final text = VoicePrompts.balance(sats, lang);
    await setLanguage(lang);
    await speak(text);
  }

  /// Speaks payment received announcement.
  Future<void> speakPaymentReceived(int sats, [String? language]) async {
    final lang = language ?? _currentLanguage;
    final text = VoicePrompts.paymentReceived(sats, lang);
    await setLanguage(lang);
    await speak(text);
  }

  /// Speaks payment sent announcement.
  Future<void> speakPaymentSent(int sats, [String? language]) async {
    final lang = language ?? _currentLanguage;
    final text = VoicePrompts.paymentSent(sats, lang);
    await setLanguage(lang);
    await speak(text);
  }

  /// Speaks language changed notification.
  Future<void> speakLanguageChanged(String newLanguage) async {
    final text = VoicePrompts.languageChanged(newLanguage);
    await setLanguage(newLanguage);
    await speak(text);
  }

  /// Speaks voice toggle state (activated or muted).
  Future<void> speakVoiceToggled(bool enabled, [String? language]) async {
    final lang = language ?? _currentLanguage;
    final text = VoicePrompts.voiceToggled(enabled, lang);
    if (!enabled) {
      final wasMuted = _isMuted;
      _isMuted = false;
      await setLanguage(lang);
      await speak(text);
      _isMuted = wasMuted;
    } else {
      _isMuted = false;
      await setLanguage(lang);
      await speak(text);
    }
  }

  /// Speaks invoice created notification.
  Future<void> speakInvoiceCreated(int sats, [String? language]) async {
    final lang = language ?? _currentLanguage;
    final text = VoicePrompts.invoiceCreated(sats, lang);
    await setLanguage(lang);
    await speak(text);
  }

  /// Speaks payment failure notice.
  Future<void> speakPaymentFailed(String reason, [String? language]) async {
    final lang = language ?? _currentLanguage;
    final text = VoicePrompts.paymentFailed(reason, lang);
    await setLanguage(lang);
    await speak(text);
  }
}

