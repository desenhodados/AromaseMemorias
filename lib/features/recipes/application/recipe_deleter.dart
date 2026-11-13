import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/photo_storage.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';
import 'recipe_providers.dart';

/// Apagar receitas com possibilidade de desfazer.
///
/// [delete] tira as receitas já, mas deixa as fotos nos ficheiros; se o
/// utilizador carregar em "Desfazer", [restore] volta a pô-las. Quando já não
/// dá para desfazer, [purge] apaga as fotos.
class RecipeDeleter {
  RecipeDeleter(this._repository, this._photos);

  final RecipeRepository _repository;
  final PhotoStorage _photos;

  Future<void> delete(List<Recipe> recipes) =>
      _repository.deleteAll(recipes.map((r) => r.id));

  Future<void> restore(List<Recipe> recipes) => _repository.saveAll(recipes);

  Future<void> purge(List<Recipe> recipes) async {
    for (final r in recipes) {
      await _photos.delete(r.photoPath);
    }
  }
}

final recipeDeleterProvider = Provider<RecipeDeleter>(
  (ref) => RecipeDeleter(
    ref.watch(recipeRepositoryProvider),
    ref.watch(photoStorageProvider),
  ),
);
