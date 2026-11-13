import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/recipe.dart';
import 'photo_storage.dart';
import 'recipe_html_parser.dart';
import 'recipe_json_ld_parser.dart';

class RecipeImportException implements Exception {
  const RecipeImportException(this.message, {this.details});

  final String message;

  /// Detalhe técnico do erro (útil para diagnóstico).
  final String? details;

  @override
  String toString() => message;
}

abstract interface class RecipeImporter {
  /// Devolve um rascunho de receita (ainda não guardado).
  Future<Recipe> importFromUrl(String url);
}

class HttpRecipeImporter implements RecipeImporter {
  HttpRecipeImporter({
    required PhotoStorage photos,
    http.Client? client,
    List<String> proxyPrefixes = const [],
  })  : _photos = photos,
        _client = client ?? http.Client(),
        _proxyPrefixes = proxyPrefixes;

  static const _headers = {
    'User-Agent': 'Mozilla/5.0 (compatible; AromasMemorias/1.0)',
    'Accept-Language': 'pt-PT,pt;q=0.9,en;q=0.8',
  };
  static const _maxPhotoBytes = 8 * 1024 * 1024;

  final PhotoStorage _photos;
  final http.Client _client;

  /// Na web, os pedidos passam por estes proxies (por causa do CORS); se um
  /// falhar, tenta o seguinte. Vazio = pedido direto (telemóvel).
  final List<String> _proxyPrefixes;

  @override
  Future<Recipe> importFromUrl(String url) async {
    final raw = url.trim();
    final uri = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
    if (uri == null || !uri.hasAuthority || !{'http', 'https'}.contains(uri.scheme)) {
      throw const RecipeImportException('Link inválido. Cole o endereço completo, com https://');
    }

    final html = await _fetchHtml(uri);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final recipe =
        RecipeJsonLdParser.parse(html, id: id, sourceUrl: uri.toString()) ??
            RecipeHtmlParser.parse(html, id: id, sourceUrl: uri.toString());
    if (recipe == null) {
      throw const RecipeImportException(
        'Não encontrei uma receita nesta página. Tente outro site ou use "Nova receita".',
      );
    }

    final imageUrl =
        RecipeJsonLdParser.imageUrl(html) ?? RecipeHtmlParser.imageUrl(html);
    if (imageUrl == null || !_photos.isSupported) return recipe;
    final photo = await _downloadPhoto(uri, imageUrl, recipe.id);
    return photo == null ? recipe : recipe.copyWith(photoPath: photo);
  }

  Future<String> _fetchHtml(Uri uri) async {
    final viaProxy = _proxyPrefixes.isNotEmpty;
    final targets = viaProxy
        ? [
            for (final p in _proxyPrefixes)
              Uri.parse('$p${Uri.encodeComponent(uri.toString())}'),
          ]
        : [uri];

    final errors = <String>[];
    var message = 'Não foi possível ligar ao site.';

    for (final target in targets) {
      try {
        final response = await _client
            .get(target, headers: viaProxy ? const {} : _headers)
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          return utf8.decode(response.bodyBytes, allowMalformed: true);
        }
        errors.add('${target.host}: HTTP ${response.statusCode}');
        message = viaProxy
            ? 'O serviço intermédio não conseguiu obter a página (erro ${response.statusCode}). '
                'Tente mais tarde ou use a app do telemóvel.'
            : 'O site respondeu com erro (${response.statusCode}).';
      } on TimeoutException {
        errors.add('${target.host}: tempo esgotado');
        message = 'O site demorou demasiado a responder. Tente novamente.';
      } on TlsException catch (e) {
        errors.add('${target.host}: $e');
        message = 'Não foi possível estabelecer uma ligação segura com o site.';
      } on Exception catch (e) {
        errors.add('${target.host}: $e');
        message = 'Não foi possível ligar ao site. Verifique a internet e, no Android, '
            'a permissão INTERNET no AndroidManifest.xml (ver README).';
      }
    }
    throw RecipeImportException(message, details: '${errors.join(' | ')} (pedido: $uri)');
  }

  /// A foto é opcional: qualquer falha é ignorada.
  Future<String?> _downloadPhoto(Uri page, String imageUrl, String recipeId) async {
    try {
      final imageUri = page.resolve(imageUrl);
      if (!{'http', 'https'}.contains(imageUri.scheme)) return null;
      final r = await _client
          .get(imageUri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      final type = r.headers['content-type'] ?? '';
      if (r.statusCode != 200 ||
          !type.startsWith('image/') ||
          r.bodyBytes.length > _maxPhotoBytes) {
        return null;
      }
      final ext = type.contains('png')
          ? 'png'
          : type.contains('webp')
              ? 'webp'
              : 'jpg';
      return await _photos.saveBytes(r.bodyBytes, recipeId: recipeId, extension: ext);
    } on Exception {
      return null;
    }
  }
}
