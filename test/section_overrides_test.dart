import 'dart:io';

import 'package:aromas_memorias/features/shopping/data/section_overrides_repository.dart';
import 'package:aromas_memorias/features/shopping/domain/supermarket_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late HiveSectionOverridesRepository repo;
  late Box<dynamic> box;

  setUp(() async {
    Hive.init(Directory.systemTemp.createTempSync('overrides_test').path);
    box = await Hive.openBox('overrides');
    repo = HiveSectionOverridesRepository(box);
  });

  tearDown(() => Hive.deleteFromDisk());

  test('guarda, lê e repõe a secção de um ingrediente', () async {
    await repo.set('atum', SupermarketSection.pantry);
    expect(await repo.watchAll().first, {'atum': SupermarketSection.pantry});

    await repo.clear('atum');
    expect(await repo.watchAll().first, isEmpty);
  });

  test('ignora valores desconhecidos', () async {
    await box.put('xpto', 'secção que não existe');
    expect(await repo.watchAll().first, isEmpty);
  });
}
