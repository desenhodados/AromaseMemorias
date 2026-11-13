import 'package:aromas_memorias/features/recipes/application/recipe_providers.dart';
import 'package:aromas_memorias/features/recipes/domain/cooking_mode.dart';
import 'package:aromas_memorias/features/recipes/domain/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const recipe = Recipe(
    id: '1',
    title: 'Arroz de pato',
    modes: {CookingMode.traditional},
    notes: 'Menos sal da próxima vez.',
  );

  test('as notas sobrevivem a toMap/fromMap', () {
    expect(Recipe.fromMap(recipe.toMap()).notes, 'Menos sal da próxima vez.');
  });

  test('receitas antigas (sem notas) ficam com notas vazias', () {
    final legacy = recipe.toMap()..remove('notes');
    expect(Recipe.fromMap(legacy).notes, isEmpty);
  });

  test('copyWith altera e limpa as notas', () {
    final edited = recipe.copyWith(notes: 'Mais tempo no forno.');
    expect(edited.notes, 'Mais tempo no forno.');
    expect(edited.copyWith(notes: '').notes, isEmpty);
    expect(recipe.copyWith(title: 'Outro').notes, recipe.notes);
  });

  test('a pesquisa também encontra o texto das notas', () {
    expect(const RecipeFilter(query: 'menos sal').matches(recipe), isTrue);
    expect(const RecipeFilter(query: 'canela').matches(recipe), isFalse);
  });
}
