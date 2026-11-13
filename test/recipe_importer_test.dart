import 'dart:io';

import 'package:aromas_memorias/features/recipes/data/photo_storage.dart';
import 'package:aromas_memorias/features/recipes/data/recipe_importer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _html = '<script type="application/ld+json">'
    '{"@type":"Recipe","name":"Bolo"}</script>';

HttpRecipeImporter _importer(MockClient client) => HttpRecipeImporter(
      photos: LocalPhotoStorage(Directory.systemTemp.createTempSync('imp')),
      client: client,
    );

void main() {
  test('erro de rede devolve mensagem e detalhe técnico', () {
    final importer = _importer(
      MockClient((_) async => throw const SocketException("Failed host lookup: 'x.pt'")),
    );
    expect(
      () => importer.importFromUrl('https://x.pt/r'),
      throwsA(
        isA<RecipeImportException>().having(
          (e) => e.details,
          'details',
          contains('Failed host lookup'),
        ),
      ),
    );
  });

  test('aceita links sem https://', () async {
    final importer = _importer(
      MockClient((req) async {
        expect(req.url.scheme, 'https');
        return http.Response(_html, 200);
      }),
    );
    final recipe = await importer.importFromUrl('x.pt/receita');
    expect(recipe.title, 'Bolo');
  });

  test('com proxy (web) o pedido leva o endereço codificado', () async {
    late Uri requested;
    final importer = HttpRecipeImporter(
      photos: LocalPhotoStorage(Directory.systemTemp.createTempSync('imp')),
      proxyPrefixes: ['https://proxy.example/raw?url='],
      client: MockClient((req) async {
        requested = req.url;
        return http.Response(_html, 200);
      }),
    );
    await importer.importFromUrl('https://x.pt/r?a=1');
    expect(requested.host, 'proxy.example');
    expect(requested.queryParameters['url'], 'https://x.pt/r?a=1');
  });

  test('tenta o proxy seguinte quando o primeiro falha', () async {
    final importer = HttpRecipeImporter(
      photos: LocalPhotoStorage(Directory.systemTemp.createTempSync('imp')),
      proxyPrefixes: ['https://p1.example/?u=', 'https://p2.example/?u='],
      client: MockClient(
        (req) async => req.url.host == 'p1.example'
            ? http.Response('', 408)
            : http.Response(_html, 200),
      ),
    );
    final recipe = await importer.importFromUrl('https://x.pt/r');
    expect(recipe.title, 'Bolo');
  });
}
