import '../data/photo_storage.dart';
import '../domain/recipe.dart';

/// Apaga as fotos que já nenhuma receita usa (ex.: receitas apagadas e não
/// repostas, ou rascunhos descartados). Corre ao arrancar a app, quando não há
/// nenhum formulário aberto. Devolve quantas fotos apagou.
Future<int> cleanOrphanPhotos(PhotoStorage storage, Iterable<Recipe> recipes) async {
  final keep = {
    for (final r in recipes)
      if (r.photoPath != null) r.photoPath!,
  };
  var removed = 0;
  for (final name in await storage.listNames()) {
    if (keep.contains(name)) continue;
    await storage.delete(name);
    removed++;
  }
  return removed;
}
