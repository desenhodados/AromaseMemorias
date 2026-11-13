/// Ajusta as quantidades de um ingrediente escrito em texto livre.
///
/// Escala o número no início da linha ("500 g", "1 1/2", "½", "1,5 kg",
/// "2 a 3") e os que vêm no início de parênteses ("1 chávena (250 ml)").
/// Linhas sem quantidade ("sal q.b.") ficam como estão. Os nomes não são
/// alterados (ex.: "1 cebola" passa a "2 cebola").
List<String> scaleIngredients(
  List<String> lines, {
  required int from,
  required int to,
}) {
  if (from <= 0 || to <= 0 || from == to) return lines;
  final factor = to / from;
  return [for (final l in lines) scaleIngredient(l, factor)];
}

String scaleIngredient(String line, double factor) {
  if (factor == 1) return line;
  final scaled = _scaleLeading(line, factor);
  return scaled.replaceAllMapped(
    RegExp(r'\(([^)]*)\)'),
    (m) => '(${_scaleLeading(m[1]!, factor)})',
  );
}

const _fractions = {
  '½': 0.5,
  '¼': 0.25,
  '¾': 0.75,
  '⅓': 1 / 3,
  '⅔': 2 / 3,
  '⅛': 0.125,
};

final _qtyRe = RegExp(
  r'(?<w1>\d+)\s*(?<f1>[½¼¾⅓⅔⅛])'
  r'|(?<f2>[½¼¾⅓⅔⅛])'
  r'|(?<w3>\d+)\s+(?<n3>\d+)/(?<d3>\d+)'
  r'|(?<n4>\d+)/(?<d4>\d+)'
  r'|(?<th>\d{1,3}(?:\.\d{3})+)(?!\d)'
  r'|(?<num>\d+(?:[.,]\d+)?)',
);

/// Lê uma quantidade ("500", "1,5", "1/2", "1 1/2", "½") a partir de [pos].
({double value, int end})? readQuantity(String s, int pos) {
  final m = _qtyRe.matchAsPrefix(s, pos) as RegExpMatch?;
  if (m == null) return null;

  double value;
  if (m.namedGroup('w1') != null) {
    value = double.parse(m.namedGroup('w1')!) + _fractions[m.namedGroup('f1')]!;
  } else if (m.namedGroup('f2') != null) {
    value = _fractions[m.namedGroup('f2')]!;
  } else if (m.namedGroup('w3') != null) {
    final d = int.parse(m.namedGroup('d3')!);
    if (d == 0) return null;
    value = double.parse(m.namedGroup('w3')!) + int.parse(m.namedGroup('n3')!) / d;
  } else if (m.namedGroup('n4') != null) {
    final d = int.parse(m.namedGroup('d4')!);
    if (d == 0) return null;
    value = int.parse(m.namedGroup('n4')!) / d;
  } else if (m.namedGroup('th') != null) {
    value = double.parse(m.namedGroup('th')!.replaceAll('.', ''));
  } else {
    value = double.parse(m.namedGroup('num')!.replaceAll(',', '.'));
  }
  return (value: value, end: m.end);
}

/// "100% cacau" e "1. farinha" não são quantidades.
bool quantityBlocked(String s, int end) =>
    end < s.length && '%.)'.contains(s[end]);

String _scaleLeading(String s, double factor) {
  final lead = RegExp(r'^\s*').firstMatch(s)!.end;
  final first = readQuantity(s, lead);
  if (first == null || quantityBlocked(s, first.end)) return s;

  var end = first.end;
  var out = s.substring(0, lead) + formatQuantity(first.value * factor);

  // Intervalos: "2 a 3", "2-3", "2 ou 3".
  final range = RegExp(r'^\s*(?:-|–|a|ou)\s*').firstMatch(s.substring(end));
  if (range != null) {
    final secondAt = end + range.end;
    final second = readQuantity(s, secondAt);
    if (second != null && !quantityBlocked(s, second.end)) {
      out += s.substring(end, secondAt) + formatQuantity(second.value * factor);
      end = second.end;
    }
  }
  return out + s.substring(end);
}

String formatQuantity(double v) {
  if (v >= 20) return v.round().toString();

  const steps = [0.0, 0.25, 1 / 3, 0.5, 2 / 3, 0.75, 1.0];
  const symbols = ['', '¼', '⅓', '½', '⅔', '¾', ''];

  var whole = v.floor();
  final frac = v - whole;
  var best = 0;
  for (var i = 1; i < steps.length; i++) {
    if ((frac - steps[i]).abs() < (frac - steps[best]).abs()) best = i;
  }
  if ((frac - steps[best]).abs() > 0.04) {
    return v.toStringAsFixed(1).replaceAll('.', ',');
  }
  if (steps[best] == 1.0) whole += 1;

  final symbol = symbols[best];
  if (symbol.isEmpty) return '$whole';
  return whole == 0 ? symbol : '$whole $symbol';
}
