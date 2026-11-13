import 'package:hive/hive.dart';

import '../domain/meal_type.dart';
import '../domain/plan_entry.dart';

abstract interface class PlanRepository {
  /// slotKey -> refeição planeada
  Stream<Map<String, PlanEntry>> watchAll();
  Future<void> assign(DateTime day, MealType meal, PlanEntry entry);
  Future<void> clear(DateTime day, MealType meal);
}

class HivePlanRepository implements PlanRepository {
  HivePlanRepository(this._box);

  final Box<dynamic> _box;

  Map<String, PlanEntry> _readAll() {
    final result = <String, PlanEntry>{};
    for (final key in _box.keys) {
      final entry = PlanEntry.fromRaw(_box.get(key));
      if (entry != null) result[key as String] = entry;
    }
    return result;
  }

  @override
  Stream<Map<String, PlanEntry>> watchAll() async* {
    yield _readAll();
    await for (final _ in _box.watch()) {
      yield _readAll();
    }
  }

  @override
  Future<void> assign(DateTime day, MealType meal, PlanEntry entry) =>
      _box.put(slotKey(day, meal), entry.toRaw());

  @override
  Future<void> clear(DateTime day, MealType meal) =>
      _box.delete(slotKey(day, meal));
}
