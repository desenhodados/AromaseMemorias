import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_storage.dart';
import '../data/category_repository.dart';
import '../domain/recipe_category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => HiveCategoryRepository(Hive.box(HiveBoxes.categories)),
);

/// Só as categorias criadas pelo utilizador.
final customCategoriesProvider = StreamProvider<List<RecipeCategory>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

/// Fixas e personalizadas (as fixas primeiro).
final allCategoriesProvider = Provider<List<RecipeCategory>>((ref) {
  final custom = ref.watch(customCategoriesProvider).valueOrNull ?? const [];
  return [...RecipeCategory.builtIn, ...custom];
});

/// A categoria com este id, ou `null` (sem categoria ou categoria apagada).
final categoryByIdProvider =
    Provider.family<RecipeCategory?, String?>((ref, id) {
  if (id == null) return null;
  for (final c in ref.watch(allCategoriesProvider)) {
    if (c.id == id) return c;
  }
  return null;
});
