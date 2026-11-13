import 'package:hive/hive.dart';

import '../domain/supermarket_section.dart';

/// Secções escolhidas pelo utilizador (ingrediente -> secção), que têm
/// prioridade sobre a sugestão automática.
abstract interface class SectionOverridesRepository {
  Stream<Map<String, SupermarketSection>> watchAll();
  Future<void> set(String ingredientKey, SupermarketSection section);
  Future<void> clear(String ingredientKey);
}

class HiveSectionOverridesRepository implements SectionOverridesRepository {
  HiveSectionOverridesRepository(this._box);

  final Box<dynamic> _box;

  Map<String, SupermarketSection> _readAll() {
    final byName = SupermarketSection.values.asNameMap();
    final result = <String, SupermarketSection>{};
    for (final key in _box.keys) {
      final section = byName[_box.get(key)];
      if (section != null) result[key as String] = section;
    }
    return result;
  }

  @override
  Stream<Map<String, SupermarketSection>> watchAll() async* {
    yield _readAll();
    await for (final _ in _box.watch()) {
      yield _readAll();
    }
  }

  @override
  Future<void> set(String ingredientKey, SupermarketSection section) =>
      _box.put(ingredientKey, section.name);

  @override
  Future<void> clear(String ingredientKey) => _box.delete(ingredientKey);
}
