import 'package:aromas_memorias/features/recipes/data/recipe_html_parser.dart';
import 'package:aromas_memorias/features/recipes/domain/cooking_mode.dart';
import 'package:flutter_test/flutter_test.dart';

const _blog = '''
<html><head>
<meta property="og:title" content="Folar Transmontano na Bimby">
<meta property="og:image" content="https://x.pt/folar.jpg">
</head><body>
<div class="menu">Receitas</div>
<div class="post"><h3>Folar</h3>
<p>Ingredientes:<br>500 g de farinha<br>3 ovos<br>100 g de açúcar</p>
<p>Preparação:<br>Misture tudo.<br>Leve ao forno 40 min.</p>
<p>Partilhar</p></div>
</body></html>
''';

void main() {
  test('extrai receita de um blog sem dados estruturados', () {
    final r = RecipeHtmlParser.parse(_blog, id: '1', sourceUrl: 'https://x.pt/folar');
    expect(r, isNotNull);
    expect(r!.title, 'Folar Transmontano na Bimby');
    expect(r.ingredients, ['500 g de farinha', '3 ovos', '100 g de açúcar']);
    expect(r.steps, ['Misture tudo.', 'Leve ao forno 40 min.']);
    expect(r.modes, {CookingMode.bimby});
    expect(RecipeHtmlParser.imageUrl(_blog), 'https://x.pt/folar.jpg');
  });

  test('aceita título e primeira linha juntos', () {
    const html = '<p>Ingredientes: 2 ovos<br>1 chávena de leite</p>'
        '<p>Modo de preparação: Bata tudo.</p>';
    final r = RecipeHtmlParser.parse(html, id: '1');
    expect(r!.ingredients, ['2 ovos', '1 chávena de leite']);
    expect(r.steps, ['Bata tudo.']);
  });

  test('devolve null quando não há ingredientes e preparação', () {
    expect(RecipeHtmlParser.parse('<p>Olá mundo</p>', id: '1'), isNull);
  });
}
