import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _notificationPrefKey = 'location_notifications_enabled';

final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesNotifier, bool>((ref) {
  return NotificationPreferencesNotifier();
});

class NotificationPreferencesNotifier extends StateNotifier<bool> {
  NotificationPreferencesNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_notificationPrefKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationPrefKey, value);
  }
}
