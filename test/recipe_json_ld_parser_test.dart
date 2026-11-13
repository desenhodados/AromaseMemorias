import 'package:aromas_memorias/features/recipes/data/recipe_json_ld_parser.dart';
import 'package:aromas_memorias/features/recipes/domain/cooking_mode.dart';
import 'package:flutter_test/flutter_test.dart';

const _html = '''
<html><head>
<script type="application/ld+json">
{"@context":"https://schema.org","@graph":[
 {"@type":"WebSite","name":"Site"},
 {"@type":"Recipe","name":"Frango na Airfryer &amp; batata","totalTime":"PT1H30M",
  "recipeYield":"4 doses","recipeIngredient":["1 frango","2 dentes de alho"],
  "recipeInstructions":[
    {"@type":"HowToStep","text":"Tempere o frango."},
    {"@type":"HowToSection","itemListElement":[
      {"@type":"HowToStep","text":"Leve à airfryer 30 min."}]}]}]}
</script></head></html>
''';

void main() {
  test('extrai receita de JSON-LD dentro de @graph', () {
    final r = RecipeJsonLdParser.parse(_html, id: '1', sourceUrl: 'https://x.pt/r');
    expect(r, isNotNull);
    expect(r!.title, 'Frango na Airfryer & batata');
    expect(r.minutes, 90);
    expect(r.servings, 4);
    expect(r.ingredients, hasLength(2));
    expect(r.steps, hasLength(2));
    expect(r.modes, {CookingMode.airfryer});
    expect(r.sourceUrl, 'https://x.pt/r');
  });

  test('extrai a imagem da receita', () {
    const html = '<script type="application/ld+json">'
        '{"@type":"Recipe","name":"X","image":[{"url":"https://x.pt/a.jpg"}]}'
        '</script>';
    expect(RecipeJsonLdParser.imageUrl(html), 'https://x.pt/a.jpg');
    expect(RecipeJsonLdParser.imageUrl('<html></html>'), isNull);
  });

  test('devolve null quando não há receita', () {
    expect(RecipeJsonLdParser.parse('<html></html>', id: '1'), isNull);
  });
}
