import 'dart:io';
import 'dart:typed_data';

import 'package:aromas_memorias/features/recipes/application/recipe_deleter.dart';
import 'package:aromas_memorias/features/recipes/data/photo_storage.dart';
import 'package:aromas_memorias/features/recipes/data/recipe_repository.dart';
import 'package:aromas_memorias/features/recipes/domain/cooking_mode.dart';
import 'package:aromas_memorias/features/recipes/domain/recipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late HiveRecipeRepository repo;
  late LocalPhotoStorage photos;
  late RecipeDeleter deleter;
  late Recipe recipe;

  setUp(() async {
    Hive.init(Directory.systemTemp.createTempSync('deleter_test').path);
    repo = HiveRecipeRepository(await Hive.openBox('recipes'));
    photos = LocalPhotoStorage(Directory.systemTemp.createTempSync('deleter_photos'));
    deleter = RecipeDeleter(repo, photos);

    final photo = await photos.saveBytes(Uint8List(1), recipeId: '1');
    recipe = Recipe(
      id: '1',
      title: 'Bolo',
      modes: const {CookingMode.traditional},
      photoPath: photo,
    );
    await repo.save(recipe);
  });

  tearDown(() => Hive.deleteFromDisk());

  test('delete tira a receita mas deixa a foto (para se poder desfazer)', () async {
    await deleter.delete([recipe]);

    expect(await repo.watchAll().first, isEmpty);
    expect(photos.exists(recipe.photoPath!), isTrue);
  });

  test('restore repõe a receita com a foto', () async {
    await deleter.delete([recipe]);
    await deleter.restore([recipe]);

    final all = await repo.watchAll().first;
    expect(all.single.id, '1');
    expect(photos.exists(all.single.photoPath!), isTrue);
  });

  test('purge apaga as fotos quando já não dá para desfazer', () async {
    await deleter.delete([recipe]);
    await deleter.purge([recipe]);

    expect(photos.exists(recipe.photoPath!), isFalse);
  });
}
