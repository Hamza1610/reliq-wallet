import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const _keyCurrencyMode = 'reliq_display_currency';
  static const _keyCustomRate = 'reliq_custom_ngn_rate';

  /// Default rate if offline before first network fetch (null if none configured)
  double? _cachedRate;

  /// Loads saved custom rate
  Future<double?> getCustomRate() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getDouble(_keyCustomRate);
    if (val != null && val > 0) {
      _cachedRate = val;
      return val;
    }
    return _cachedRate;
  }

  /// Saves custom rate
  Future<void> setCustomRate(double rate) async {
    _cachedRate = rate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyCustomRate, rate);
  }

  /// Loads currency mode ('sats' or 'ngn')
  Future<String> getCurrencyMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrencyMode) ?? 'ngn'; // Default to Everyday Naira Mode
  }

  /// Saves currency mode
  Future<void> setCurrencyMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrencyMode, mode);
  }

  /// Fetches live Bitcoin price in NGN from public endpoints without requiring an API key
  Future<double?> fetchLiveNgnRate() async {
    // Check if user set a custom rate first
    final custom = await getCustomRate();
    if (custom != null && custom > 0) return custom;

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      // Attempt 1: CoinGecko simple price (BTC to NGN)
      final request = await client.getUrl(
        Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=ngn'),
      );
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final btcPriceNgn = (json['bitcoin']?['ngn'] as num?)?.toDouble();
        if (btcPriceNgn != null && btcPriceNgn > 0) {
          final ratePerSat = btcPriceNgn / 100000000.0;
          _cachedRate = ratePerSat;
          return ratePerSat;
        }
      }
    } catch (e) {
      debugPrint('[CurrencyService] Live price fetch: $e');
    }

    return _cachedRate;
  }
}

