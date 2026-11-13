import 'package:aromas_memorias/features/cooking/application/cooking_providers.dart';
import 'package:aromas_memorias/features/cooking/data/timer_alarm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAlarm implements TimerAlarm {
  @override
  Future<void> ring() async {}

  @override
  void dispose() {}
}

void main() {
  test('adiciona e remove temporizadores', () {
    final container = ProviderContainer(
      overrides: [timerAlarmProvider.overrideWithValue(_FakeAlarm())],
    );
    addTearDown(container.dispose);
    container.listen(cookingTimersProvider, (_, __) {});

    final notifier = container.read(cookingTimersProvider.notifier);
    notifier.start(const Duration(minutes: 1), 'Passo 1');
    notifier.start(const Duration(minutes: 5), 'Passo 2');

    var timers = container.read(cookingTimersProvider);
    expect(timers, hasLength(2));
    expect(timers.first.remaining(DateTime.now()).inSeconds, inInclusiveRange(59, 60));

    notifier.remove(timers.first.id);
    timers = container.read(cookingTimersProvider);
    expect(timers.map((t) => t.label), ['Passo 2']);
  });
}
