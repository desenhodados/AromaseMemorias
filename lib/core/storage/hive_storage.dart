import 'package:hive_flutter/hive_flutter.dart';

abstract final class HiveBoxes {
  static const recipes = 'recipes';
  static const plan = 'plan';
  static const shoppingChecked = 'shopping_checked';
  static const settings = 'settings';
  static const sectionOverrides = 'section_overrides';
  static const categories = 'categories';
}

abstract final class HiveStorage {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(HiveBoxes.recipes),
      Hive.openBox(HiveBoxes.plan),
      Hive.openBox(HiveBoxes.shoppingChecked),
      Hive.openBox(HiveBoxes.settings),
      Hive.openBox(HiveBoxes.sectionOverrides),
      Hive.openBox(HiveBoxes.categories),
    ]);
  }
}
