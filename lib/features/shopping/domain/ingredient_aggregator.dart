import '../../../core/text_utils.dart';
import '../../recipes/domain/ingredient_scaler.dart';
import 'shopping_item.dart';
import 'supermarket_section.dart';

enum IngredientKind { none, mass, volume, count }

class _UnitSpec {
  const _UnitSpec(this.pattern, this.kind, this.factor, this.singular, this.plural);

  final String pattern;
  final IngredientKind kind;

  /// Fator para a unidade-base (g ou ml).
  final double factor;
  final String singular;
  final String plural;
}

// Ordem importa: o primeiro padrão que coincidir ganha.
const _specs = <_UnitSpec>[
  // massa (base: g)
  _UnitSpec(r'quilogramas?|quilos?|kg', IngredientKind.mass, 1000, 'kg', 'kg'),
  _UnitSpec(r'miligramas?|mg', IngredientKind.mass, 0.001, 'mg', 'mg'),
  _UnitSpec(r'gramas?|gr|g', IngredientKind.mass, 1, 'g', 'g'),
  // volume (base: ml)
  _UnitSpec(r'litros?|lts?|l', IngredientKind.volume, 1000, 'l', 'l'),
  _UnitSpec(r'mililitros?|ml', IngredientKind.volume, 1, 'ml', 'ml'),
  _UnitSpec(r'centilitros?|cl', IngredientKind.volume, 10, 'cl', 'cl'),
  _UnitSpec(r'decilitros?|dl', IngredientKind.volume, 100, 'dl', 'dl'),
  // contagem
  _UnitSpec(r'colheres? de sopa', IngredientKind.count, 1, 'colher de sopa', 'colheres de sopa'),
  _UnitSpec(r'colheres? de sobremesa', IngredientKind.count, 1, 'colher de sobremesa', 'colheres de sobremesa'),
  _UnitSpec(r'colheres? de (?:chá|cha)', IngredientKind.count, 1, 'colher de chá', 'colheres de chá'),
  _UnitSpec(r'colheres? de (?:café|cafe)', IngredientKind.count, 1, 'colher de café', 'colheres de café'),
  _UnitSpec(r'colheres?', IngredientKind.count, 1, 'colher', 'colheres'),
  _UnitSpec(r'chávenas?|chavenas?', IngredientKind.count, 1, 'chávena', 'chávenas'),
  _UnitSpec(r'copos?', IngredientKind.count, 1, 'copo', 'copos'),
  _UnitSpec(r'pitadas?', IngredientKind.count, 1, 'pitada', 'pitadas'),
  _UnitSpec(r'dentes?', IngredientKind.count, 1, 'dente', 'dentes'),
  _UnitSpec(r'fatias?', IngredientKind.count, 1, 'fatia', 'fatias'),
  _UnitSpec(r'folhas?', IngredientKind.count, 1, 'folha', 'folhas'),
  _UnitSpec(r'ramos?', IngredientKind.count, 1, 'ramo', 'ramos'),
  _UnitSpec(r'latas?', IngredientKind.count, 1, 'lata', 'latas'),
  _UnitSpec(r'pacotes?', IngredientKind.count, 1, 'pacote', 'pacotes'),
  _UnitSpec(r'embalagens?', IngredientKind.count, 1, 'embalagem', 'embalagens'),
  _UnitSpec(r'fios?', IngredientKind.count, 1, 'fio', 'fios'),
  _UnitSpec(r'cubos?', IngredientKind.count, 1, 'cubo', 'cubos'),
  _UnitSpec(r'molhos?', IngredientKind.count, 1, 'molho', 'molhos'),
  _UnitSpec(r'maços?|macos?', IngredientKind.count, 1, 'maço', 'maços'),
  _UnitSpec(r'unidades?', IngredientKind.count, 1, 'unidade', 'unidades'),
  _UnitSpec(r'saquetas?', IngredientKind.count, 1, 'saqueta', 'saquetas'),
  _UnitSpec(r'punhados?', IngredientKind.count, 1, 'punhado', 'punhados'),
  _UnitSpec(r'rodelas?', IngredientKind.count, 1, 'rodela', 'rodelas'),
  _UnitSpec(r'pedaços?|pedacos?', IngredientKind.count, 1, 'pedaço', 'pedaços'),
];

final _unitRes = [
  for (final s in _specs)
    RegExp('^(?:${s.pattern})(?![A-Za-zÀ-ÿ])', caseSensitive: false),
];

final _pluralOf = {
  for (final s in _specs)
    if (s.kind == IngredientKind.count) s.singular: s.plural,
};

class ParsedIngredient {
  const ParsedIngredient({
    required this.raw,
    required this.name,
    required this.kind,
    this.quantity,
    this.unit = '',
  });

  final String raw;

  /// Nome sem quantidade, unidade nem notas ("cebola, picada" → "cebola").
  final String name;
  final IngredientKind kind;

  /// Em g/ml para massa/volume; no número de unidades para contagem.
  final double? quantity;

  /// Unidade de contagem no singular ("colher de sopa"); vazio nos outros casos.
  final String unit;

  /// Ingredientes com a mesma chave somam-se.
  String get key => '${kind.name}|$unit|${_normalize(name)}';
}

String _normalize(String name) => stripPlurals(name);

String _cleanName(String s) {
  final cut = s.indexOf(RegExp(r'[,(]'));
  final base = (cut == -1 ? s : s.substring(0, cut)).trim();
  return base.isEmpty ? s.trim() : base;
}

/// Separa "500 g de farinha" em quantidade (500), unidade (g) e nome (farinha).
ParsedIngredient parseIngredient(String line) {
  final raw = line.trim();
  final first = raw.isEmpty ? null : readQuantity(raw, 0);
  if (first == null || quantityBlocked(raw, first.end)) {
    return ParsedIngredient(raw: raw, name: _cleanName(raw), kind: IngredientKind.none);
  }

  var value = first.value;
  var end = first.end;
  final range = RegExp(r'^\s*(?:-|–|a|ou)\s*').firstMatch(raw.substring(end));
  if (range != null) {
    final second = readQuantity(raw, end + range.end);
    if (second != null && !quantityBlocked(raw, second.end)) {
      // Intervalo ("4 a 6"): para comprar, conta o maior.
      value = value > second.value ? value : second.value;
      end = second.end;
    }
  }

  var rest = raw.substring(end).trimLeft();
  var kind = IngredientKind.count;
  var unit = '';
  var quantity = value;
  for (var i = 0; i < _specs.length; i++) {
    final m = _unitRes[i].firstMatch(rest);
    if (m == null) continue;
    final spec = _specs[i];
    kind = spec.kind;
    quantity = value * spec.factor;
    unit = spec.kind == IngredientKind.count ? spec.singular : '';
    rest = rest.substring(m.end).trimLeft();
    break;
  }
  rest = rest.replaceFirst(
    RegExp(r'^(?:de|da|do|das|dos)\s+', caseSensitive: false),
    '',
  );

  return ParsedIngredient(
    raw: raw,
    name: _cleanName(rest.isEmpty ? raw : rest),
    kind: kind,
    quantity: quantity,
    unit: unit,
  );
}

class _Group {
  _Group(ParsedIngredient first)
      : key = first.key,
        kind = first.kind,
        unit = first.unit,
        firstRaw = first.raw;

  final String key;
  final IngredientKind kind;
  final String unit;
  final String firstRaw;
  double total = 0;
  final meals = <int>{};
  final names = <String>[];

  void add(ParsedIngredient p, int meal) {
    total += p.quantity ?? 0;
    meals.add(meal);
    names.add(p.name);
  }

  String get sortName => _normalize(names.first);

  /// Identifica só o ingrediente (sem unidade), para a secção escolhida pelo utilizador.
  String get ingredientKey => foldAccents(_normalize(names.first));

  SupermarketSection get section =>
      SupermarketSection.classify(names.first, unit: unit);

  String get label {
    if (kind == IngredientKind.none) return firstRaw;

    // Plural quando há mais de um (a variante mais comprida costuma ser o plural).
    final sorted = [...names]..sort((a, b) => a.length.compareTo(b.length));
    final name = total > 1 ? sorted.last : sorted.first;

    switch (kind) {
      case IngredientKind.mass:
        return total >= 1000
            ? '${_decimal(total / 1000)} kg de $name'
            : '${formatQuantity(total)} g de $name';
      case IngredientKind.volume:
        return total >= 1000
            ? '${_decimal(total / 1000)} l de $name'
            : '${formatQuantity(total)} ml de $name';
      case IngredientKind.count:
        final qty = formatQuantity(total);
        if (unit.isEmpty) return '$qty $name';
        final unitName = total > 1 ? (_pluralOf[unit] ?? unit) : unit;
        return '$qty $unitName de $name';
      case IngredientKind.none:
        return firstRaw;
    }
  }
}

String _decimal(double v) {
  var s = v.toStringAsFixed(2);
  s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return s.replaceAll('.', ',');
}

/// Junta os ingredientes de várias refeições (já ajustados às porções),
/// somando quantidades do mesmo ingrediente e unidade.
List<ShoppingItem> aggregateIngredients(
  List<List<String>> meals, {
  Set<String> checked = const {},
  Map<String, SupermarketSection> overrides = const {},
}) {
  final groups = <String, _Group>{};
  for (var m = 0; m < meals.length; m++) {
    for (final line in meals[m]) {
      final p = parseIngredient(line);
      if (p.raw.isEmpty || _isTapWater(p)) continue;
      groups.putIfAbsent(p.key, () => _Group(p)).add(p, m);
    }
  }
  final sorted = groups.values.toList()
    ..sort((a, b) => a.sortName.compareTo(b.sortName));
  return [
    for (final g in sorted)
      ShoppingItem(
        key: g.key,
        name: g.label,
        count: g.meals.length,
        checked: checked.contains(g.key),
        ingredientKey: g.ingredientKey,
        section: overrides[g.ingredientKey] ?? g.section,
        sectionIsCustom: overrides.containsKey(g.ingredientKey),
      ),
  ];
}

/// "200 ml de água" não se compra: fica fora da lista de compras.
final _tapWaterRe = RegExp(
  r'^agua(?: (?:fria|morna|quente|gelada|a ferver|fervente|de cozer|do cozer|da cozedura))?$',
);

bool _isTapWater(ParsedIngredient p) =>
    p.kind != IngredientKind.none && _tapWaterRe.hasMatch(foldAccents(p.name));
