import 'package:flutter/material.dart';

import '../application/recipe_deleter.dart';
import '../domain/recipe.dart';

/// Avisa que as receitas foram apagadas e oferece "Desfazer". As fotos só se
/// apagam quando a mensagem desaparece sem o utilizador desfazer.
void showDeletedSnackBar(
  ScaffoldMessengerState messenger,
  RecipeDeleter deleter,
  List<Recipe> removed,
) {
  if (removed.isEmpty) return;
  final text = removed.length == 1
      ? '1 receita apagada.'
      : '${removed.length} receitas apagadas.';

  messenger
      .showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => deleter.restore(removed),
          ),
        ),
      )
      .closed
      .then((reason) {
    if (reason != SnackBarClosedReason.action) deleter.purge(removed);
  });
}
