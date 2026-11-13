import '../data/photo_storage.dart';
import '../domain/recipe.dart';

/// Rascunho de uma variação de [recipe]: cópia com novo id, título
/// "… (cópia)" e uma cópia própria da foto (apagar uma receita não afeta a
/// outra). Não guarda nada: o rascunho abre-se no formulário para editar.
Future<Recipe> duplicateRecipeDraft(Recipe recipe, PhotoStorage photos) async {
  final id = DateTime.now().microsecondsSinceEpoch.toString();
  final photo = recipe.photoPath;
  return Recipe(
    id: id,
    title: '${recipe.title} (cópia)',
    modes: {...recipe.modes},
    minutes: recipe.minutes,
    servings: recipe.servings,
    ingredients: [...recipe.ingredients],
    steps: [...recipe.steps],
    sourceUrl: recipe.sourceUrl,
    categoryId: recipe.categoryId,
    notes: recipe.notes,
    photoPath: photo == null ? null : await photos.duplicate(photo, recipeId: id),
  );
}
