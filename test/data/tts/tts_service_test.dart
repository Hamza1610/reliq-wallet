import 'package:flutter_test/flutter_test.dart';
import 'package:reliq/data/tts/tts_service.dart';

void main() {
  late LogTtsEngine logEngine;
  late TtsService service;

  setUp(() {
    logEngine = LogTtsEngine();
    service = TtsService(engine: logEngine);
  });

  group('TtsService Unit Tests', () {
    test('init sets isInitialized to true', () async {
      await service.init();
      expect(service.isInitialized, isTrue);
    });

    test('setLanguage updates language correctly', () async {
      await service.setLanguage('ha');
      expect(service.language, equals('ha'));

      await service.setLanguage('en');
      expect(service.language, equals('en'));
    });

    test('speakBalance speaks localized string in English and Hausa', () async {
      await service.speakBalance(10000, 'en');
      expect(logEngine.spokenHistory.last, contains('10,000'));

      await service.speakBalance(10000, 'ha');
      expect(logEngine.spokenHistory.last, contains('dubu goma'));
    });

    test('speakPaymentReceived speaks payment received announcement', () async {
      await service.speakPaymentReceived(2500, language: 'en');
      expect(logEngine.spokenHistory.last, contains('2,500'));

      await service.speakPaymentReceived(2500, language: 'ha');
      expect(logEngine.spokenHistory.last, contains('dubu biyu da dari biyar'));
    });

    test('speakPaymentSent speaks payment dispatched announcement', () async {
      await service.speakPaymentSent(500, language: 'en');
      expect(logEngine.spokenHistory.last, contains('500'));

      await service.speakPaymentSent(500, language: 'ha');
      expect(logEngine.spokenHistory.last, contains('dari biyar'));
    });

    test('mute prevents speak calls until unmuted', () async {
      service.setMuted(true);
      expect(service.isVoiceEnabled, isFalse);
      expect(service.isMuted, isTrue);

      final countBefore = logEngine.spokenHistory.length;
      await service.speak('Testing muted speech');
      expect(logEngine.spokenHistory.length, equals(countBefore));

      service.setMuted(false);
      expect(service.isVoiceEnabled, isTrue);
      expect(service.isMuted, isFalse);
      await service.speak('Speech is working again');
      expect(logEngine.spokenHistory.length, equals(countBefore + 1));
    });

    test('speakVoiceToggled speaks activation or muting status', () async {
      await service.speakVoiceToggled(true, 'en');
      expect(logEngine.spokenHistory.last, contains('activated'));

      await service.speakVoiceToggled(false, 'ha');
      expect(logEngine.spokenHistory.last, contains('kashe'));
    });
  });
}
