import 'dart:async';

import '../../tasks/domain/task.dart';
import '../domain/reminder_delivery.dart';

/// Agendador de avisos de primeiro plano (spec 08, §8).
abstract class ForegroundScheduler {
  /// Registra o disparo em [time]; devolve um identificador do agendamento.
  Object scheduleAt(DateTime time, void Function() fire);

  void cancel(Object handle);
}

/// Implementação baseada em `Timer`.
class TimerForegroundScheduler implements ForegroundScheduler {
  @override
  Object scheduleAt(DateTime time, void Function() fire) {
    final delay = time.difference(DateTime.now());
    return Timer(delay.isNegative ? Duration.zero : delay, fire);
  }

  @override
  void cancel(Object handle) {
    (handle as Timer).cancel();
  }
}

/// Estado de entrega por tarefa.
class TaskDeliveryStatus {
  const TaskDeliveryStatus(this.taskId, this.state);

  final String taskId;
  final DeliveryState state;
}

/// Orquestra agendamento, cancelamento e reconciliação de lembretes
/// (spec 08, RF-01 a RF-05).
///
/// Regras:
/// - a configuração do lembrete nunca é alterada por este coordenador;
/// - pedidos de permissão só ocorrem por ação explícita do usuário (§6);
/// - instante no passado não gera agendamento nem catch-up (§8);
/// - em primeiro plano o disparo vira aviso no app **ou** notificação do
///   sistema, nunca os dois (§8).
class ReminderCoordinator {
  ReminderCoordinator(
    this._adapter,
    this._permissionStore, {
    ForegroundScheduler? foreground,
    DateTime Function()? clock,
    this.onForegroundNotice,
  })  : _foreground = foreground ?? TimerForegroundScheduler(),
        _clock = clock ?? DateTime.now;

  final ReminderAdapter _adapter;
  final ReminderPermissionStore _permissionStore;
  final ForegroundScheduler _foreground;
  final DateTime Function() _clock;
  final void Function(Task task)? onForegroundNotice;

  final Map<String, Object> _foregroundHandles = {};
  final Map<String, DeliveryState> _states = {};
  StreamSubscription<List<Task>>? _subscription;

  /// Vincula o coordenador às mudanças de tarefas: cada emissão dispara a
  /// reconciliação idempotente (spec 08, RF-05).
  void bindTo(Stream<List<Task>> tasks) {
    _subscription?.cancel();
    _subscription = tasks.listen((items) {
      unawaited(reconcile(items));
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    for (final handle in _foregroundHandles.values) {
      _foreground.cancel(handle);
    }
    _foregroundHandles.clear();
    await _notices.close();
    await _stateChanges.close();
  }

  DeliveryState stateOf(String taskId) =>
      _states[taskId] ?? DeliveryState.pendingVerification;

  /// Emissões a cada mudança de estado de entrega (para atualizar a UI).
  Stream<String> get stateChanges => _stateChanges.stream;

  final StreamController<String> _stateChanges = StreamController.broadcast();

  /// Aplica o estado atual da tarefa aos agendamentos (RF-01 a RF-03).
  Future<DeliveryState> apply(Task task) async {
    final reminder = task.reminder;
    final eligible = task.status == TaskStatus.active &&
        !task.isTrashed &&
        reminder != null;

    if (!eligible) {
      // Concluir/excluir cancela o aviso e preserva a configuração (RF-03).
      await _cancel(task.id);
      return _record(task.id, DeliveryState.overdue);
    }

    if (!reminder.isAfter(_clock())) {
      // Vencido: sem agendamento e sem catch-up (§8).
      await _cancel(task.id);
      return _record(task.id, DeliveryState.overdue);
    }

    final capability = await _adapter.queryCapability();
    if (capability == ReminderCapability.unsupported) {
      return _record(task.id, DeliveryState.platformUnsupported);
    }

    final permission = await _adapter.queryPermission();
    if (permission != ReminderPermission.granted) {
      // Revogada/negada: configuração preservada e pendentes cancelados
      // quando possível (§6).
      await _cancel(task.id);
      return _record(task.id, DeliveryState.permissionNeeded);
    }

    await _adapter.schedule(
      taskId: task.id,
      title: task.title,
      fireAt: reminder,
    );
    _scheduleForeground(task, reminder);
    return _record(task.id, DeliveryState.scheduled);
  }

  /// Reconciliação idempotente (RF-05): cria ausentes, atualiza alterados e
  /// cancela os que não se aplicam, sem pedir permissão e sem alterar o
  /// domínio.
  Future<void> reconcile(List<Task> tasks) async {
    final seen = <String>{};
    for (final task in tasks) {
      seen.add(task.id);
      await apply(task);
    }
    for (final taskId in _states.keys.toList()) {
      if (!seen.contains(taskId)) {
        await _cancel(taskId);
        _states.remove(taskId);
      }
    }
  }

  /// Notificações de primeiro plano disparadas (spec 08, §8).
  Stream<Task> get foregroundNotices => _notices.stream;

  final StreamController<Task> _notices = StreamController<Task>.broadcast();

  /// Ação explícita do usuário: única ocasião de pedir permissão (§6, CA-01).
  Future<DeliveryState> requestPermissionFromUser(Task task) async {
    await _permissionStore.markRequested();
    await _adapter.requestPermission();
    return apply(task);
  }

  /// Cancela o aviso agendado da tarefa (idempotente).
  Future<void> cancelForTask(String taskId) => _cancel(taskId);

  Future<void> _cancel(String taskId) async {
    await _adapter.cancel(taskId: taskId);
    final handle = _foregroundHandles.remove(taskId);
    if (handle != null) {
      _foreground.cancel(handle);
    }
  }

  void _scheduleForeground(Task task, DateTime fireAt) {
    final previous = _foregroundHandles.remove(task.id);
    if (previous != null) {
      _foreground.cancel(previous);
    }
    _foregroundHandles[task.id] = _foreground.scheduleAt(fireAt, () {
      _foregroundHandles.remove(task.id);
      // Em primeiro plano: aviso no app e cancela o do sistema (§8).
      unawaited(_adapter.cancel(taskId: task.id));
      onForegroundNotice?.call(task);
      _notices.add(task);
    });
  }

  DeliveryState _record(String taskId, DeliveryState state) {
    _states[taskId] = state;
    _stateChanges.add(taskId);
    return state;
  }
}
