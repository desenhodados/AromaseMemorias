import 'dart:io';
import 'dart:typed_data';

import 'package:aromas_memorias/features/recipes/application/recipe_providers.dart';
import 'package:aromas_memorias/features/recipes/application/recipe_selection.dart';
import 'package:aromas_memorias/features/recipes/data/photo_storage.dart';
import 'package:aromas_memorias/features/recipes/data/recipe_repository.dart';
import 'package:aromas_memorias/features/recipes/domain/cooking_mode.dart';
import 'package:aromas_memorias/features/recipes/domain/recipe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

Recipe _r(String id, {String? cat, bool favorite = false, String? photo}) => Recipe(
      id: id,
      title: 'R$id',
      modes: const {CookingMode.traditional},
      categoryId: cat,
      isFavorite: favorite,
      photoPath: photo,
    );

class _FakeRepo implements RecipeRepository {
  _FakeRepo(this.items);

  List<Recipe> items;

  @override
  Stream<List<Recipe>> watchAll() => Stream.value(List.of(items));

  @override
  Future<void> save(Recipe recipe) async {
    final index = items.indexWhere((i) => i.id == recipe.id);
    items = [...items];
    if (index == -1) {
      items.add(recipe);
    } else {
      items[index] = recipe;
    }
  }

  @override
  Future<void> saveAll(List<Recipe> recipes) async {
    for (final r in recipes) {
      await save(r);
    }
  }

  @override
  Future<void> delete(String id) async {
    items = items.where((r) => r.id != id).toList();
  }

  @override
  Future<void> deleteAll(Iterable<String> ids) async {
    items = items.where((r) => !ids.contains(r.id)).toList();
  }
}

void main() {
  test('selecionar, desselecionar, selecionar tudo e limpar', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final selection = container.read(recipeSelectionProvider.notifier);

    selection
      ..toggle('1')
      ..toggle('2');
    expect(container.read(recipeSelectionProvider), {'1', '2'});

    selection.toggle('1');
    expect(container.read(recipeSelectionProvider), {'2'});

    selection.selectAll(['1', '2', '3']);
    expect(container.read(recipeSelectionProvider), hasLength(3));

    selection.clear();
    expect(container.read(recipeSelectionProvider), isEmpty);
  });

  group('assignCategory', () {
    late _FakeRepo repo;
    late ProviderContainer container;

    setUp(() async {
      repo = _FakeRepo([_r('1'), _r('2'), _r('3', cat: 'soups')]);
      container = ProviderContainer(
        overrides: [recipeRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await container.read(recipesProvider.future);
    });

    test('muda só as receitas selecionadas e limpa a seleção', () async {
      final selection = container.read(recipeSelectionProvider.notifier)
        ..selectAll(['1', '3']);

      final count = await selection.assignCategory('desserts');

      expect(count, 2);
      expect(repo.items.map((r) => r.categoryId), ['desserts', null, 'desserts']);
      expect(container.read(recipeSelectionProvider), isEmpty);
    });

    test('null tira a categoria', () async {
      final selection = container.read(recipeSelectionProvider.notifier)
        ..selectAll(['3']);

      await selection.assignCategory(null);

      expect(repo.items.last.categoryId, isNull);
    });
  });

  group('ações em lote', () {
    late _FakeRepo repo;
    late LocalPhotoStorage photos;
    late ProviderContainer container;

    setUp(() async {
      photos = LocalPhotoStorage(Directory.systemTemp.createTempSync('bulk_photos'));
      final photo = await photos.saveBytes(Uint8List(1), recipeId: '1');
      repo = _FakeRepo([
        _r('1', photo: photo),
        _r('2', favorite: true),
        _r('3'),
      ]);
      container = ProviderContainer(
        overrides: [
          recipeRepositoryProvider.overrideWithValue(repo),
          photoStorageProvider.overrideWithValue(photos),
        ],
      );
      addTearDown(container.dispose);
      await container.read(recipesProvider.future);
    });

    test('marca as selecionadas como favoritas', () async {
      final selection = container.read(recipeSelectionProvider.notifier)
        ..selectAll(['1', '2']);

      final count = await selection.setFavorite(true);

      expect(count, 2);
      expect(repo.items.map((r) => r.isFavorite), [true, true, false]);
      expect(container.read(recipeSelectionProvider), isEmpty);
    });

    test('tira as selecionadas dos favoritos', () async {
      final selection = container.read(recipeSelectionProvider.notifier)
        ..selectAll(['2']);

      await selection.setFavorite(false);

      expect(repo.items.map((r) => r.isFavorite), [false, false, false]);
    });

    test('apaga as selecionadas mas guarda as fotos para o "Desfazer"', () async {
      final photo = repo.items.first.photoPath!;
      final selection = container.read(recipeSelectionProvider.notifier)
        ..selectAll(['1', '3']);

      final removed = await selection.deleteSelected();

      expect(removed.map((r) => r.id), ['1', '3']);
      expect(repo.items.map((r) => r.id), ['2']);
      expect(photos.exists(photo), isTrue);
      expect(container.read(recipeSelectionProvider), isEmpty);

      await container.read(recipeDeleterProvider).restore(removed);
      expect(repo.items.map((r) => r.id).toSet(), {'1', '2', '3'});
    });
  });

  test('HiveRecipeRepository.saveAll guarda várias receitas de uma vez', () async {
    Hive.init(Directory.systemTemp.createTempSync('saveall_test').path);
    addTearDown(Hive.deleteFromDisk);
    final repo = HiveRecipeRepository(await Hive.openBox('recipes'));

    await repo.saveAll([_r('1'), _r('2')]);

    final all = await repo.watchAll().first;
    expect(all.map((r) => r.id), ['1', '2']);

    await repo.deleteAll(['1', '2']);
    expect(await repo.watchAll().first, isEmpty);
  });
}
