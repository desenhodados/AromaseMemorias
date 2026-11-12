import 'package:flutter/foundation.dart';

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

@immutable
class BackupSummary {
  const BackupSummary({required this.recipes, required this.plannedMeals});

  final int recipes;
  final int plannedMeals;
}
