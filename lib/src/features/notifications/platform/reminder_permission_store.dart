// Controle do pedido único de permissão (spec 08, seção 6 / CA-01/CA-02).
import 'package:shared_preferences/shared_preferences.dart';

/// Marca que a explicação já foi exibida e o pedido de autorização já
/// ocorreu uma vez — depois disso nenhum pedido automático (spec 08,
/// seção 6).
abstract interface class ReminderPermissionStore {
  Future<bool> isExplained();
  Future<void> markExplained();
}

class SharedPrefsReminderPermissionStore implements ReminderPermissionStore {
  static const _key = 'urutau_reminder_permission_explained';

  @override
  Future<bool> isExplained() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> markExplained() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
