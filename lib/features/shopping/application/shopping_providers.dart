import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_storage.dart';
import '../../planner/application/plan_providers.dart';
import '../../planner/domain/meal_type.dart';
import '../../planner/domain/plan_entry.dart';
import '../../recipes/application/recipe_providers.dart';
import '../../recipes/domain/ingredient_scaler.dart';
import '../../recipes/domain/recipe.dart';
import '../data/section_overrides_repository.dart';
import '../data/shopping_repository.dart';
import '../domain/ingredient_aggregator.dart';
import '../domain/shopping_item.dart';
import '../domain/supermarket_section.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => HiveShoppingRepository(Hive.box(HiveBoxes.shoppingChecked)),
);

final sectionOverridesRepositoryProvider = Provider<SectionOverridesRepository>(
  (ref) => HiveSectionOverridesRepository(Hive.box(HiveBoxes.sectionOverrides)),
);

final sectionOverridesProvider = StreamProvider<Map<String, SupermarketSection>>(
  (ref) => ref.watch(sectionOverridesRepositoryProvider).watchAll(),
);

final checkedItemsProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(shoppingRepositoryProvider).watchChecked(),
);

/// Ingredientes das refeições planeadas para os próximos 7 dias, ajustados às
/// porções de cada refeição e com as quantidades somadas.
final shoppingItemsProvider = Provider<List<ShoppingItem>>((ref) {
  final plan = ref.watch(planProvider).valueOrNull ?? const <String, PlanEntry>{};
  final recipes = ref.watch(recipesProvider).valueOrNull ?? const <Recipe>[];
  final checked =
      ref.watch(checkedItemsProvider).valueOrNull ?? const <String>{};
  final overrides = ref.watch(sectionOverridesProvider).valueOrNull ??
      const <String, SupermarketSection>{};

  final byId = {for (final r in recipes) r.id: r};
  final today = DateTime.now();
  final meals = <List<String>>[];

  for (var i = 0; i < 7; i++) {
    final day = today.add(Duration(days: i));
    for (final meal in MealType.values) {
      final entry = plan[slotKey(day, meal)];
      final recipe = entry == null ? null : byId[entry.recipeId];
      if (entry == null || recipe == null) continue;
      meals.add(
        scaleIngredients(
          recipe.ingredients,
          from: recipe.servings,
          to: entry.servings ?? recipe.servings,
        ),
      );
    }
  }
  return aggregateIngredients(meals, checked: checked, overrides: overrides);
});
