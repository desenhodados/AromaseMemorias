import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/app_info.dart';
import '../../../core/storage/hive_storage.dart';
import '../../settings/application/settings_providers.dart';
import '../data/photo_picker.dart';
import '../data/photo_storage.dart';
import '../data/recipe_importer.dart';
import '../data/recipe_repository.dart';
import 'category_providers.dart';
import '../domain/cooking_mode.dart';
import '../domain/ingredient_scaler.dart';
import '../domain/recipe.dart';
import '../domain/recipe_category.dart';
import '../domain/recipe_sort.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) => HiveRecipeRepository(Hive.box(HiveBoxes.recipes)),
);

/// Sobrescrito em `main()` com a pasta real de fotos.
final photoStorageProvider = Provider<PhotoStorage>(
  (ref) => throw UnimplementedError('photoStorageProvider não foi inicializado'),
);

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => ImagePickerPhotoPicker(),
);

final recipeImporterProvider = Provider<RecipeImporter>(
  (ref) => HttpRecipeImporter(
    photos: ref.watch(photoStorageProvider),
    proxyPrefixes: kIsWeb ? AppInfo.webProxyPrefixes : const [],
  ),
);

final recipesProvider = StreamProvider<List<Recipe>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchAll(),
);

final recipeByIdProvider = Provider.family<Recipe?, String>((ref, id) {
  final recipes = ref.watch(recipesProvider).valueOrNull ?? const <Recipe>[];
  return recipes.where((r) => r.id == id).firstOrNull;
});

/// Categorias (fixas e personalizadas) que existem nas receitas, para os filtros.
final availableCategoriesProvider = Provider<List<RecipeCategory>>((ref) {
  final recipes = ref.watch(recipesProvider).valueOrNull ?? const <Recipe>[];
  final used = {
    for (final r in recipes)
      if (r.categoryId != null) r.categoryId!,
  };
  return [
    for (final c in ref.watch(allCategoriesProvider))
      if (used.contains(c.id)) c,
  ];
});

/// Porções escolhidas no detalhe (`null` = as da receita). Só dura enquanto
/// o ecrã da receita estiver aberto; a receita guardada não é alterada.
final servingsOverrideProvider =
    StateProvider.autoDispose.family<int?, String>((ref, recipeId) => null);

/// Ingredientes com as quantidades ajustadas às porções escolhidas.
final scaledIngredientsProvider =
    Provider.autoDispose.family<List<String>, String>((ref, recipeId) {
  final recipe = ref.watch(recipeByIdProvider(recipeId));
  if (recipe == null) return const [];
  final target = ref.watch(servingsOverrideProvider(recipeId)) ?? recipe.servings;
  return scaleIngredients(recipe.ingredients, from: recipe.servings, to: target);
});

@immutable
class RecipeFilter {
  const RecipeFilter({
    this.query = '',
    this.mode,
    this.onlyFavorites = false,
    this.categoryId,
  });

  final String query;
  final CookingMode? mode;
  final bool onlyFavorites;
  final String? categoryId;

  RecipeFilter copyWith({String? query, bool? onlyFavorites}) => RecipeFilter(
        query: query ?? this.query,
        mode: mode,
        onlyFavorites: onlyFavorites ?? this.onlyFavorites,
        categoryId: categoryId,
      );

  bool matches(Recipe r) {
    if (mode != null && !r.modes.contains(mode)) return false;
    if (onlyFavorites && !r.isFavorite) return false;
    if (categoryId != null && r.categoryId != categoryId) return false;
    if (query.isEmpty) return true;
    final text = '${r.title} ${r.ingredients.join(' ')} ${r.notes}'.toLowerCase();
    return text.contains(query.toLowerCase());
  }
}

class RecipeFilterNotifier extends Notifier<RecipeFilter> {
  @override
  RecipeFilter build() => const RecipeFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setMode(CookingMode? mode) => state = RecipeFilter(
        query: state.query,
        mode: mode,
        onlyFavorites: state.onlyFavorites,
        categoryId: state.categoryId,
      );

  void setOnlyFavorites(bool value) =>
      state = state.copyWith(onlyFavorites: value);

  void setCategory(String? categoryId) => state = RecipeFilter(
        query: state.query,
        mode: state.mode,
        onlyFavorites: state.onlyFavorites,
        categoryId: categoryId,
      );
}

final recipeFilterProvider =
    NotifierProvider<RecipeFilterNotifier, RecipeFilter>(
  RecipeFilterNotifier.new,
);

/// Ordem da lista de receitas; a escolha fica guardada.
class RecipeSortNotifier extends Notifier<RecipeSort> {
  @override
  RecipeSort build() =>
      RecipeSort.fromName(ref.read(settingsRepositoryProvider).recipeSortName);

  Future<void> choose(RecipeSort sort) async {
    state = sort;
    await ref.read(settingsRepositoryProvider).setRecipeSortName(sort.name);
  }
}

final recipeSortProvider =
    NotifierProvider<RecipeSortNotifier, RecipeSort>(RecipeSortNotifier.new);

/// Receitas que passam nos filtros, pela ordem escolhida.
final filteredRecipesProvider = Provider<AsyncValue<List<Recipe>>>((ref) {
  final filter = ref.watch(recipeFilterProvider);
  final sort = ref.watch(recipeSortProvider);
  return ref
      .watch(recipesProvider)
      .whenData((list) => sort.apply(list.where(filter.matches).toList()));
});
