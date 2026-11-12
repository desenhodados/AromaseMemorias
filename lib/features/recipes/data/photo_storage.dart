import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Guarda as fotos das receitas. As receitas só guardam o *nome* do ficheiro,
/// porque o caminho absoluto pode mudar (ex.: atualizações no iOS).
abstract interface class PhotoStorage {
  /// `false` em plataformas sem ficheiros (web).
  bool get isSupported;

  File fileFor(String name);
  bool exists(String name);

  /// Copia a foto escolhida para a pasta da app e devolve o nome do ficheiro.
  Future<String> saveFromPath(String sourcePath, {required String recipeId});
  Future<String> saveBytes(
    Uint8List bytes, {
    required String recipeId,
    String extension = 'jpg',
  });

  Future<Uint8List?> readBytes(String name);

  /// Usado ao restaurar backups (o nome vem do ficheiro, por isso é validado).
  Future<void> writeNamed(String name, Uint8List bytes);
  Future<void> delete(String? name);
  Future<void> clear();
}

class LocalPhotoStorage implements PhotoStorage {
  LocalPhotoStorage(this._dir);

  static Future<LocalPhotoStorage> inDocuments() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/recipe_photos');
    await dir.create(recursive: true);
    return LocalPhotoStorage(dir);
  }

  static final _validName =
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*(\.[A-Za-z0-9]+)?$');

  static bool isValidName(String name) => _validName.hasMatch(name);

  final Directory _dir;

  @override
  bool get isSupported => true;

  @override
  File fileFor(String name) =>
      File('${_dir.path}/${name.replaceAll(RegExp(r'[\\/]'), '_')}');

  @override
  bool exists(String name) => isValidName(name) && fileFor(name).existsSync();

  String _newName(String recipeId, String extension) =>
      '${recipeId}_${DateTime.now().microsecondsSinceEpoch}.$extension';

  @override
  Future<String> saveFromPath(String sourcePath, {required String recipeId}) async {
    final dot = sourcePath.lastIndexOf('.');
    final ext = dot == -1 ? 'jpg' : sourcePath.substring(dot + 1).toLowerCase();
    final name = _newName(
      recipeId,
      RegExp(r'^[a-z0-9]{2,5}$').hasMatch(ext) ? ext : 'jpg',
    );
    await File(sourcePath).copy(fileFor(name).path);
    return name;
  }

  @override
  Future<String> saveBytes(
    Uint8List bytes, {
    required String recipeId,
    String extension = 'jpg',
  }) async {
    final name = _newName(recipeId, extension);
    await fileFor(name).writeAsBytes(bytes, flush: true);
    return name;
  }

  @override
  Future<Uint8List?> readBytes(String name) async =>
      exists(name) ? fileFor(name).readAsBytes() : null;

  @override
  Future<void> writeNamed(String name, Uint8List bytes) async {
    if (!isValidName(name)) throw ArgumentError.value(name, 'name');
    await fileFor(name).writeAsBytes(bytes, flush: true);
  }

  @override
  Future<void> delete(String? name) async {
    if (name == null || !isValidName(name)) return;
    final file = fileFor(name);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> clear() async {
    if (!await _dir.exists()) return;
    await for (final e in _dir.list()) {
      if (e is File) await e.delete();
    }
  }
}

/// Usado na web, onde não há sistema de ficheiros: as fotos ficam desativadas.
class NoPhotoStorage implements PhotoStorage {
  const NoPhotoStorage();

  static const _msg = 'Fotos não suportadas nesta plataforma.';

  @override
  bool get isSupported => false;

  @override
  File fileFor(String name) => throw UnsupportedError(_msg);

  @override
  bool exists(String name) => false;

  @override
  Future<String> saveFromPath(String sourcePath, {required String recipeId}) =>
      throw UnsupportedError(_msg);

  @override
  Future<String> saveBytes(
    Uint8List bytes, {
    required String recipeId,
    String extension = 'jpg',
  }) =>
      throw UnsupportedError(_msg);

  @override
  Future<Uint8List?> readBytes(String name) async => null;

  @override
  Future<void> writeNamed(String name, Uint8List bytes) async {}

  @override
  Future<void> delete(String? name) async {}

  @override
  Future<void> clear() async {}
}
