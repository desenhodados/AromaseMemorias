import 'dart:io';
import 'dart:typed_data';

import 'package:aromas_memorias/features/backup/data/backup_repository.dart';
import 'package:aromas_memorias/features/backup/domain/backup.dart';
import 'package:aromas_memorias/features/recipes/data/photo_storage.dart';
import 'package:aromas_memorias/features/recipes/domain/cooking_mode.dart';
import 'package:aromas_memorias/features/recipes/domain/recipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

Recipe _recipe(String id, String title) => Recipe(
      id: id,
      title: title,
      modes: const {CookingMode.traditional},
      ingredients: const ['sal'],
    );

void main() {
  late Box<dynamic> recipes;
  late Box<dynamic> plan;
  late Box<dynamic> checked;
  late Box<dynamic> overrides;
  late Box<dynamic> categories;
  late HiveBackupRepository repo;
  late LocalPhotoStorage photos;

  setUp(() async {
    Hive.init(Directory.systemTemp.createTempSync('backup_test').path);
    recipes = await Hive.openBox('recipes');
    plan = await Hive.openBox('plan');
    checked = await Hive.openBox('checked');
    overrides = await Hive.openBox('overrides');
    categories = await Hive.openBox('categories');
    photos = LocalPhotoStorage(Directory.systemTemp.createTempSync('photos'));
    repo = HiveBackupRepository(
      recipes: recipes,
      plan: plan,
      checked: checked,
      sectionOverrides: overrides,
      categories: categories,
      photos: photos,
    );
  });

  tearDown(() => Hive.deleteFromDisk());

  test('exportar e importar repõe os dados', () async {
    await recipes.put('1', _recipe('1', 'Bacalhau').toMap());
    await plan.put('2026-11-01|lunch', '1');
    await checked.put('sal', true);
    final json = await repo.exportJson();

    await Future.wait([recipes.clear(), plan.clear(), checked.clear()]);
    final summary = await repo.restore(json, replace: false);

    expect(summary.recipes, 1);
    expect(summary.plannedMeals, 1);
    expect(Recipe.fromMap(recipes.get('1') as Map).title, 'Bacalhau');
    expect(plan.get('2026-11-01|lunch'), '1');
    expect(checked.get('sal'), true);
  });

  test('substituir apaga o que não está no backup', () async {
    await recipes.put('1', _recipe('1', 'Bacalhau').toMap());
    final json = await repo.exportJson();
    await recipes.put('2', _recipe('2', 'Arroz').toMap());

    await repo.restore(json, replace: true);

    expect(recipes.keys, ['1']);
  });

  test('ficheiro inválido não altera nada', () async {
    await recipes.put('1', _recipe('1', 'Bacalhau').toMap());

    expect(
      () => repo.restore('{"foo": 1}', replace: true),
      throwsA(isA<BackupException>()),
    );
    expect(recipes.length, 1);
  });

  test('as fotos viajam no backup', () async {
    final name = await photos.saveBytes(
      Uint8List.fromList([9, 8, 7]),
      recipeId: '1',
    );
    await recipes.put('1', _recipe('1', 'Bacalhau').copyWith(photoPath: name).toMap());
    final json = await repo.exportJson();

    await Future.wait([recipes.clear(), photos.clear()]);
    await repo.restore(json, replace: false);

    expect(Recipe.fromMap(recipes.get('1') as Map).photoPath, name);
    expect(await photos.readBytes(name), [9, 8, 7]);
  });

  test('o planeamento com porções viaja no backup', () async {
    await plan.put('2026-11-01|lunch', {'recipeId': '1', 'servings': 6});
    await plan.put('2026-11-01|dinner', '2');
    final json = await repo.exportJson();

    await plan.clear();
    await repo.restore(json, replace: false);

    expect((plan.get('2026-11-01|lunch') as Map)['servings'], 6);
    expect(plan.get('2026-11-01|dinner'), '2');
  });

  test('as secções escolhidas viajam no backup (ignorando as inválidas)', () async {
    await overrides.put('atum', 'pantry');
    final json = await repo.exportJson();

    await overrides.clear();
    await repo.restore(
      json.replaceFirst('"atum": "pantry"', '"atum": "pantry", "xpto": "nada"'),
      replace: false,
    );

    expect(overrides.get('atum'), 'pantry');
    expect(overrides.containsKey('xpto'), isFalse);
  });

  test('as categorias personalizadas viajam no backup', () async {
    await categories.put('c1', {'id': 'c1', 'label': 'Festas', 'iconKey': 'celebration'});
    await recipes.put('1', _recipe('1', 'Bolo').copyWith(categoryId: 'c1').toMap());
    final json = await repo.exportJson();

    await Future.wait([categories.clear(), recipes.clear()]);
    await repo.restore(json, replace: false);

    expect((categories.get('c1') as Map)['label'], 'Festas');
    expect(Recipe.fromMap(recipes.get('1') as Map).categoryId, 'c1');
  });
}
