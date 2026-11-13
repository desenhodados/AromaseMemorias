import 'package:flutter/foundation.dart';

/// Refeição planeada num slot: receita + para quantas pessoas.
@immutable
class PlanEntry {
  const PlanEntry({required this.recipeId, this.servings});

  final String recipeId;

  /// `null` = as porções da receita.
  final int? servings;

  /// Formato guardado: texto simples (formato antigo) ou mapa com porções.
  Object toRaw() =>
      servings == null ? recipeId : {'recipeId': recipeId, 'servings': servings};

  static PlanEntry? fromRaw(Object? raw) {
    if (raw is String) return PlanEntry(recipeId: raw);
    if (raw is Map) {
      final id = raw['recipeId'];
      final servings = raw['servings'];
      if (id is String) {
        return PlanEntry(
          recipeId: id,
          servings: servings is int && servings > 0 ? servings : null,
        );
      }
    }
    return null;
  }
}
