import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../ldk/ldk_models.dart';

class PaymentHistoryService {
  static const _keyActivities = 'reliq_payment_activities';

  /// Loads all payment activities from local persistence
  Future<List<PaymentActivity>> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keyActivities);
    if (jsonList == null || jsonList.isEmpty) {
      return [];
    }

    try {
      return jsonList
          .map((item) => PaymentActivity.fromJson(jsonDecode(item)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return [];
    }
  }

  /// Appends a new payment activity to the local record
  Future<void> addActivity(PaymentActivity activity) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getActivities();
    current.insert(0, activity);

    final rawList = current.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_keyActivities, rawList);
  }

  /// Clears all stored activities
  Future<void> clearActivities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActivities);
  }

  /// Alias for clearActivities
  Future<void> clear() => clearActivities();
}
