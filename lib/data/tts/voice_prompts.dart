import '../../core/utils/formatters.dart';

/// Converts non-negative integers into culturally natural Hausa words.
///
/// Handles northern Nigerian marketplace denominations:
/// 1: daya, 10: goma, 15: goma sha biyar, 20: ashirin, 25: ashirin da biyar,
/// 100: dari daya, 250: dari biyu da hamsin, 1,000: dubu daya,
/// 12,450: dubu goma sha biyu da dari hudu da hamsin, 1,000,000: miliyan daya.
String numberToHausaWords(int n) {
  if (n < 0) return 'debe ${numberToHausaWords(-n)}';
  if (n == 0) return 'sifili';

  const units = {
    1: 'daya',
    2: 'biyu',
    3: 'uku',
    4: 'hudu',
    5: 'biyar',
    6: 'shida',
    7: 'bakwai',
    8: 'takwas',
    9: 'tara',
  };

  const tens = {
    10: 'goma',
    20: 'ashirin',
    30: 'talatin',
    40: "arba'in",
    50: 'hamsin',
    60: 'sittin',
    70: "saba'in",
    80: 'tamanin',
    90: "casa'in",
  };

  String convertUnder100(int num) {
    if (num == 0) return '';
    if (num < 10) return units[num]!;
    if (num == 10) return 'goma';
    if (num < 20) {
      return 'goma sha ${units[num - 10]!}';
    }
    final t = (num ~/ 10) * 10;
    final r = num % 10;
    if (r == 0) return tens[t]!;
    return '${tens[t]!} da ${units[r]!}';
  }

  String convertUnder1000(int num) {
    if (num == 0) return '';
    if (num < 100) return convertUnder100(num);
    final h = num ~/ 100;
    final r = num % 100;
    final hStr = h == 1 ? 'dari daya' : 'dari ${units[h]!}';
    if (r == 0) return hStr;
    return '$hStr da ${convertUnder100(r)}';
  }

  String convertUnder1Million(int num) {
    if (num == 0) return '';
    if (num < 1000) return convertUnder1000(num);
    final th = num ~/ 1000;
    final r = num % 1000;
    final thStr = th == 1 ? 'dubu daya' : 'dubu ${convertUnder1000(th)}';
    if (r == 0) return thStr;
    return '$thStr da ${convertUnder1000(r)}';
  }

  String convertUnder1Billion(int num) {
    if (num == 0) return '';
    if (num < 1000000) return convertUnder1Million(num);
    final m = num ~/ 1000000;
    final r = num % 1000000;
    final mStr = m == 1 ? 'miliyan daya' : 'miliyan ${convertUnder1000(m)}';
    if (r == 0) return mStr;
    return '$mStr da ${convertUnder1Million(r)}';
  }

  return convertUnder1Billion(n);
}

/// Offline voice synthesis prompts in English and Hausa.
class VoicePrompts {
  static String numberToHausa(int number) => numberToHausaWords(number);

  /// Speaks current wallet balance:
  /// EN: "Your balance is 12,450 sats"
  /// HA: "Kudin ka ya kai satoshi dubu goma sha biyu da dari hudu da hamsin"
  static String balance(int sats, String language) {
    if (language.toLowerCase() == 'ha') {
      return 'Kudin ka ya kai satoshi ${numberToHausa(sats)}';
    }
    return 'Your balance is ${Formatters.formatSats(sats)}';
  }

  /// Speaks payment received announcement:
  /// EN: "Payment received: 5,000 sats"
  /// HA: "An karbi satoshi dubu biyar"
  static String paymentReceived(int sats, String language) {
    if (language.toLowerCase() == 'ha') {
      return 'An karbi satoshi ${numberToHausa(sats)}';
    }
    return 'Payment received: ${Formatters.formatSats(sats)}';
  }

  /// Speaks payment sent announcement:
  /// EN: "Payment sent: 1,500 sats"
  /// HA: "An tura satoshi dubu daya da dari biyar"
  static String paymentSent(int sats, String language) {
    if (language.toLowerCase() == 'ha') {
      return 'An tura satoshi ${numberToHausa(sats)}';
    }
    return 'Payment sent: ${Formatters.formatSats(sats)}';
  }

  /// Speaks language changed notification:
  /// EN: "Language set to English"
  /// HA: "An canza harshe zuwa Hausa"
  static String languageChanged(String language) {
    if (language.toLowerCase() == 'ha') {
      return 'An canza harshe zuwa Hausa';
    }
    return 'Language set to English';
  }

  /// Speaks voice toggle state:
  /// EN: "Voice feedback activated" / "Voice feedback muted"
  /// HA: "An kunna murya" / "An kashe murya"
  static String voiceToggled(bool enabled, String language) {
    if (language.toLowerCase() == 'ha') {
      return enabled ? 'An kunna murya' : 'An kashe murya';
    }
    return enabled ? 'Voice feedback activated' : 'Voice feedback muted';
  }

  /// Speaks invoice created notification:
  /// EN: "Invoice created for 2,500 sats"
  /// HA: "An kirkiro daftari na satoshi dubu biyu da dari biyar"
  static String invoiceCreated(int sats, String language) {
    if (language.toLowerCase() == 'ha') {
      return 'An kirkiro daftari na satoshi ${numberToHausa(sats)}';
    }
    return 'Invoice created for ${Formatters.formatSats(sats)}';
  }

  /// Speaks payment failure notice:
  /// EN: "Payment failed: <reason>"
  /// HA: "Biyan bai yi nasara ba: <reason>"
  static String paymentFailed(String reason, String language) {
    if (language.toLowerCase() == 'ha') {
      return 'Biyan bai yi nasara ba: $reason';
    }
    return 'Payment failed: $reason';
  }
}

