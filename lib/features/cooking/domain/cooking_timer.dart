import 'package:flutter/foundation.dart';

@immutable
class CookingTimer {
  const CookingTimer({
    required this.id,
    required this.label,
    required this.total,
    required this.endsAt,
    this.finished = false,
    this.alertsLeft = 0,
  });

  final int id;
  final String label;
  final Duration total;

  /// Instante de fim (e não "segundos restantes"), para não perder tempo
  /// se a app ficar parada.
  final DateTime endsAt;
  final bool finished;
  final int alertsLeft;

  Duration remaining(DateTime now) {
    final ms = endsAt.difference(now).inMilliseconds;
    return ms <= 0 ? Duration.zero : Duration(seconds: (ms / 1000).ceil());
  }

  CookingTimer copyWith({bool? finished, int? alertsLeft}) => CookingTimer(
        id: id,
        label: label,
        total: total,
        endsAt: endsAt,
        finished: finished ?? this.finished,
        alertsLeft: alertsLeft ?? this.alertsLeft,
      );
}
