import 'dart:io';
import 'dart:typed_data';

import 'package:aromas_memorias/features/recipes/application/photo_cleanup.dart';
import 'package:aromas_memorias/features/recipes/data/photo_storage.dart';
import 'package:aromas_memorias/features/recipes/domain/cooking_mode.dart';
import 'package:aromas_memorias/features/recipes/domain/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LocalPhotoStorage storage;

  setUp(() {
    storage = LocalPhotoStorage(Directory.systemTemp.createTempSync('photos'));
  });

  test('guarda, lê e apaga uma foto', () async {
    final name = await storage.saveBytes(
      Uint8List.fromList([1, 2, 3]),
      recipeId: '42',
    );
    expect(storage.exists(name), isTrue);
    expect(await storage.readBytes(name), [1, 2, 3]);

    await storage.delete(name);
    expect(storage.exists(name), isFalse);
  });

  test('rejeita nomes perigosos', () {
    expect(LocalPhotoStorage.isValidName('42_1.jpg'), isTrue);
    expect(LocalPhotoStorage.isValidName('../x.jpg'), isFalse);
    expect(LocalPhotoStorage.isValidName('a/b.jpg'), isFalse);
    expect(
      () => storage.writeNamed('../x.jpg', Uint8List(1)),
      throwsArgumentError,
    );
  });

  test('cleanOrphanPhotos só apaga as fotos que nenhuma receita usa', () async {
    final used = await storage.saveBytes(Uint8List(1), recipeId: '1');
    final orphan1 = await storage.saveBytes(Uint8List(1), recipeId: '2');
    final orphan2 = await storage.saveBytes(Uint8List(1), recipeId: '3');
    final recipes = [
      Recipe(
        id: '1',
        title: 'Com foto',
        modes: const {CookingMode.traditional},
        photoPath: used,
      ),
    ];

    final removed = await cleanOrphanPhotos(storage, recipes);

    expect(removed, 2);
    expect(storage.exists(used), isTrue);
    expect(storage.exists(orphan1), isFalse);
    expect(storage.exists(orphan2), isFalse);
    expect(await storage.listNames(), [used]);
  });

  test('clear apaga todas as fotos', () async {
    final name = await storage.saveBytes(Uint8List(1), recipeId: '1');
    await storage.clear();
    expect(storage.exists(name), isFalse);
  });
}
