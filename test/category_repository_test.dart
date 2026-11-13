import 'dart:io';

import 'package:aromas_memorias/features/recipes/data/category_repository.dart';
import 'package:aromas_memorias/features/recipes/domain/recipe_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Box<dynamic> box;
  late HiveCategoryRepository repo;

  setUp(() async {
    Hive.init(Directory.systemTemp.createTempSync('categories_test').path);
    box = await Hive.openBox('categories');
    repo = HiveCategoryRepository(box);
  });

  tearDown(() => Hive.deleteFromDisk());

  test('guarda, ordena por nome e apaga', () async {
    await repo.save(const RecipeCategory(id: 'c2', label: 'Páscoa'));
    await repo.save(const RecipeCategory(id: 'c1', label: 'Aniversários'));

    final all = await repo.watchAll().first;
    expect(all.map((c) => c.label), ['Aniversários', 'Páscoa']);

    await repo.delete('c1');
    expect((await repo.watchAll().first).single.id, 'c2');
  });

  test('ignora entradas inválidas', () async {
    await box.put('x', {'id': 'soups', 'label': 'colide com uma fixa'});
    await box.put('y', 'não é um mapa');
    expect(await repo.watchAll().first, isEmpty);
  });
}
