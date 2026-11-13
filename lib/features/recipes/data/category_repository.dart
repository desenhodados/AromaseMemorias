import 'package:hive/hive.dart';

import '../../../core/text_utils.dart';
import '../domain/recipe_category.dart';

/// Categorias criadas pelo utilizador (as fixas estão em [RecipeCategory.builtIn]).
abstract interface class CategoryRepository {
  Stream<List<RecipeCategory>> watchAll();
  Future<void> save(RecipeCategory category);
  Future<void> delete(String id);
}

class HiveCategoryRepository implements CategoryRepository {
  HiveCategoryRepository(this._box);

  final Box<dynamic> _box;

  List<RecipeCategory> _readAll() {
    final list = <RecipeCategory>[];
    for (final value in _box.values) {
      final category = value is Map ? RecipeCategory.fromMap(value) : null;
      if (category != null) list.add(category);
    }
    list.sort((a, b) => foldAccents(a.label).compareTo(foldAccents(b.label)));
    return list;
  }

  @override
  Stream<List<RecipeCategory>> watchAll() async* {
    yield _readAll();
    await for (final _ in _box.watch()) {
      yield _readAll();
    }
  }

  @override
  Future<void> save(RecipeCategory category) =>
      _box.put(category.id, category.toMap());

  @override
  Future<void> delete(String id) => _box.delete(id);
}
