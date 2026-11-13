import 'dart:io';
import 'dart:typed_data';

import 'package:aromas_memorias/features/recipes/data/photo_storage.dart';
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

  test('clear apaga todas as fotos', () async {
    final name = await storage.saveBytes(Uint8List(1), recipeId: '1');
    await storage.clear();
    expect(storage.exists(name), isFalse);
  });
}
