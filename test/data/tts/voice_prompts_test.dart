import 'package:flutter_test/flutter_test.dart';
import 'package:reliq/data/tts/voice_prompts.dart';

void main() {
  group('Hausa Number-to-Words (Northern Nigerian Marketplace)', () {
    test('handles zero and single digits correctly', () {
      expect(numberToHausaWords(0), equals('sifili'));
      expect(numberToHausaWords(1), equals('daya'));
      expect(numberToHausaWords(2), equals('biyu'));
      expect(numberToHausaWords(3), equals('uku'));
      expect(numberToHausaWords(4), equals('hudu'));
      expect(numberToHausaWords(5), equals('biyar'));
      expect(numberToHausaWords(6), equals('shida'));
      expect(numberToHausaWords(7), equals('bakwai'));
      expect(numberToHausaWords(8), equals('takwas'));
      expect(numberToHausaWords(9), equals('tara'));
    });

    test('handles teens (goma sha...) correctly', () {
      expect(numberToHausaWords(10), equals('goma'));
      expect(numberToHausaWords(11), equals('goma sha daya'));
      expect(numberToHausaWords(12), equals('goma sha biyu'));
      expect(numberToHausaWords(15), equals('goma sha biyar'));
      expect(numberToHausaWords(19), equals('goma sha tara'));
    });

    test('handles tens and compound tens correctly', () {
      expect(numberToHausaWords(20), equals('ashirin'));
      expect(numberToHausaWords(21), equals('ashirin da daya'));
      expect(numberToHausaWords(25), equals('ashirin da biyar'));
      expect(numberToHausaWords(30), equals('talatin'));
      expect(numberToHausaWords(40), equals("arba'in"));
      expect(numberToHausaWords(50), equals('hamsin'));
      expect(numberToHausaWords(75), equals("saba'in da biyar"));
      expect(numberToHausaWords(99), equals("casa'in da tara"));
    });

    test('handles hundreds correctly', () {
      expect(numberToHausaWords(100), equals('dari daya'));
      expect(numberToHausaWords(105), equals('dari daya da biyar'));
      expect(numberToHausaWords(200), equals('dari biyu'));
      expect(numberToHausaWords(250), equals('dari biyu da hamsin'));
      expect(numberToHausaWords(500), equals('dari biyar'));
      expect(numberToHausaWords(999), equals("dari tara da casa'in da tara"));
    });

    test('handles thousands and common satoshi denominations', () {
      expect(numberToHausaWords(1000), equals('dubu daya'));
      expect(numberToHausaWords(1500), equals('dubu daya da dari biyar'));
      expect(numberToHausaWords(2500), equals('dubu biyu da dari biyar'));
      expect(numberToHausaWords(5000), equals('dubu biyar'));
      expect(numberToHausaWords(10000), equals('dubu goma'));
      expect(
        numberToHausaWords(12450),
        equals('dubu goma sha biyu da dari hudu da hamsin'),
      );
      expect(numberToHausaWords(25000), equals('dubu ashirin da biyar'));
      expect(numberToHausaWords(50000), equals('dubu hamsin'));
      expect(numberToHausaWords(100000), equals('dubu dari daya'));
      expect(numberToHausaWords(1000000), equals('miliyan daya'));
    });
  });

  group('VoicePrompts Localization Tests', () {
    test('balance prompts in English and Hausa', () {
      expect(
        VoicePrompts.balance(12450, 'en'),
        equals('Your balance is 12,450 sats'),
      );
      expect(
        VoicePrompts.balance(12450, 'ha'),
        equals(
          'Kudin ka ya kai satoshi dubu goma sha biyu da dari hudu da hamsin',
        ),
      );
    });

    test('paymentReceived prompts in English and Hausa', () {
      expect(
        VoicePrompts.paymentReceived(5000, 'en'),
        equals('Payment received: 5,000 sats'),
      );
      expect(
        VoicePrompts.paymentReceived(5000, 'ha'),
        equals('An karbi satoshi dubu biyar'),
      );
    });

    test('paymentSent prompts in English and Hausa', () {
      expect(
        VoicePrompts.paymentSent(1500, 'en'),
        equals('Payment sent: 1,500 sats'),
      );
      expect(
        VoicePrompts.paymentSent(1500, 'ha'),
        equals('An tura satoshi dubu daya da dari biyar'),
      );
    });

    test('languageChanged prompts in English and Hausa', () {
      expect(VoicePrompts.languageChanged('en'), equals('Language set to English'));
      expect(VoicePrompts.languageChanged('ha'), equals('An canza harshe zuwa Hausa'));
    });

    test('voiceToggled prompts in English and Hausa', () {
      expect(VoicePrompts.voiceToggled(true, 'en'), equals('Voice feedback activated'));
      expect(VoicePrompts.voiceToggled(false, 'en'), equals('Voice feedback muted'));
      expect(VoicePrompts.voiceToggled(true, 'ha'), equals('An kunna murya'));
      expect(VoicePrompts.voiceToggled(false, 'ha'), equals('An kashe murya'));
    });

    test('invoiceCreated prompts in English and Hausa', () {
      expect(
        VoicePrompts.invoiceCreated(2500, 'en'),
        equals('Invoice created for 2,500 sats'),
      );
      expect(
        VoicePrompts.invoiceCreated(2500, 'ha'),
        equals('An kirkiro daftari na satoshi dubu biyu da dari biyar'),
      );
    });
  });
}

