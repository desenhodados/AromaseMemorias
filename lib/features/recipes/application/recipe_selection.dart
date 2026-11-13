import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recipe.dart';
import 'recipe_deleter.dart';
import 'recipe_providers.dart';

/// Receitas selecionadas na lista (modo de seleção). Vazio = modo normal.
class RecipeSelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) {
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    state = next;
  }

  void selectAll(Iterable<String> ids) => state = {...ids};

  void clear() => state = const {};

  /// Define a categoria de todas as receitas selecionadas (`null` = sem
  /// categoria), numa única escrita. Limpa a seleção e devolve quantas mudou.
  Future<int> assignCategory(String? categoryId) async {
    final recipes = ref.read(recipesProvider).valueOrNull ?? const <Recipe>[];
    final changed = [
      for (final r in recipes)
        if (state.contains(r.id))
          r.copyWith(categoryId: categoryId, clearCategory: categoryId == null),
    ];
    await ref.read(recipeRepositoryProvider).saveAll(changed);
    state = const {};
    return changed.length;
  }

  /// Marca (ou tira) como favoritas todas as receitas selecionadas, numa só
  /// escrita. Limpa a seleção e devolve quantas receitas estavam selecionadas.
  Future<int> setFavorite(bool value) async {
    final recipes = ref.read(recipesProvider).valueOrNull ?? const <Recipe>[];
    final selected = [
      for (final r in recipes)
        if (state.contains(r.id)) r,
    ];
    await ref.read(recipeRepositoryProvider).saveAll([
      for (final r in selected)
        if (r.isFavorite != value) r.copyWith(isFavorite: value),
    ]);
    state = const {};
    return selected.length;
  }

  /// Apaga as receitas selecionadas e limpa a seleção. Devolve as receitas
  /// apagadas (para o "Desfazer"); as fotos só se apagam com `RecipeDeleter.purge`.
  Future<List<Recipe>> deleteSelected() async {
    final recipes = ref.read(recipesProvider).valueOrNull ?? const <Recipe>[];
    final removed = [
      for (final r in recipes)
        if (state.contains(r.id)) r,
    ];
    await ref.read(recipeDeleterProvider).delete(removed);
    state = const {};
    return removed;
  }
}

final recipeSelectionProvider =
    NotifierProvider<RecipeSelectionNotifier, Set<String>>(
  RecipeSelectionNotifier.new,
);
