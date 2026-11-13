import 'package:flutter/material.dart' show ThemeMode;
import 'package:hive/hive.dart';

abstract interface class SettingsRepository {
  ThemeMode get themeMode;
  Future<void> setThemeMode(ThemeMode mode);
}

class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository(this._box);

  static const _themeKey = 'themeMode';

  final Box<dynamic> _box;

  @override
  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[_box.get(_themeKey)] ?? ThemeMode.system;

  @override
  Future<void> setThemeMode(ThemeMode mode) => _box.put(_themeKey, mode.name);
}
