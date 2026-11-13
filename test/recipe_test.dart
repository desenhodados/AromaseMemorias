import 'package:flutter_test/flutter_test.dart';
import 'package:aromas_memorias/features/recipes/application/recipe_providers.dart';
import 'package:aromas_memorias/features/recipes/domain/cooking_mode.dart';
import 'package:aromas_memorias/features/recipes/domain/recipe.dart';

void main() {
  const recipe = Recipe(
    id: '1',
    title: 'Frango no forno',
    modes: {CookingMode.traditional, CookingMode.airfryer},
    minutes: 40,
    servings: 4,
    ingredients: ['frango', 'alho'],
  );

  test('Recipe sobrevive a toMap/fromMap', () {
    final copy = Recipe.fromMap(recipe.toMap());
    expect(copy.title, recipe.title);
    expect(copy.modes, recipe.modes);
    expect(copy.ingredients, recipe.ingredients);
  });

  test('RecipeFilter filtra por modo e pesquisa', () {
    expect(const RecipeFilter(mode: CookingMode.bimby).matches(recipe), isFalse);
    expect(const RecipeFilter(mode: CookingMode.airfryer).matches(recipe), isTrue);
    expect(const RecipeFilter(query: 'ALHO').matches(recipe), isTrue);
  });
}
