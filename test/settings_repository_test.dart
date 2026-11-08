import 'dart:io';

import 'package:aromas_memorias/features/settings/data/settings_repository.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late HiveSettingsRepository repo;

  setUp(() async {
    Hive.init(Directory.systemTemp.createTempSync('settings_test').path);
    repo = HiveSettingsRepository(await Hive.openBox('settings'));
  });

  tearDown(() => Hive.deleteFromDisk());

  test('o tema por omissão segue o sistema', () {
    expect(repo.themeMode, ThemeMode.system);
  });

  test('guarda e lê o tema escolhido', () async {
    await repo.setThemeMode(ThemeMode.dark);
    expect(repo.themeMode, ThemeMode.dark);
  });
}
