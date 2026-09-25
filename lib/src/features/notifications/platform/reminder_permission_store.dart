import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reminder_delivery.dart';

/// Registro local de pedidos de permissão (spec 08, §6).
class SharedPrefsReminderPermissionStore implements ReminderPermissionStore {
  static const String _key = 'reminder_permission_requested';

  @override
  Future<bool> wasRequested() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> markRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

/// Implementação em memória para testes.
class InMemoryReminderPermissionStore implements ReminderPermissionStore {
  bool requested = false;

  @override
  Future<bool> wasRequested() async => requested;

  @override
  Future<void> markRequested() async => requested = true;
}
