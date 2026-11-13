/// Deteta tempos no texto de um passo (ex.: "30 minutos", "1 hora e 30
/// minutos", "1h30", "20 a 25 min", "45 segundos"). Em intervalos usa o menor.
final _combinedRe = RegExp(r'(\d{1,2})\s*h\s*(\d{2})(?!\d)', caseSensitive: false);

final _unitRe = RegExp(
  r'(\d+(?:[.,]\d+)?)(?:\s*(?:a|-|–|ou)\s*\d+(?:[.,]\d+)?)?\s*'
  r'(horas?|hrs?|h|minutos?|mins?|segundos?|segs?)(?![a-zA-ZçÇãÃâêôéíóúÁÉÍÓÚ])',
  caseSensitive: false,
);

double _number(String s) => double.parse(s.replaceAll(',', '.'));

List<Duration> extractDurations(String text) {
  final found = <(int, Duration)>[];

  for (final m in _combinedRe.allMatches(text)) {
    found.add((
      m.start,
      Duration(hours: int.parse(m[1]!), minutes: int.parse(m[2]!)),
    ));
  }
  final rest = text.replaceAllMapped(_combinedRe, (m) => ' ' * m.group(0)!.length);

  final matches = _unitRe.allMatches(rest).toList();
  for (var i = 0; i < matches.length; i++) {
    final m = matches[i];
    final value = _number(m[1]!);
    final unit = m[2]!.toLowerCase();

    if (unit.startsWith('h')) {
      var total = Duration(minutes: (value * 60).round());
      // "1 hora e 30 minutos"
      if (i + 1 < matches.length) {
        final next = matches[i + 1];
        final gap = rest.substring(m.end, next.start);
        if (next[2]!.toLowerCase().startsWith('min') &&
            RegExp(r'^\s*(?:e|,)?\s*$').hasMatch(gap)) {
          total += Duration(minutes: _number(next[1]!).round());
          i++;
        }
      }
      found.add((m.start, total));
    } else if (unit.startsWith('min')) {
      found.add((m.start, Duration(seconds: (value * 60).round())));
    } else {
      found.add((m.start, Duration(seconds: value.round())));
    }
  }

  found.sort((a, b) => a.$1.compareTo(b.$1));
  final result = <Duration>[];
  for (final f in found) {
    if (f.$2 > Duration.zero && !result.contains(f.$2)) result.add(f.$2);
  }
  return result;
}

/// Ex.: `1 h 30 min`, `45 s`.
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  final parts = [
    if (h > 0) '$h h',
    if (m > 0) '$m min',
    if (s > 0 && h == 0) '$s s',
  ];
  return parts.isEmpty ? '0 s' : parts.join(' ');
}

/// Contagem decrescente: `29:59` ou `1:05:00`.
String formatClock(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
}
