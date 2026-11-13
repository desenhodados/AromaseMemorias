import '../domain/recipe.dart';
import 'recipe_json_ld_parser.dart';

/// Plano B para páginas sem dados estruturados (ex.: blogs): procura os
/// títulos "Ingredientes" e "Preparação" no texto da página.
abstract final class RecipeHtmlParser {
  // Grupos: 1 = complemento do título, 2 = ":" (se existir), 3 = resto da linha.
  static final _ingredientsRe = RegExp(r'^ingredientes?([^:]{0,40})(:)?\s*(.*)$');
  static final _stepsRe = RegExp(
    r'^(?:modo de preparação|modo de preparacao|preparação|preparacao|confecção|'
    r'confeccao|modo de fazer|método|metodo|execução|execucao)([^:]{0,30})(:)?\s*(.*)$',
  );
  static final _stopRe = RegExp(
    r'^(partilh|comentar|comentário|comentários|comentarios|etiquetas|tags|'
    r'publicado|enviar|deixe|ver mais|artigos relacionados|posts relacionados|'
    r'receitas relacionadas|relacionad|subscri|seguir|arquivo|permalink|'
    r'link do post|anterior|seguinte)',
  );

  static Recipe? parse(String html, {required String id, String? sourceUrl}) {
    final lines = _toLines(html);

    for (var i = 0; i < lines.length; i++) {
      final ingRest = _headingRest(_ingredientsRe, lines[i]);
      if (ingRest == null) continue;

      var stepsAt = -1;
      for (var j = i + 1; j < lines.length && j <= i + 80; j++) {
        if (_headingRest(_stepsRe, lines[j]) != null) {
          stepsAt = j;
          break;
        }
      }
      if (stepsAt == -1) continue;

      final ingredients = <String>[
        if (ingRest.isNotEmpty) ingRest,
        for (var k = i + 1; k < stepsAt && k < i + 61; k++) lines[k],
      ].map(_stripBullet).where((e) => e.isNotEmpty).toList();

      final steps = <String>[
        if (_headingRest(_stepsRe, lines[stepsAt])!.isNotEmpty)
          _headingRest(_stepsRe, lines[stepsAt])!,
      ];
      for (var k = stepsAt + 1; k < lines.length && steps.length < 30; k++) {
        if (_stopRe.hasMatch(lines[k].toLowerCase())) break;
        steps.add(lines[k]);
      }

      if (ingredients.length < 2 || steps.isEmpty) continue;

      final title = _title(html);
      return Recipe(
        id: id,
        title: title,
        modes: RecipeJsonLdParser.guessModes(
          '$title ${sourceUrl ?? ''} ${ingredients.join(' ')} ${steps.join(' ')}',
        ),
        ingredients: ingredients,
        steps: steps,
        sourceUrl: sourceUrl,
      );
    }
    return null;
  }

  /// Imagem principal da página (`og:image`), se existir.
  static String? imageUrl(String html) {
    final url = _meta(html, 'og:image');
    final clean = url == null ? '' : RecipeJsonLdParser.cleanText(url);
    return clean.isEmpty ? null : clean;
  }

  /// Texto a seguir ao título, ou `null` se a linha não for esse título.
  static String? _headingRest(RegExp re, String line) {
    final lower = line.toLowerCase();
    final m = re.firstMatch(lower);
    if (m == null) return null;
    final rest = m.group(3)!;
    if (m.group(2) == null && rest.isNotEmpty) return null; // frase normal
    return line.substring(line.length - rest.length).trim();
  }

  static String _stripBullet(String s) =>
      s.replaceFirst(RegExp(r'^[-•·*–]\s*'), '').trim();

  static List<String> _toLines(String html) {
    var s = html
        .replaceAll(
          RegExp(r'<(script|style|noscript)[^>]*>.*?</\1>',
              caseSensitive: false, dotAll: true),
          ' ',
        )
        .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), ' ');
    s = s.replaceAllMapped(
      RegExp(
        r'<(br|/?(p|div|li|ul|ol|h[1-6]|tr|table|section|article))\b[^>]*>',
        caseSensitive: false,
      ),
      (_) => '\n',
    );
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    return s
        .split('\n')
        .map(RecipeJsonLdParser.cleanText)
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static String _title(String html) {
    final raw = _meta(html, 'og:title') ??
        RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false, dotAll: true)
            .firstMatch(html)
            ?.group(1) ??
        RegExp(r'<h1[^>]*>(.*?)</h1>', caseSensitive: false, dotAll: true)
            .firstMatch(html)
            ?.group(1) ??
        '';
    final title = RecipeJsonLdParser.cleanText(raw);
    return title.isEmpty ? 'Receita importada' : title;
  }

  static String? _meta(String html, String property) {
    final p = RegExp.escape(property);
    final forward = RegExp(
      '<meta[^>]+property\\s*=\\s*"$p"[^>]*content\\s*=\\s*"([^"]*)"',
      caseSensitive: false,
    );
    final backward = RegExp(
      '<meta[^>]+content\\s*=\\s*"([^"]*)"[^>]*property\\s*=\\s*"$p"',
      caseSensitive: false,
    );
    return (forward.firstMatch(html) ?? backward.firstMatch(html))?.group(1);
  }
}
