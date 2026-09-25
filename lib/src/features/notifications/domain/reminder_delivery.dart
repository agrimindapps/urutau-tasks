// Contrato de notificações e estados de entrega (spec 08).

import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

/// Estados exibidos no detalhe da tarefa (spec 08, seção 3.2).
enum ReminderDeliveryState {
  scheduled,
  permissionNeeded,
  unavailable,
  expired,
  pending,
}

/// Status de permissão do sistema/navegador (spec 08, seção 6).
enum NotificationPermission { granted, denied, notDetermined, unavailable }

/// Resultado da consulta de capacidade (spec 08, seção 5 — consultar
/// capacidade e permissão, sem alterar estado).
class NotificationCapability {
  const NotificationCapability({
    required this.supported,
    required this.permission,
    required this.canRequestPermission,
    required this.supportsScheduling,
    this.limitationKey,
  });

  final bool supported;
  final NotificationPermission permission;

  /// Só pode ser `true` antes da primeira negativa (spec 08, seção 6:
  /// após negativa, sem pedido automático).
  final bool canRequestPermission;

  /// A plataforma agenda avisos por conta própria (Android/iOS/macOS/
  /// Windows). Quando `false` (Web, Linux), a entrega enquanto o app
  /// estiver vivo usa os temporizadores do coordenador.
  final bool supportsScheduling;

  /// Chave i18n opcional da limitação relevante (matriz da spec 08).
  final String? limitationKey;

  static const unsupported = NotificationCapability(
    supported: false,
    permission: NotificationPermission.unavailable,
    canRequestPermission: false,
    supportsScheduling: false,
    limitationKey: 'reminderStateUnavailable',
  );
}

/// Contrato do adaptador (spec 08, seção 5).
abstract interface class NotificationAdapter {
  /// A plataforma agenda avisos por conta própria (matriz da spec 08).
  /// Quando `false` (Web, Linux), a entrega depende do processo vivo.
  bool get supportsScheduling;

  /// Consulta capacidade/permissão sem abrir diálogo nem alterar estado.
  Future<NotificationCapability> checkCapability();

  /// Abre o fluxo do sistema apenas em resposta a ação explícita do
  /// usuário (spec 08, CA-01).
  Future<NotificationPermission> requestPermission();

  /// Agenda um único aviso futuro; substitui o agendamento anterior do
  /// mesmo [id] (spec 08, RF-01/RF-02/CA-03).
  Future<bool> schedule({
    required int id,
    required String title,
    required DateTime whenUtc,
    required String payload,
  });

  /// Cancela o aviso do [id]. Idempotente (spec 08, seção 5).
  Future<void> cancel(int id);

  /// Mostra um aviso imediato quando o sistema não agenda e o app está
  /// em segundo plano (Web em aba oculta, Linux com processo vivo).
  Future<void> showImmediate({
    required int id,
    required String title,
    required String payload,
  });

  /// Callback de toque no aviso do sistema: payload = UUID da tarefa
  /// (spec 08, CA-06).
  void setOnOpened(void Function(String payload)? callback);
}

/// Identificador estável derivado do UUID da tarefa (spec 08, seção 5):
/// no máximo um agendamento por tarefa, sem compartilhar IDs do sistema.
/// Hash polinomial de 31 bits sobre o UUID completo — determinístico e
/// independente da representação usada pelo sistema operacional.
int notificationIdFor(String taskId) {
  var hash = 0;
  for (final code in taskId.codeUnits) {
    hash = 0x1FFFFFFF & (hash * 31 + code);
  }
  return hash;
}

/// Elegibilidade de um lembrete (spec 08, RF-05): tarefa existente,
/// ativa, fora da lixeira e com instante futuro. Sem catch-up (CA-08).
bool isReminderEligible(Task task, DateTime now) =>
    task.isActive && task.reminder != null && task.reminder!.isAfter(now);

/// Estado de entrega calculado para exibição (spec 08, seção 3.2).
ReminderDeliveryState deliveryStateFor({
  required Task task,
  required DateTime now,
  NotificationCapability? capability,
  bool capabilityFailed = false,
}) {
  if (task.reminder == null) {
    throw ArgumentError('task has no reminder');
  }
  if (!task.reminder!.isAfter(now)) return ReminderDeliveryState.expired;
  if (capabilityFailed) return ReminderDeliveryState.pending;
  if (capability == null) return ReminderDeliveryState.pending;
  if (!capability.supported) return ReminderDeliveryState.unavailable;
  if (capability.permission != NotificationPermission.granted) {
    return ReminderDeliveryState.permissionNeeded;
  }
  return ReminderDeliveryState.scheduled;
}

/// Aviso em primeiro plano (spec 08, CA-05).
class InAppReminder {
  const InAppReminder({required this.taskId, required this.title});

  final String taskId;
  final String title;
}
