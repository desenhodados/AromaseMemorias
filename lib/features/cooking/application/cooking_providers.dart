import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/timer_alarm.dart';
import '../domain/cooking_timer.dart';

final timerAlarmProvider = Provider.autoDispose<TimerAlarm>((ref) {
  final alarm = DeviceTimerAlarm();
  ref.onDispose(alarm.dispose);
  return alarm;
});

/// Temporizadores da sessão de cozinha (desaparecem ao sair do ecrã).
class CookingTimersNotifier extends AutoDisposeNotifier<List<CookingTimer>> {
  static const _alertRepeats = 8;

  Timer? _ticker;
  int _nextId = 0;
  late final TimerAlarm _alarm;

  @override
  List<CookingTimer> build() {
    _alarm = ref.watch(timerAlarmProvider);
    ref.onDispose(() => _ticker?.cancel());
    return const [];
  }

  void start(Duration total, String label) {
    state = [
      ...state,
      CookingTimer(
        id: _nextId++,
        label: label,
        total: total,
        endsAt: DateTime.now().add(total),
      ),
    ];
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void remove(int id) {
    state = [
      for (final t in state)
        if (t.id != id) t,
    ];
    if (state.isEmpty) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _tick() {
    final now = DateTime.now();
    var alert = false;
    final next = <CookingTimer>[];
    for (final t in state) {
      if (!t.finished && !t.endsAt.isAfter(now)) {
        next.add(t.copyWith(finished: true, alertsLeft: _alertRepeats));
        alert = true;
      } else if (t.finished && t.alertsLeft > 0) {
        next.add(t.copyWith(alertsLeft: t.alertsLeft - 1));
        alert = true;
      } else {
        next.add(t);
      }
    }
    state = next; // nova lista a cada segundo: atualiza a contagem no ecrã
    if (alert) _alarm.ring();
  }
}

final cookingTimersProvider =
    NotifierProvider.autoDispose<CookingTimersNotifier, List<CookingTimer>>(
  CookingTimersNotifier.new,
);
