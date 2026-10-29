import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _satFormatter = NumberFormat('#,###');

  /// Formats raw satoshi integer to human-friendly format (e.g. 12450 -> "12,450 sats")
  static String formatSats(int sats) {
    return '${_satFormatter.format(sats)} sats';
  }

  /// Truncates a Bitcoin address or invoice (e.g. "tb1q...34f8")
  static String truncateAddress(String address, {int start = 8, int end = 8}) {
    if (address.length <= start + end) return address;
    return '${address.substring(0, start)}...${address.substring(address.length - end)}';
  }
}
