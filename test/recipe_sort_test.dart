import 'package:aromas_memorias/features/recipes/domain/cooking_mode.dart';
import 'package:aromas_memorias/features/recipes/domain/recipe.dart';
import 'package:aromas_memorias/features/recipes/domain/recipe_sort.dart';
import 'package:flutter_test/flutter_test.dart';

Recipe _r(String id, String title, {int minutes = 0, bool favorite = false}) => Recipe(
      id: id,
      title: title,
      modes: const {CookingMode.traditional},
      minutes: minutes,
      isFavorite: favorite,
    );

List<String> _titles(List<Recipe> list) => list.map((r) => r.title).toList();

void main() {
  test('A–Z ignora acentos e maiúsculas', () {
    final sorted = RecipeSort.alphabetical.apply([
      _r('1', 'fruta'),
      _r('2', 'Éclair'),
      _r('3', 'Bolo'),
      _r('4', 'doce'),
    ]);
    expect(_titles(sorted), ['Bolo', 'doce', 'Éclair', 'fruta']);
  });

  test('mais recentes primeiro (pelo instante guardado no id)', () {
    final sorted = RecipeSort.newest.apply([
      _r('100', 'Antiga'),
      _r('300', 'Nova'),
      _r('200', 'Média'),
      _r('abc', 'Sem data'),
    ]);
    expect(_titles(sorted), ['Nova', 'Média', 'Antiga', 'Sem data']);
  });

  test('favoritas primeiro, depois A–Z', () {
    final sorted = RecipeSort.favorites.apply([
      _r('1', 'Bolo'),
      _r('2', 'Zebra', favorite: true),
      _r('3', 'Arroz'),
      _r('4', 'Maçã', favorite: true),
    ]);
    expect(_titles(sorted), ['Maçã', 'Zebra', 'Arroz', 'Bolo']);
  });

  test('mais rápidas primeiro; sem tempo no fim; empates por nome', () {
    final sorted = RecipeSort.quickest.apply([
      _r('1', 'Lenta', minutes: 90),
      _r('2', 'Sem tempo'),
      _r('3', 'Rápida B', minutes: 10),
      _r('4', 'Rápida A', minutes: 10),
      _r('5', 'Média', minutes: 30),
    ]);
    expect(_titles(sorted), ['Rápida A', 'Rápida B', 'Média', 'Lenta', 'Sem tempo']);
  });

  test('apply não altera a lista original', () {
    final original = [_r('1', 'B'), _r('2', 'A')];
    RecipeSort.alphabetical.apply(original);
    expect(_titles(original), ['B', 'A']);
  });

  test('fromName usa A–Z quando o nome é desconhecido', () {
    expect(RecipeSort.fromName('newest'), RecipeSort.newest);
    expect(RecipeSort.fromName('xpto'), RecipeSort.alphabetical);
    expect(RecipeSort.fromName(null), RecipeSort.alphabetical);
  });
}
