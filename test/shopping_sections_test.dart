import 'package:aromas_memorias/features/shopping/domain/ingredient_aggregator.dart';
import 'package:aromas_memorias/features/shopping/domain/supermarket_section.dart';
import 'package:flutter_test/flutter_test.dart';

SupermarketSection _s(String name, {String unit = ''}) =>
    SupermarketSection.classify(name, unit: unit);

void main() {
  group('classify', () {
    test('frutas e legumes', () {
      expect(_s('cebola'), SupermarketSection.produce);
      expect(_s('cebolas'), SupermarketSection.produce);
      expect(_s('limões'), SupermarketSection.produce);
      expect(_s('coentros'), SupermarketSection.produce);
      expect(_s('batata-doce'), SupermarketSection.produce);
      expect(_s('pimento'), SupermarketSection.produce);
      expect(_s('sumo de limão'), SupermarketSection.produce);
    });

    test('talho, peixaria e charcutaria', () {
      expect(_s('peito de frango'), SupermarketSection.meat);
      expect(_s('carne picada'), SupermarketSection.meat);
      expect(_s('filetes de pescada'), SupermarketSection.fish);
      expect(_s('bacalhau'), SupermarketSection.fish);
      expect(_s('queijo ralado'), SupermarketSection.deli);
      expect(_s('chouriço'), SupermarketSection.deli);
      expect(_s('fiambre de peru'), SupermarketSection.deli);
    });

    test('laticínios, padaria e mercearia', () {
      expect(_s('leite'), SupermarketSection.dairy);
      expect(_s('ovos'), SupermarketSection.dairy);
      expect(_s('manteiga'), SupermarketSection.dairy);
      expect(_s('pão'), SupermarketSection.bakery);
      expect(_s('pão ralado'), SupermarketSection.pantry);
      expect(_s('arroz'), SupermarketSection.pantry);
      expect(_s('azeite'), SupermarketSection.pantry);
      expect(_s('leite de coco'), SupermarketSection.pantry);
      expect(_s('uvas passas'), SupermarketSection.pantry);
    });

    test('temperos, congelados e bebidas', () {
      expect(_s('sal'), SupermarketSection.spices);
      expect(_s('pimenta'), SupermarketSection.spices);
      expect(_s('folhas de louro'), SupermarketSection.spices);
      expect(_s('ervilhas congeladas'), SupermarketSection.frozen);
      expect(_s('massa folhada'), SupermarketSection.frozen);
      expect(_s('vinho branco'), SupermarketSection.drinks);
      expect(_s('vinagre de vinho'), SupermarketSection.pantry);
    });

    test('conservas e caldos vão para a mercearia', () {
      expect(_s('atum'), SupermarketSection.fish);
      expect(_s('atum', unit: 'lata'), SupermarketSection.pantry);
      expect(_s('caldo de galinha'), SupermarketSection.pantry);
    });

    test('desconhecido fica em Outros', () {
      expect(_s('xpto'), SupermarketSection.other);
    });
  });

  group('aggregateIngredients', () {
    test('cada item leva a sua secção', () {
      final items = aggregateIngredients([
        ['2 cebolas', '500 g de frango', 'Sal q.b.'],
      ]);
      final bySection = {for (final i in items) i.name: i.section};
      expect(bySection['2 cebolas'], SupermarketSection.produce);
      expect(bySection['500 g de frango'], SupermarketSection.meat);
      expect(bySection['Sal q.b.'], SupermarketSection.spices);
    });

    test('a água da torneira não entra na lista', () {
      final items = aggregateIngredients([
        ['200 ml de água', '1 l de água a ferver', '1 colher de água de rosas'],
      ]);
      expect(items, hasLength(1));
      expect(items.single.name, contains('rosas'));
    });

    test('a secção escolhida pelo utilizador tem prioridade', () {
      final auto = aggregateIngredients([['500 g de frango']]).single;
      expect(auto.section, SupermarketSection.meat);
      expect(auto.sectionIsCustom, isFalse);

      final custom = aggregateIngredients(
        [['500 g de frango']],
        overrides: {auto.ingredientKey: SupermarketSection.frozen},
      ).single;
      expect(custom.section, SupermarketSection.frozen);
      expect(custom.sectionIsCustom, isTrue);
    });
  });
}
