import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _satFormatter = NumberFormat('#,###');
  static final NumberFormat _ngnFormatter = NumberFormat('#,##0.00');

  /// Formats raw satoshi integer to human-friendly format (e.g. 12450 -> "12,450 sats")
  static String formatSats(int sats) {
    return '${_satFormatter.format(sats)} sats';
  }

  /// Formats raw satoshi integer to bare count (e.g. 12450 -> "12,450")
  static String formatSatsCount(int sats) {
    return _satFormatter.format(sats);
  }

  /// Formats Naira amount (e.g. 15000 -> "₦ 15,000.00")
  static String formatNgn(double ngn) {
    return '₦ ${_ngnFormatter.format(ngn)}';
  }

  /// Converts satoshis to formatted Naira string given an exchange rate
  static String satsToNgnDisplay(int sats, double? ratePerSat) {
    if (ratePerSat == null || ratePerSat <= 0) {
      return '${formatSats(sats)} (No rate)';
    }
    final ngn = sats * ratePerSat;
    return formatNgn(ngn);
  }

  /// Truncates a Bitcoin address or invoice (e.g. "tb1q...34f8")
  static String truncateAddress(String address, {int start = 8, int end = 8}) {
    if (address.length <= start + end) return address;
    return '${address.substring(0, start)}...${address.substring(address.length - end)}';
  }
}
