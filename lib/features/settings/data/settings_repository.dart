import 'package:flutter/material.dart' show ThemeMode;
import 'package:hive/hive.dart';

abstract interface class SettingsRepository {
  ThemeMode get themeMode;
  Future<void> setThemeMode(ThemeMode mode);

  /// Nome da ordem escolhida na lista de receitas (ver `RecipeSort`), se existir.
  String? get recipeSortName;
  Future<void> setRecipeSortName(String name);
}

class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository(this._box);

  static const _themeKey = 'themeMode';
  static const _recipeSortKey = 'recipeSort';

  final Box<dynamic> _box;

  @override
  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[_box.get(_themeKey)] ?? ThemeMode.system;

  @override
  Future<void> setThemeMode(ThemeMode mode) => _box.put(_themeKey, mode.name);

  @override
  String? get recipeSortName => _box.get(_recipeSortKey) as String?;

  @override
  Future<void> setRecipeSortName(String name) => _box.put(_recipeSortKey, name);
}
