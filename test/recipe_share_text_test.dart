import 'package:aromas_memorias/features/recipes/domain/cooking_mode.dart';
import 'package:aromas_memorias/features/recipes/domain/recipe.dart';
import 'package:aromas_memorias/features/recipes/domain/recipe_share_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receita completa: cabeçalho, ingredientes, passos e fonte', () {
    const recipe = Recipe(
      id: '1',
      title: 'Bolo de cenoura',
      modes: {CookingMode.traditional, CookingMode.airfryer},
      minutes: 45,
      servings: 4,
      steps: ['Bata os ovos.', 'Leve ao forno.'],
      sourceUrl: 'https://x.pt/bolo',
    );

    final text = recipeShareText(
      recipe,
      ingredients: ['6 ovos', '300 g de açúcar'],
      servings: 6,
      categoryLabel: 'Sobremesas',
    );

    final header = text.substring(0, text.indexOf('*Ingredientes*'));
    expect(header, contains('*Bolo de cenoura*'));
    expect(header, contains('45 min'));
    expect(header, contains('6 porções'));
    expect(header, contains('Sobremesas · Tradicional / Airfryer'));

    expect(
      text.substring(text.indexOf('*Ingredientes*')),
      '*Ingredientes*\n'
      '• 6 ovos\n'
      '• 300 g de açúcar\n'
      '\n'
      '*Preparação*\n'
      '1. Bata os ovos.\n'
      '2. Leve ao forno.\n'
      '\n'
      'Fonte: https://x.pt/bolo',
    );
  });

  test('receita mínima: só título e porções', () {
    const recipe = Recipe(
      id: '1',
      title: 'Chá',
      modes: {},
    );

    final text = recipeShareText(recipe, ingredients: [], servings: 1);

    expect(text.split('\n'), hasLength(2));
    expect(text, contains('*Chá*'));
    expect(text, contains('1 porção'));
    expect(text, isNot(contains('porções')));
    expect(text, isNot(contains('Ingredientes')));
    expect(text, isNot(contains('Preparação')));
  });
}
