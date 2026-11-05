import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_storage.dart';
import '../data/photo_picker.dart';
import '../data/photo_storage.dart';
import '../data/recipe_importer.dart';
import '../data/recipe_repository.dart';
import '../domain/cooking_mode.dart';
import '../domain/recipe.dart';

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
  (ref) => HttpRecipeImporter(photos: ref.watch(photoStorageProvider)),
);

final recipesProvider = StreamProvider<List<Recipe>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchAll(),
);

final recipeByIdProvider = Provider.family<Recipe?, String>((ref, id) {
  final recipes = ref.watch(recipesProvider).valueOrNull ?? const <Recipe>[];
  return recipes.where((r) => r.id == id).firstOrNull;
});

@immutable
class RecipeFilter {
  const RecipeFilter({this.query = '', this.mode, this.onlyFavorites = false});

  final String query;
  final CookingMode? mode;
  final bool onlyFavorites;

  RecipeFilter copyWith({String? query, bool? onlyFavorites}) => RecipeFilter(
        query: query ?? this.query,
        mode: mode,
        onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      );

  bool matches(Recipe r) {
    if (mode != null && !r.modes.contains(mode)) return false;
    if (onlyFavorites && !r.isFavorite) return false;
    if (query.isEmpty) return true;
    final text = '${r.title} ${r.ingredients.join(' ')}'.toLowerCase();
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
      );

  void setOnlyFavorites(bool value) =>
      state = state.copyWith(onlyFavorites: value);
}

final recipeFilterProvider =
    NotifierProvider<RecipeFilterNotifier, RecipeFilter>(
  RecipeFilterNotifier.new,
);

final filteredRecipesProvider = Provider<AsyncValue<List<Recipe>>>((ref) {
  final filter = ref.watch(recipeFilterProvider);
  return ref
      .watch(recipesProvider)
      .whenData((list) => list.where(filter.matches).toList());
});
