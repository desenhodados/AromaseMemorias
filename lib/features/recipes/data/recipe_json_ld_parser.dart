import 'dart:convert';

import '../domain/cooking_mode.dart';
import '../domain/recipe.dart';

/// Extrai uma receita dos dados estruturados (schema.org/Recipe em JSON-LD)
/// que a maioria dos sites de receitas inclui no HTML.
abstract final class RecipeJsonLdParser {
  static final _scriptRe = RegExp(
    r'<script[^>]*type\s*=\s*[\x22\x27]application/ld\+json[\x22\x27][^>]*>(.*?)</script>',
    caseSensitive: false,
    dotAll: true,
  );

  static Recipe? parse(String html, {required String id, String? sourceUrl}) {
    for (final match in _scriptRe.allMatches(html)) {
      try {
        final node = _findRecipe(jsonDecode(match.group(1)!.trim()));
        if (node != null) {
          final recipe = _toRecipe(node, id, sourceUrl);
          if (recipe != null) return recipe;
        }
      } on FormatException {
        continue; // bloco JSON inválido: tenta o seguinte
      }
    }
    return null;
  }

  /// URL da imagem principal da receita (campo `image`), se existir.
  static String? imageUrl(String html) {
    for (final match in _scriptRe.allMatches(html)) {
      try {
        final node = _findRecipe(jsonDecode(match.group(1)!.trim()));
        final url = node == null ? null : _imageOf(node['image']);
        if (url != null) return url;
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  static String? _imageOf(Object? v) {
    if (v is String) return v.trim().isEmpty ? null : v.trim();
    if (v is List) {
      for (final e in v) {
        final url = _imageOf(e);
        if (url != null) return url;
      }
      return null;
    }
    if (v is Map) return _imageOf(v['url'] ?? v['contentUrl']);
    return null;
  }

  static Map<String, dynamic>? _findRecipe(Object? data) {
    if (data is List) {
      for (final e in data) {
        final r = _findRecipe(e);
        if (r != null) return r;
      }
      return null;
    }
    if (data is Map) {
      if (_isRecipe(data['@type'])) return Map<String, dynamic>.from(data);
      return _findRecipe(data['@graph']);
    }
    return null;
  }

  static bool _isRecipe(Object? type) =>
      type == 'Recipe' || (type is List && type.contains('Recipe'));

  static Recipe? _toRecipe(Map<String, dynamic> node, String id, String? url) {
    final title = _text(node['name']);
    if (title.isEmpty) return null;

    final ingredients = _asList(node['recipeIngredient'] ?? node['ingredients'])
        .whereType<String>()
        .map(_clean)
        .where((e) => e.isNotEmpty)
        .toList();
    final steps = _steps(node['recipeInstructions']);
    final minutes = _duration(node['totalTime']) ??
        ((_duration(node['prepTime']) ?? 0) + (_duration(node['cookTime']) ?? 0));

    return Recipe(
      id: id,
      title: title,
      modes: guessModes('$title ${_text(node['description'])} ${steps.join(' ')}'),
      minutes: minutes,
      servings: _servings(node['recipeYield']),
      ingredients: ingredients,
      steps: steps,
      sourceUrl: url,
    );
  }

  static Set<CookingMode> guessModes(String text) {
    final t = text.toLowerCase();
    final modes = <CookingMode>{
      if (t.contains('airfryer') ||
          t.contains('air fryer') ||
          t.contains('fritadeira'))
        CookingMode.airfryer,
      if (t.contains('bimby') || t.contains('thermomix')) CookingMode.bimby,
    };
    return modes.isEmpty ? {CookingMode.traditional} : modes;
  }

  static List<String> _steps(Object? v) {
    if (v is String) return _splitLines(v);
    if (v is List) return [for (final e in v) ..._steps(e)];
    if (v is Map) {
      if (v['itemListElement'] != null) return _steps(v['itemListElement']);
      final t = v['text'] ?? v['name'];
      return t is String ? _splitLines(t) : const [];
    }
    return const [];
  }

  static List<String> _splitLines(String s) => s
      .split(RegExp(r'\r?\n|<br\s*/?>', caseSensitive: false))
      .map(_clean)
      .where((e) => e.isNotEmpty)
      .toList();

  /// Duração ISO 8601 (ex.: PT1H30M) em minutos.
  static int? _duration(Object? v) {
    if (v is! String) return null;
    final m = RegExp(
      r'^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:\d+S)?)?$',
      caseSensitive: false,
    ).firstMatch(v.trim());
    if (m == null) return null;
    final total = (int.tryParse(m[1] ?? '') ?? 0) * 1440 +
        (int.tryParse(m[2] ?? '') ?? 0) * 60 +
        (int.tryParse(m[3] ?? '') ?? 0);
    return total == 0 ? null : total;
  }

  static int _servings(Object? v) {
    final value = v is List && v.isNotEmpty ? v.first : v;
    final digits = RegExp(r'\d+').firstMatch(value?.toString() ?? '');
    return int.tryParse(digits?.group(0) ?? '') ?? 1;
  }

  static List<Object?> _asList(Object? v) =>
      v is List ? v : (v is String ? [v] : const []);

  /// Remove etiquetas HTML, converte entidades e normaliza espaços.
  static String cleanText(String s) => _clean(s);

  static String _text(Object? v) => v is String ? _clean(v) : '';

  static String _clean(String s) => _unescape(s.replaceAll(RegExp(r'<[^>]+>'), ' '))
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String _unescape(String s) => s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAllMapped(
        RegExp(r'&#x([0-9a-fA-F]+);'),
        (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
      )
      .replaceAllMapped(
        RegExp(r'&#(\d+);'),
        (m) => String.fromCharCode(int.parse(m[1]!)),
      )
      .replaceAll('&amp;', '&');
}
