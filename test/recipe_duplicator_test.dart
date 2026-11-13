import 'dart:io';
import 'dart:typed_data';

import 'package:aromas_memorias/features/recipes/application/recipe_duplicator.dart';
import 'package:aromas_memorias/features/recipes/data/photo_storage.dart';
import 'package:aromas_memorias/features/recipes/domain/cooking_mode.dart';
import 'package:aromas_memorias/features/recipes/domain/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LocalPhotoStorage photos;

  setUp(() {
    photos = LocalPhotoStorage(Directory.systemTemp.createTempSync('dup_photos'));
  });

  test('copia os dados, com novo id e título "(cópia)"', () async {
    const original = Recipe(
      id: '1',
      title: 'Bolo',
      modes: {CookingMode.traditional, CookingMode.bimby},
      minutes: 40,
      servings: 6,
      ingredients: ['3 ovos'],
      steps: ['Bata.'],
      isFavorite: true,
      sourceUrl: 'https://x.pt/bolo',
      categoryId: 'desserts',
      notes: 'Menos sal.',
    );

    final copy = await duplicateRecipeDraft(original, photos);

    expect(copy.id, isNot(original.id));
    expect(copy.title, 'Bolo (cópia)');
    expect(copy.modes, original.modes);
    expect(copy.minutes, 40);
    expect(copy.servings, 6);
    expect(copy.ingredients, ['3 ovos']);
    expect(copy.steps, ['Bata.']);
    expect(copy.sourceUrl, 'https://x.pt/bolo');
    expect(copy.categoryId, 'desserts');
    expect(copy.notes, 'Menos sal.');
    expect(copy.isFavorite, isFalse);
    expect(copy.photoPath, isNull);
  });

  test('a foto é copiada para um ficheiro próprio', () async {
    final name = await photos.saveBytes(
      Uint8List.fromList([1, 2, 3]),
      recipeId: '1',
      extension: 'png',
    );
    final original = Recipe(
      id: '1',
      title: 'Bolo',
      modes: const {CookingMode.traditional},
      photoPath: name,
    );

    final copy = await duplicateRecipeDraft(original, photos);

    expect(copy.photoPath, isNotNull);
    expect(copy.photoPath, isNot(name));
    expect(copy.photoPath, endsWith('.png'));
    expect(await photos.readBytes(copy.photoPath!), [1, 2, 3]);

    // apagar a cópia não toca na foto original
    await photos.delete(copy.photoPath);
    expect(photos.exists(name), isTrue);
  });

  test('duplicate devolve null se a foto não existir', () async {
    expect(await photos.duplicate('nao_existe.jpg', recipeId: '1'), isNull);
  });
}
