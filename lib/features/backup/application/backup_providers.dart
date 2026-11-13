import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_storage.dart';
import '../../recipes/application/recipe_providers.dart';
import '../data/backup_file_service.dart';
import '../data/backup_repository.dart';

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => HiveBackupRepository(
    recipes: Hive.box(HiveBoxes.recipes),
    plan: Hive.box(HiveBoxes.plan),
    checked: Hive.box(HiveBoxes.shoppingChecked),
    photos: ref.watch(photoStorageProvider),
  ),
);

final backupFileServiceProvider = Provider<BackupFileService>(
  (ref) => DeviceBackupFileService(),
);
