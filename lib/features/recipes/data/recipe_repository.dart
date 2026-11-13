import 'package:hive/hive.dart';

import '../domain/recipe.dart';

abstract interface class RecipeRepository {
  Stream<List<Recipe>> watchAll();
  Future<void> save(Recipe recipe);

  /// Guarda várias receitas numa só escrita.
  Future<void> saveAll(List<Recipe> recipes);
  Future<void> delete(String id);

  /// Apaga várias receitas numa só escrita.
  Future<void> deleteAll(Iterable<String> ids);
}

class HiveRecipeRepository implements RecipeRepository {
  HiveRecipeRepository(this._box);

  final Box<dynamic> _box;

  List<Recipe> _readAll() {
    final list = _box.values
        .map((e) => Recipe.fromMap(e as Map<dynamic, dynamic>))
        .toList();
    list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  @override
  Stream<List<Recipe>> watchAll() async* {
    yield _readAll();
    await for (final _ in _box.watch()) {
      yield _readAll();
    }
  }

  @override
  Future<void> save(Recipe recipe) => _box.put(recipe.id, recipe.toMap());

  @override
  Future<void> saveAll(List<Recipe> recipes) =>
      _box.putAll({for (final r in recipes) r.id: r.toMap()});

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  Future<void> deleteAll(Iterable<String> ids) => _box.deleteAll(ids);
}
