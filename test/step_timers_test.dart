import 'package:aromas_memorias/features/cooking/domain/step_timers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractDurations', () {
    test('minutos', () {
      expect(extractDurations('Coza durante 30 minutos.'), [const Duration(minutes: 30)]);
    });

    test('intervalo usa o menor valor', () {
      expect(extractDurations('Leve ao forno 20 a 25 min.'), [const Duration(minutes: 20)]);
    });

    test('1 hora e 30 minutos soma', () {
      expect(extractDurations('Deixe repousar 1 hora e 30 minutos.'), [const Duration(minutes: 90)]);
    });

    test('formato 1h30', () {
      expect(extractDurations('Asse durante 1h30.'), [const Duration(minutes: 90)]);
    });

    test('segundos', () {
      expect(extractDurations('Misture 45 segundos na vel. 4.'), [const Duration(seconds: 45)]);
    });

    test('vários tempos no mesmo passo', () {
      expect(
        extractDurations('Coza 10 minutos e depois mais 5 minutos.'),
        [const Duration(minutes: 10), const Duration(minutes: 5)],
      );
    });

    test('não confunde palavras com unidades', () {
      expect(extractDurations('Junte 3 hortelã e 2 ovos.'), isEmpty);
    });
  });

  test('formatDuration e formatClock', () {
    expect(formatDuration(const Duration(minutes: 90)), '1 h 30 min');
    expect(formatDuration(const Duration(seconds: 45)), '45 s');
    expect(formatClock(const Duration(minutes: 29, seconds: 5)), '29:05');
    expect(formatClock(const Duration(hours: 1, minutes: 5)), '1:05:00');
  });
}
