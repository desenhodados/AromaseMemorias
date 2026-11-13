import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../application/category_providers.dart';
import '../application/recipe_providers.dart';
import '../domain/recipe.dart';
import '../domain/recipe_category.dart';
import 'category_editor_dialog.dart';
import 'recipe_category_ui.dart';

/// Criar, editar e apagar categorias personalizadas.
class ManageCategoriesPage extends ConsumerWidget {
  const ManageCategoriesPage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref, List<RecipeCategory> all) async {
    final repo = ref.read(categoryRepositoryProvider);
    final created = await showCategoryEditor(
      context,
      takenLabels: RecipeCategory.takenLabels(all),
    );
    if (created != null) await repo.save(created);
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    RecipeCategory category,
    List<RecipeCategory> all,
  ) async {
    final repo = ref.read(categoryRepositoryProvider);
    final edited = await showCategoryEditor(
      context,
      existing: category,
      takenLabels: RecipeCategory.takenLabels(all, exceptId: category.id),
    );
    if (edited != null) await repo.save(edited);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RecipeCategory category,
    int usedBy,
  ) async {
    final categories = ref.read(categoryRepositoryProvider);
    final recipesRepo = ref.read(recipeRepositoryProvider);
    final recipes = ref.read(recipesProvider).valueOrNull ?? const <Recipe>[];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Apagar "${category.label}"?'),
        content: Text(
          usedBy == 0
              ? 'Esta categoria não está a ser usada.'
              : usedBy == 1
                  ? '1 receita fica sem categoria.'
                  : '$usedBy receitas ficam sem categoria.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    for (final r in recipes) {
      if (r.categoryId == category.id) {
        await recipesRepo.save(r.copyWith(clearCategory: true));
      }
    }
    await categories.delete(category.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custom = ref.watch(customCategoriesProvider).valueOrNull ?? const <RecipeCategory>[];
    final all = ref.watch(allCategoriesProvider);
    final recipes = ref.watch(recipesProvider).valueOrNull ?? const <Recipe>[];
    final theme = Theme.of(context);
    final label = theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref, all),
        icon: const Icon(Icons.add),
        label: const Text('Nova categoria'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text('Personalizadas', style: label),
          const SizedBox(height: 8),
          if (custom.isEmpty)
            Text(
              'Ainda não criou nenhuma categoria. Toque em "Nova categoria" para começar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final c in custom)
              Builder(builder: (context) {
                final usedBy = recipes.where((r) => r.categoryId == c.id).length;
                return AppCard(
                  child: ListTile(
                    leading: Icon(c.icon),
                    title: Text(c.label),
                    subtitle: Text(usedBy == 1 ? '1 receita' : '$usedBy receitas'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar',
                          onPressed: () => _edit(context, ref, c, all),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Apagar',
                          onPressed: () => _delete(context, ref, c, usedBy),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          const SizedBox(height: 24),
          Text('Predefinidas', style: label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in RecipeCategory.builtIn)
                Chip(avatar: Icon(c.icon, size: 18), label: Text(c.label)),
            ],
          ),
        ],
      ),
    );
  }
}
