import 'package:aromas_memorias/features/recipes/application/recipe_providers.dart';
import 'package:aromas_memorias/features/recipes/domain/cooking_mode.dart';
import 'package:aromas_memorias/features/recipes/domain/recipe.dart';
import 'package:aromas_memorias/features/recipes/domain/recipe_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guess reconhece a categoria pelo título', () {
    expect(RecipeCategory.guess('Sopa de legumes'), RecipeCategory.soups);
    expect(RecipeCategory.guess('Bolo de cenoura'), RecipeCategory.desserts);
    expect(RecipeCategory.guess('Frango assado'), RecipeCategory.meat);
    expect(RecipeCategory.guess('Bacalhau com natas'), RecipeCategory.fish);
    expect(RecipeCategory.guess('Arroz doce'), RecipeCategory.desserts);
    expect(RecipeCategory.guess('Esparguete à bolonhesa'), RecipeCategory.pastaRice);
    expect(RecipeCategory.guess('Salada de atum'), RecipeCategory.salads);
    expect(RecipeCategory.guess('Pão-de-ló'), RecipeCategory.desserts);
    expect(RecipeCategory.guess('Batata-doce assada'), isNull);
  });

  group('categorias personalizadas', () {
    test('distinguem-se das fixas', () {
      expect(RecipeCategory.soups.isCustom, isFalse);
      expect(const RecipeCategory(id: 'c1', label: 'Festas').isCustom, isTrue);
    });

    test('toMap/fromMap preserva nome e ícone', () {
      const festas = RecipeCategory(id: 'c1', label: 'Festas', iconKey: 'celebration');
      final copy = RecipeCategory.fromMap(festas.toMap());
      expect(copy, festas);
      expect(copy!.label, 'Festas');
      expect(copy.iconKey, 'celebration');
    });

    test('fromMap rejeita dados inválidos e ids das fixas', () {
      expect(RecipeCategory.fromMap({'id': 'soups', 'label': 'X'}), isNull);
      expect(RecipeCategory.fromMap({'id': 'c1', 'label': '  '}), isNull);
      expect(RecipeCategory.fromMap({'label': 'Sem id'}), isNull);
    });

    test('takenLabels ignora acentos e maiúsculas', () {
      const festas = RecipeCategory(id: 'c1', label: 'Receitas de Páscoa');
      final taken = RecipeCategory.takenLabels([...RecipeCategory.builtIn, festas]);
      expect(taken, contains('receitas de pascoa'));
      expect(taken, contains('sobremesas'));
      expect(
        RecipeCategory.takenLabels([festas], exceptId: 'c1'),
        isEmpty,
      );
    });
  });

  test('a categoria (fixa ou personalizada) sobrevive a toMap/fromMap', () {
    for (final id in ['desserts', 'c123']) {
      final recipe = Recipe(
        id: '1',
        title: 'Pudim',
        modes: const {CookingMode.traditional},
        categoryId: id,
      );
      expect(Recipe.fromMap(recipe.toMap()).categoryId, id);
    }
  });

  test('receitas antigas (sem categoria) ficam sem categoria', () {
    const recipe = Recipe(id: '1', title: 'Pudim', modes: {CookingMode.traditional});
    final legacy = recipe.toMap()..remove('category');
    expect(Recipe.fromMap(legacy).categoryId, isNull);
  });

  test('copyWith altera e limpa a categoria', () {
    const recipe = Recipe(id: '1', title: 'Pudim', modes: {CookingMode.traditional});
    final withCat = recipe.copyWith(categoryId: 'desserts');
    expect(withCat.categoryId, 'desserts');
    expect(withCat.copyWith(clearCategory: true).categoryId, isNull);
  });

  test('o filtro respeita a categoria', () {
    const recipe = Recipe(
      id: '1',
      title: 'Pudim',
      modes: {CookingMode.traditional},
      categoryId: 'c123',
    );
    expect(const RecipeFilter(categoryId: 'c123').matches(recipe), isTrue);
    expect(const RecipeFilter(categoryId: 'soups').matches(recipe), isFalse);
  });
}
