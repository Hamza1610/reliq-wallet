import 'package:flutter_test/flutter_test.dart';
import 'package:reliq/core/utils/formatters.dart';

void main() {
  group('Currency Formatting Tests', () {
    test('formatNgn formats correctly', () {
      expect(Formatters.formatNgn(15000.5), equals('₦ 15,000.50'));
      expect(Formatters.formatNgn(0), equals('₦ 0.00'));
    });

    test('satsToNgnDisplay converts accurately', () {
      // 10,000 sats at 1.50 NGN/sat = 15,000 NGN
      final display = Formatters.satsToNgnDisplay(10000, 1.50);
      expect(display, equals('₦ 15,000.00'));
    });

    test('satsToNgnDisplay handles null rate gracefully', () {
      final display = Formatters.satsToNgnDisplay(10000, null);
      expect(display.contains('10,000 sats'), isTrue);
    });
  });
}

