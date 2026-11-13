import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'app/app.dart';
import 'core/storage/hive_storage.dart';
import 'features/recipes/application/photo_cleanup.dart';
import 'features/recipes/application/recipe_providers.dart';
import 'features/recipes/data/photo_storage.dart';
import 'features/recipes/data/recipe_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage.init();
  // Na web não há pasta de ficheiros: as fotos ficam desativadas.
  final PhotoStorage photoStorage =
      kIsWeb ? const NoPhotoStorage() : await LocalPhotoStorage.inDocuments();

  // Limpeza de fotos sem receita; nunca deve impedir a app de arrancar.
  if (photoStorage.isSupported) {
    try {
      final recipes =
          await HiveRecipeRepository(Hive.box(HiveBoxes.recipes)).watchAll().first;
      await cleanOrphanPhotos(photoStorage, recipes);
    } on Exception {
      // Fica para a próxima vez.
    }
  }

  runApp(
    ProviderScope(
      overrides: [photoStorageProvider.overrideWithValue(photoStorage)],
      child: const AromasMemoriasApp(),
    ),
  );
}
