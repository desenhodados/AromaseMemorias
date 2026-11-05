enum MealType {
  lunch('Almoço'),
  dinner('Jantar');

  const MealType(this.label);

  final String label;
}

/// Chave única de um slot do planeador, ex.: `2026-11-01|lunch`.
String slotKey(DateTime day, MealType meal) {
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '${day.year}-$m-$d|${meal.name}';
}
