import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_storage.dart';
import '../../planner/application/plan_providers.dart';
import '../../planner/domain/meal_type.dart';
import '../../recipes/application/recipe_providers.dart';
import '../../recipes/domain/recipe.dart';
import '../data/shopping_repository.dart';
import '../domain/shopping_item.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => HiveShoppingRepository(Hive.box(HiveBoxes.shoppingChecked)),
);

final checkedItemsProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(shoppingRepositoryProvider).watchChecked(),
);

/// Ingredientes das refeições planeadas para os próximos 7 dias.
final shoppingItemsProvider = Provider<List<ShoppingItem>>((ref) {
  final plan = ref.watch(planProvider).valueOrNull ?? const <String, String>{};
  final recipes = ref.watch(recipesProvider).valueOrNull ?? const <Recipe>[];
  final checked =
      ref.watch(checkedItemsProvider).valueOrNull ?? const <String>{};

  final byId = {for (final r in recipes) r.id: r};
  final today = DateTime.now();
  final counts = <String, int>{};

  for (var i = 0; i < 7; i++) {
    final day = today.add(Duration(days: i));
    for (final meal in MealType.values) {
      final recipe = byId[plan[slotKey(day, meal)]];
      if (recipe == null) continue;
      for (final ingredient in recipe.ingredients) {
        counts.update(ingredient, (v) => v + 1, ifAbsent: () => 1);
      }
    }
  }

  final names = counts.keys.toList()..sort();
  return [
    for (final n in names)
      ShoppingItem(name: n, count: counts[n]!, checked: checked.contains(n)),
  ];
});
