import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import '../../recipes/data/photo_storage.dart';
import '../../recipes/domain/recipe.dart';
import '../domain/backup.dart';

abstract interface class BackupRepository {
  /// Todos os dados da app (incluindo fotos) serializados em JSON.
  Future<String> exportJson();

  /// Valida o JSON antes de escrever. Com [replace] apaga os dados atuais;
  /// caso contrário junta (receitas com o mesmo id são atualizadas).
  Future<BackupSummary> restore(String json, {required bool replace});
}

typedef _ParsedBackup = ({
  Map<String, Map<String, dynamic>> recipes,
  Map<String, String> plan,
  List<String> checked,
  Map<String, Uint8List> photos,
});

class HiveBackupRepository implements BackupRepository {
  HiveBackupRepository({
    required Box<dynamic> recipes,
    required Box<dynamic> plan,
    required Box<dynamic> checked,
    required PhotoStorage photos,
  })  : _recipes = recipes,
        _plan = plan,
        _checked = checked,
        _photos = photos;

  static const _appId = 'aromas_memorias';
  static const _version = 1;

  final Box<dynamic> _recipes;
  final Box<dynamic> _plan;
  final Box<dynamic> _checked;
  final PhotoStorage _photos;

  @override
  Future<String> exportJson() async {
    final recipes = [
      for (final e in _recipes.values) Map<String, dynamic>.from(e as Map),
    ];

    final photos = <String, String>{};
    for (final r in recipes) {
      final name = r['photoPath'] as String?;
      if (name == null || photos.containsKey(name)) continue;
      final bytes = await _photos.readBytes(name);
      if (bytes != null) photos[name] = base64Encode(bytes);
    }

    final data = <String, dynamic>{
      'app': _appId,
      'version': _version,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'recipes': recipes,
      'plan': {for (final k in _plan.keys) k as String: _plan.get(k)},
      'shoppingChecked': [
        for (final k in _checked.keys)
          if (_checked.get(k) == true) k as String,
      ],
      'photos': photos,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  @override
  Future<BackupSummary> restore(String json, {required bool replace}) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      throw const BackupException('O ficheiro não é um JSON válido.');
    }
    if (decoded is! Map || decoded['app'] != _appId) {
      throw const BackupException(
        'Este ficheiro não é um backup do Aromas & Memórias.',
      );
    }
    final version = decoded['version'];
    if (version is! int || version > _version) {
      throw const BackupException(
        'Versão de backup não suportada. Atualize a app.',
      );
    }

    final parsed = _parse(decoded);

    // Uma receita só mantém a foto se ela vier no backup (ou já existir aqui).
    for (final m in parsed.recipes.values) {
      final name = m['photoPath'] as String?;
      if (name != null &&
          !parsed.photos.containsKey(name) &&
          (replace || !_photos.exists(name))) {
        m['photoPath'] = null;
      }
    }

    if (replace) {
      await Future.wait([
        _recipes.clear(),
        _plan.clear(),
        _checked.clear(),
        _photos.clear(),
      ]);
    }
    for (final e in parsed.photos.entries) {
      await _photos.writeNamed(e.key, e.value);
    }
    await _recipes.putAll(parsed.recipes);
    await _plan.putAll(parsed.plan);
    await _checked.putAll({for (final n in parsed.checked) n: true});

    return BackupSummary(
      recipes: parsed.recipes.length,
      plannedMeals: parsed.plan.length,
    );
  }

  /// Valida tudo antes de tocar na base de dados ou nos ficheiros.
  _ParsedBackup _parse(Map<dynamic, dynamic> data) {
    try {
      final recipes = <String, Map<String, dynamic>>{};
      for (final item in data['recipes'] as List? ?? const []) {
        final recipe = Recipe.fromMap(item as Map);
        recipes[recipe.id] = recipe.toMap();
      }
      final plan = <String, String>{
        for (final e in (data['plan'] as Map? ?? const {}).entries)
          e.key as String: e.value as String,
      };
      final checked = <String>[
        for (final n in data['shoppingChecked'] as List? ?? const []) n as String,
      ];
      final photos = <String, Uint8List>{};
      for (final e in (data['photos'] as Map? ?? const {}).entries) {
        final name = e.key as String;
        if (!LocalPhotoStorage.isValidName(name)) continue;
        photos[name] = base64Decode(e.value as String);
      }
      return (recipes: recipes, plan: plan, checked: checked, photos: photos);
    } on TypeError {
      throw const BackupException('O backup está corrompido ou incompleto.');
    } on FormatException {
      throw const BackupException('O backup está corrompido ou incompleto.');
    }
  }
}
