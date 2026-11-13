import 'package:flutter/foundation.dart';

import 'supermarket_section.dart';

@immutable
class ShoppingItem {
  const ShoppingItem({
    required this.key,
    required this.ingredientKey,
    required this.name,
    required this.count,
    required this.checked,
    required this.section,
    required this.sectionIsCustom,
  });

  /// Identifica o ingrediente com a unidade (independente da quantidade),
  /// para guardar o "já comprei".
  final String key;

  /// Identifica só o ingrediente (ex.: `atum`), para guardar a secção escolhida.
  final String ingredientKey;

  /// Texto a mostrar, ex.: `750 g de farinha`.
  final String name;

  /// Em quantas refeições aparece.
  final int count;
  final bool checked;

  /// Secção do supermercado onde aparece.
  final SupermarketSection section;

  /// `true` se a secção foi escolhida pelo utilizador (e não sugerida pela app).
  final bool sectionIsCustom;
}
