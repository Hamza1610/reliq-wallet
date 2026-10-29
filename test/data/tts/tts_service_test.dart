import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:reliq/data/tts/tts_service.dart';

class FakeFlutterTts extends FlutterTts {
  final List<String> spokenTexts = [];
  String currentLanguage = 'en-US';
  double speechRate = 0.5;
  double volume = 1.0;
  double pitch = 1.0;
  bool isStopped = false;

  @override
  Future<dynamic> setSpeechRate(double rate) async {
    speechRate = rate;
    return 1;
  }

  @override
  Future<dynamic> setVolume(double vol) async {
    volume = vol;
    return 1;
  }

  @override
  Future<dynamic> setPitch(double p) async {
    pitch = p;
    return 1;
  }

  @override
  void setErrorHandler(dynamic handler) {}

  @override
  Future<dynamic> isLanguageAvailable(String language) async {
    return 1;
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    currentLanguage = language;
    return 1;
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spokenTexts.add(text);
    isStopped = false;
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    isStopped = true;
    return 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeFlutterTts fakeTts;
  late TtsService service;

  setUp(() {
    fakeTts = FakeFlutterTts();
    service = TtsService(flutterTts: fakeTts);
  });

  group('TtsService Unit Tests', () {
    test('init configures speech rate, volume, and pitch correctly', () async {
      await service.init();
      expect(service.isInitialized, isTrue);
      expect(fakeTts.speechRate, equals(0.85));
      expect(fakeTts.volume, equals(1.0));
      expect(fakeTts.pitch, equals(1.0));
    });

    test('setLanguage maps ha to ha-NG and en to en-US', () async {
      await service.setLanguage('ha');
      expect(fakeTts.currentLanguage, equals('ha-NG'));
      expect(service.currentLanguage, equals('ha'));

      await service.setLanguage('en');
      expect(fakeTts.currentLanguage, equals('en-US'));
      expect(service.currentLanguage, equals('en'));
    });

    test('speakBalance speaks localized string in English and Hausa', () async {
      await service.init();

      await service.speakBalance(10000, 'en');
      expect(fakeTts.spokenTexts.last, equals('Your balance is 10,000 sats'));

      await service.speakBalance(10000, 'ha');
      expect(fakeTts.spokenTexts.last, equals('Kudin ka ya kai satoshi dubu goma'));
    });

    test('speakPaymentReceived speaks payment received announcement', () async {
      await service.init();

      await service.speakPaymentReceived(2500, 'en');
      expect(fakeTts.spokenTexts.last, equals('Payment received: 2,500 sats'));

      await service.speakPaymentReceived(2500, 'ha');
      expect(
        fakeTts.spokenTexts.last,
        equals('An karbi satoshi dubu biyu da dari biyar'),
      );
    });

    test('speakPaymentSent speaks payment dispatched announcement', () async {
      await service.init();

      await service.speakPaymentSent(500, 'en');
      expect(fakeTts.spokenTexts.last, equals('Payment sent: 500 sats'));

      await service.speakPaymentSent(500, 'ha');
      expect(fakeTts.spokenTexts.last, equals('An tura satoshi dari biyar'));
    });

    test('mute prevents speak calls until unmuted', () async {
      await service.init();
      service.setMuted(true);
      expect(service.isMuted, isTrue);

      final countBefore = fakeTts.spokenTexts.length;
      await service.speak('Testing muted speech');
      expect(fakeTts.spokenTexts.length, equals(countBefore));

      service.setMuted(false);
      expect(service.isMuted, isFalse);
      await service.speak('Speech is working again');
      expect(fakeTts.spokenTexts.length, equals(countBefore + 1));
      expect(fakeTts.spokenTexts.last, equals('Speech is working again'));
    });

    test('speakVoiceToggled speaks activation or muting status', () async {
      await service.init();

      await service.speakVoiceToggled(true, 'en');
      expect(fakeTts.spokenTexts.last, equals('Voice feedback activated'));

      await service.speakVoiceToggled(false, 'ha');
      expect(fakeTts.spokenTexts.last, equals('An kashe murya'));
    });
  });
}
