import 'package:aromas_memorias/core/text_sharer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('imageMimeType pela extensão', () {
    expect(imageMimeType('/a/b/foto.png'), 'image/png');
    expect(imageMimeType('/a/b/foto.WEBP'), 'image/webp');
    expect(imageMimeType('/a/b/foto.jpg'), 'image/jpeg');
    expect(imageMimeType('/a/b/foto'), 'image/jpeg');
  });
}
