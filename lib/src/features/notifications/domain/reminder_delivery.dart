/// Contrato de notificações locais por plataforma (spec 08; ADR-0002).
///
/// Entrega **best effort** conforme a matriz de capacidade; a configuração
/// do lembrete (instante UTC) é do domínio e nunca é removida por falta de
/// permissão/capacidade. IDs do sistema são infraestrutura e ficam fora do
/// backup (spec 08, §3).
library;

/// Capacidade da plataforma (spec 08, §4).
enum ReminderCapability {
  /// A plataforma consegue exibir avisos (com as ressalvas da matriz).
  supported,

  /// Sem suporte nesta plataforma/compilação.
  unsupported,
}

/// Estado da permissão de notificação.
enum ReminderPermission {
  /// Concedida.
  granted,

  /// Negada pelo usuário; não repetir pedido automaticamente (§6).
  denied,

  /// Ainda não perguntada.
  notDetermined,
}

/// Estado de entrega exibido ao usuário (spec 08, §3).
enum DeliveryState {
  /// O sistema aceitou o agendamento (sem garantia pontual).
  scheduled,

  /// Permissão necessária; a configuração é preservada.
  permissionNeeded,

  /// Indisponível nesta plataforma.
  platformUnsupported,

  /// O instante já passou; sem agendamento e sem catch-up (§8).
  overdue,

  /// Aguardando confirmação de capacidade/permissão.
  pendingVerification,
}

/// Adaptador de notificação por plataforma (spec 08, §5).
///
/// Um único agendamento ativo por tarefa; o ID é estável e derivado do
/// UUID da tarefa. O aviso mostra o título atual, sem ações rápidas.
/// Tocar no aviso navega para o detalhe da tarefa (CA-06).
abstract class ReminderAdapter {
  /// Registra o destino de navegação ao tocar em um aviso.
  void setOnOpenTask(void Function(String taskId) handler);
  Future<ReminderCapability> queryCapability();

  Future<ReminderPermission> queryPermission();

  /// Só em resposta a ação explícita do usuário (spec 08, §6).
  Future<ReminderPermission> requestPermission();

  /// Agenda/substitui o único aviso futuro da tarefa; idempotente.
  Future<void> schedule({
    required String taskId,
    required String title,
    required DateTime fireAt,
  });

  /// Cancela o aviso da tarefa; idempotente.
  Future<void> cancel({required String taskId});
}

/// Registro local de que o pedido de permissão já ocorreu (spec 08, §6).
///
/// Após negativa, o pedido nunca é repetido automaticamente; nova tentativa
/// só por ação explícita do usuário.
abstract class ReminderPermissionStore {
  Future<bool> wasRequested();
  Future<void> markRequested();
}

/// ID de agendamento estável por tarefa (spec 08, §5).
String reminderScheduleId(String taskId) => 'urutau-reminder-$taskId';
