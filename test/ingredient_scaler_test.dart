import 'package:aromas_memorias/features/recipes/domain/ingredient_scaler.dart';
import 'package:flutter_test/flutter_test.dart';

String _x(String line, double factor) => scaleIngredient(line, factor);

void main() {
  test('escala quantidades simples', () {
    expect(_x('500 g de farinha', 1.5), '750 g de farinha');
    expect(_x('2 ovos', 1.5), '3 ovos');
    expect(_x('250g de açúcar', 0.5), '125g de açúcar');
  });

  test('usa frações habituais', () {
    expect(_x('1 dente de alho', 1.5), '1 ½ dente de alho');
    expect(_x('0,5 l de leite', 1.5), '¾ l de leite');
    expect(_x('1/2 chávena de leite', 3), '1 ½ chávena de leite');
    expect(_x('1 1/2 colher de sopa', 2), '3 colher de sopa');
    expect(_x('½ cebola', 2), '1 cebola');
  });

  test('decimais e milhares', () {
    expect(_x('1,5 kg de batatas', 2), '3 kg de batatas');
    expect(_x('1.000 g de farinha', 2), '2000 g de farinha');
  });

  test('intervalos e parênteses', () {
    expect(_x('2 a 3 colheres de azeite', 2), '4 a 6 colheres de azeite');
    expect(_x('2-3 dentes de alho', 2), '4-6 dentes de alho');
    expect(_x('1 chávena (250 ml) de leite', 2), '2 chávena (500 ml) de leite');
  });

  test('não mexe no que não é quantidade', () {
    expect(_x('Sal q.b.', 2), 'Sal q.b.');
    expect(_x('100% cacau', 2), '100% cacau');
    expect(_x('1. farinha', 2), '1. farinha');
  });

  test('scaleIngredients usa a razão entre porções', () {
    expect(
      scaleIngredients(['400 g de arroz', 'Sal q.b.'], from: 4, to: 6),
      ['600 g de arroz', 'Sal q.b.'],
    );
    expect(scaleIngredients(['400 g de arroz'], from: 4, to: 4), ['400 g de arroz']);
    expect(scaleIngredients(['400 g de arroz'], from: 0, to: 6), ['400 g de arroz']);
  });
}
