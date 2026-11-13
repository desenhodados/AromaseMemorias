import '../../../core/text_utils.dart';
import 'recipe.dart';

/// Ordem da lista de receitas.
enum RecipeSort {
  alphabetical('A–Z'),
  newest('Mais recentes'),
  favorites('Favoritas primeiro'),
  quickest('Mais rápidas primeiro');

  const RecipeSort(this.label);

  final String label;

  /// Lê o nome guardado; se for desconhecido, usa A–Z.
  static RecipeSort fromName(String? name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return alphabetical;
  }

  /// Devolve uma cópia ordenada (a lista recebida não é alterada). Em empate,
  /// desempata por ordem alfabética, para a ordem ser sempre a mesma.
  List<Recipe> apply(List<Recipe> recipes) {
    int byTitle(Recipe a, Recipe b) =>
        foldAccents(a.title).compareTo(foldAccents(b.title));

    final int Function(Recipe, Recipe) compare = switch (this) {
      RecipeSort.alphabetical => byTitle,
      RecipeSort.newest => (a, b) {
          final c = b.createdMicros.compareTo(a.createdMicros);
          return c != 0 ? c : byTitle(a, b);
        },
      RecipeSort.favorites => (a, b) {
          if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
          return byTitle(a, b);
        },
      RecipeSort.quickest => (a, b) {
          // Sem tempo indicado (0) fica no fim.
          final ta = a.minutes > 0 ? a.minutes : 1 << 30;
          final tb = b.minutes > 0 ? b.minutes : 1 << 30;
          final c = ta.compareTo(tb);
          return c != 0 ? c : byTitle(a, b);
        },
    };
    return [...recipes]..sort(compare);
  }
}
