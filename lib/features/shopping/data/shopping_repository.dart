import 'package:hive/hive.dart';

abstract interface class ShoppingRepository {
  Stream<Set<String>> watchChecked();
  Future<void> setChecked(String name, {required bool checked});
  Future<void> clearChecked();
}

class HiveShoppingRepository implements ShoppingRepository {
  HiveShoppingRepository(this._box);

  final Box<dynamic> _box;

  Set<String> _readChecked() => {
        for (final k in _box.keys)
          if (_box.get(k) == true) k as String,
      };

  @override
  Stream<Set<String>> watchChecked() async* {
    yield _readChecked();
    await for (final _ in _box.watch()) {
      yield _readChecked();
    }
  }

  @override
  Future<void> setChecked(String name, {required bool checked}) =>
      checked ? _box.put(name, true) : _box.delete(name);

  @override
  Future<void> clearChecked() => _box.clear();
}
