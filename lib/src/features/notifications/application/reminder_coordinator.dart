import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../tasks/domain/task.dart';
import '../../tasks/domain/task_repository.dart';
import '../domain/reminder_delivery.dart';

/// Coordena a entrega de lembretes (spec 08, RF-01 a RF-05 e seção 8).
///
/// - temporizadores para o primeiro plano (aviso no app, CA-05);
/// - camada de sistema quando a plataforma agenda (segundo plano,
///   CA-13) — só fora do primeiro plano, para nunca duplicar o disparo;
/// - sem catch-up de instantes vencidos (CA-08);
/// - reconciliação idempotente (RF-05/CA-10) a partir apenas dos dados
///   persistidos, sem abrir pedido de permissão.
class ReminderCoordinator {
  ReminderCoordinator({
    required this._adapter,
    required this._tasks,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _adapter.setOnOpened((payload) => onNotificationOpened?.call(payload));
  }

  final NotificationAdapter _adapter;
  final TaskRepository _tasks;
  final DateTime Function() _now;

  final _timers = <String, Timer>{};
  final _inAppController = StreamController<InAppReminder>.broadcast();

  /// Estado do ciclo de vida em relação ao primeiro plano.
  AppLifecycleState phase = AppLifecycleState.resumed;

  /// Fluxo de avisos em primeiro plano (spec 08, CA-05).
  Stream<InAppReminder> get inAppReminders => _inAppController.stream;

  /// Navegação ao toque de notificação do sistema (spec 08, CA-06);
  /// definido pela casca do aplicativo.
  void Function(String taskId)? onNotificationOpened;

  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    unawaited(_inAppController.close());
  }

  /// RF-05/CA-10: reconciliação idempotente — agenda ausentes, substitui
  /// alterados, cancela os que não se aplicam mais e recompõe os
  /// temporizadores. Nunca pede permissão nem altera dados de domínio.
  Future<void> reconcile() async {
    final now = _now();
    final all = await _tasks.watchTasks(includeTrashed: true).first;
    final withReminder = <Task>[
      for (final task in all)
        if (task.reminder != null) task,
    ];
    final eligible = <Task>[
      for (final task in withReminder)
        if (isReminderEligible(task, now)) task,
    ];

    NotificationCapability capability;
    try {
      capability = await _adapter.checkCapability();
    } catch (_) {
      capability = NotificationCapability.unsupported;
    }

    // Camada de sistema (CA-13): agenda somente fora do primeiro plano;
    // em primeiro plano cancela para o aviso no app não duplicar (CA-05).
    final systemActive = capability.supported &&
        capability.permission == NotificationPermission.granted &&
        _adapter.supportsScheduling &&
        phase != AppLifecycleState.resumed;

    final eligibleIds = eligible.map((t) => t.id).toSet();
    for (final task in withReminder) {
      final keepInSystem = systemActive && eligibleIds.contains(task.id);
      if (!keepInSystem) {
        // Idempotente; cobre conclusão, lixeira, vencidos, órfãos e a
        // transição de ciclo de vida (RF-05/CA-04/CA-10).
        await _adapter.cancel(notificationIdFor(task.id));
      }
    }
    if (systemActive) {
      for (final task in eligible) {
        await _adapter.schedule(
          id: notificationIdFor(task.id),
          title: task.title,
          whenUtc: task.reminder!.toUtc(),
          payload: task.id,
        );
      }
    }

    // Temporizadores de primeiro plano; vencidos ficam de fora (CA-08).
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    for (final task in eligible) {
      final delay = task.reminder!.difference(now);
      _timers[task.id] = Timer(delay, () => _onTimer(task.id));
    }
  }

  /// Atualiza o ciclo de vida e reconcilia (RF-05: iniciar/retomar).
  void setPhase(AppLifecycleState next) {
    if (next == phase) return;
    phase = next;
    unawaited(reconcile());
  }

  Future<ReminderDeliveryState> deliveryState(Task task) async {
    if (task.reminder == null) {
      throw ArgumentError('task has no reminder');
    }
    NotificationCapability? capability;
    var failed = false;
    try {
      capability = await _adapter.checkCapability();
    } catch (_) {
      failed = true;
    }
    return deliveryStateFor(
      task: task,
      now: _now(),
      capability: capability,
      capabilityFailed: failed,
    );
  }

  Future<void> _onTimer(String taskId) async {
    _timers.remove(taskId);
    final task = await _tasks.getTask(taskId);
    if (task == null) return;
    // Vencido entre o agendamento e o disparo: sem catch-up (CA-08).
    // No instante do disparo `now == reminder` ainda é o aviso correto
    // (não é vencimento — este só vale para instantes estritamente
    // anteriores ao momento atual).
    if (task.reminder == null || task.reminder!.isBefore(_now())) return;
    if (!task.isActive) return;

    if (phase == AppLifecycleState.resumed) {
      _inAppController.add(InAppReminder(taskId: task.id, title: task.title));
      return;
    }
    // Segundo plano sem agendamento do sistema (Web/Linux): aviso
    // imediato enquanto o processo estiver vivo; sem promessa depois
    // (CA-09/CA-13).
    if (!_adapter.supportsScheduling) {
      await _adapter.showImmediate(
        id: notificationIdFor(task.id),
        title: task.title,
        payload: task.id,
      );
    }
    // Com agendamento do sistema o aviso é do sistema — não duplica.
  }
}
