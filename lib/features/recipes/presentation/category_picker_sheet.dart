import 'package:flutter/material.dart';

import '../domain/recipe_category.dart';
import 'recipe_category_ui.dart';

/// Valores especiais devolvidos por [showCategoryPicker].
const categoryPickerNone = '__sem__';
const categoryPickerNew = '__nova__';

/// Escolher uma categoria. Devolve o id da categoria, [categoryPickerNone],
/// [categoryPickerNew] ou `null` se o utilizador cancelar.
Future<String?> showCategoryPicker(
  BuildContext context,
  List<RecipeCategory> categories, {
  String title = 'Definir categoria',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Sem categoria'),
            onTap: () => Navigator.pop(ctx, categoryPickerNone),
          ),
          for (final c in categories)
            ListTile(
              leading: Icon(c.icon),
              title: Text(c.label),
              onTap: () => Navigator.pop(ctx, c.id),
            ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Nova categoria…'),
            onTap: () => Navigator.pop(ctx, categoryPickerNew),
          ),
        ],
      ),
    ),
  );
}
