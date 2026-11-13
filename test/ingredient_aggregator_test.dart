import 'package:aromas_memorias/features/shopping/domain/ingredient_aggregator.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _labels(List<List<String>> meals, {Set<String> checked = const {}}) =>
    aggregateIngredients(meals, checked: checked).map((i) => i.name).toList();

void main() {
  group('parseIngredient', () {
    test('separa quantidade, unidade e nome', () {
      final p = parseIngredient('500 g de farinha');
      expect(p.kind, IngredientKind.mass);
      expect(p.quantity, 500);
      expect(p.name, 'farinha');
    });

    test('converte para a unidade-base', () {
      expect(parseIngredient('1,5 kg de batatas').quantity, 1500);
      expect(parseIngredient('2 dl de leite').quantity, 200);
    });

    test('contagem com e sem unidade', () {
      final dente = parseIngredient('2 dentes de alho, picados');
      expect(dente.unit, 'dente');
      expect(dente.name, 'alho');
      expect(parseIngredient('3 ovos').unit, '');
      expect(parseIngredient('1 limão').name, 'limão');
    });

    test('sem quantidade', () {
      expect(parseIngredient('Sal q.b.').kind, IngredientKind.none);
    });
  });

  group('aggregateIngredients', () {
    test('soma o mesmo ingrediente entre refeições', () {
      final labels = _labels([
        ['500 g de farinha', '2 ovos', 'Sal q.b.'],
        ['250 g farinha', '3 ovos', '1 dente de alho'],
      ]);
      expect(
        labels,
        containsAll(['750 g de farinha', '5 ovos', 'Sal q.b.', '1 dente de alho']),
      );
      expect(labels, hasLength(4));
    });

    test('converte g em kg e ml em l', () {
      expect(_labels([['600 g de arroz'], ['600 g de arroz']]), ['1,2 kg de arroz']);
      expect(_labels([['700 ml de leite'], ['500 ml de leite']]), ['1,2 l de leite']);
    });

    test('plural das unidades e dos nomes', () {
      expect(
        _labels([['1 colher de sopa de azeite'], ['2 colheres de sopa de azeite']]),
        ['3 colheres de sopa de azeite'],
      );
      expect(_labels([['1 cebola'], ['2 cebolas']]), ['3 cebolas']);
    });

    test('guarda o "já comprei" pela chave do ingrediente', () {
      final items = aggregateIngredients(
        [['500 g de farinha']],
        checked: {'mass||farinha'},
      );
      expect(items.single.checked, isTrue);
      expect(items.single.count, 1);
    });

    test('conta em quantas refeições aparece', () {
      final items = aggregateIngredients([
        ['2 ovos'],
        ['3 ovos'],
      ]);
      expect(items.single.count, 2);
    });
  });
}
