import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/storage/hive_storage.dart';
import 'features/recipes/application/recipe_providers.dart';
import 'features/recipes/data/photo_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage.init();
  final photoStorage = await LocalPhotoStorage.inDocuments();
  runApp(
    ProviderScope(
      overrides: [photoStorageProvider.overrideWithValue(photoStorage)],
      child: const AromasMemoriasApp(),
    ),
  );
}
