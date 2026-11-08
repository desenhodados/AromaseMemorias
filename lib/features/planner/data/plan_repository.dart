import 'package:hive/hive.dart';

import '../domain/meal_type.dart';

abstract interface class PlanRepository {
  /// slotKey -> recipeId
  Stream<Map<String, String>> watchAll();
  Future<void> assign(DateTime day, MealType meal, String recipeId);
  Future<void> clear(DateTime day, MealType meal);
}

class HivePlanRepository implements PlanRepository {
  HivePlanRepository(this._box);

  final Box<dynamic> _box;

  Map<String, String> _readAll() => {
        for (final k in _box.keys) k as String: _box.get(k) as String,
      };

  @override
  Stream<Map<String, String>> watchAll() async* {
    yield _readAll();
    await for (final _ in _box.watch()) {
      yield _readAll();
    }
  }

  @override
  Future<void> assign(DateTime day, MealType meal, String recipeId) =>
      _box.put(slotKey(day, meal), recipeId);

  @override
  Future<void> clear(DateTime day, MealType meal) =>
      _box.delete(slotKey(day, meal));
}
