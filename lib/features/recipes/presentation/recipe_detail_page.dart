import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/text_sharer.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/share_sheet.dart';
import '../../cooking/presentation/cooking_session_page.dart';
import '../application/category_providers.dart';
import '../application/recipe_deleter.dart';
import '../application/recipe_duplicator.dart';
import '../application/recipe_providers.dart';
import '../domain/recipe_share_text.dart';
import 'cooking_mode_ui.dart';
import 'recipe_category_ui.dart';
import 'recipe_deleted_snackbar.dart';
import 'recipe_form_page.dart';
import 'recipe_notes_editor.dart';
import 'recipe_photo.dart';

class RecipeDetailPage extends ConsumerWidget {
  const RecipeDetailPage({super.key, required this.recipeId});

  final String recipeId;

  /// Caminho da foto para partilhar, ou `null` (sem foto ou sem suporte, ex.: web).
  String? _sharePhotoPath(WidgetRef ref, Recipe recipe) {
    final photo = recipe.photoPath;
    final storage = ref.read(photoStorageProvider);
    if (photo == null || !storage.isSupported || !storage.exists(photo)) return null;
    return storage.fileFor(photo).path;
  }

  /// Abre uma cópia da receita no formulário, para criar uma variação.
  Future<void> _duplicate(BuildContext context, WidgetRef ref, Recipe recipe) async {
    final draft = await duplicateRecipeDraft(recipe, ref.read(photoStorageProvider));
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RecipeFormPage(recipe: draft, isNew: true),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final recipe = ref.read(recipeByIdProvider(recipeId));
    if (recipe == null) return;
    final deleter = ref.read(recipeDeleterProvider);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar receita?'),
        content: const Text('Poderá desfazer durante alguns segundos depois de apagar.'),
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
    if (context.mounted) Navigator.pop(context);
    await deleter.delete([recipe]);
    showDeletedSnackBar(messenger, deleter, [recipe]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = ref.watch(recipeByIdProvider(recipeId));
    if (recipe == null) return const Scaffold();
    final category = ref.watch(categoryByIdProvider(recipe.categoryId));
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Partilhar',
            onPressed: () => showShareSheet(
              context,
              sharer: ref.read(textSharerProvider),
              subject: recipe.title,
              text: recipeShareText(
                recipe,
                ingredients: ref.read(scaledIngredientsProvider(recipe.id)),
                servings: ref.read(servingsOverrideProvider(recipe.id)) ?? recipe.servings,
                categoryLabel: category?.label,
              ),
              copiedMessage: 'Receita copiada.',
              imagePath: _sharePhotoPath(ref, recipe),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => RecipeFormPage(recipe: recipe),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'duplicate') {
                _duplicate(context, ref, recipe);
              } else if (value == 'delete') {
                _confirmDelete(context, ref);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: Icon(Icons.copy_all_outlined),
                  title: Text('Duplicar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Apagar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (recipe.photoPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: RecipePhoto(photoPath: recipe.photoPath, cacheWidth: 900),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 8,
            children: [
              if (category != null)
                Chip(
                  avatar: Icon(category.icon, size: 18),
                  label: Text(category.label),
                ),
              for (final m in recipe.modes)
                Chip(avatar: Icon(m.icon, size: 18), label: Text(m.label)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${recipe.minutes} min · ${recipe.servings} porções'),
          const SizedBox(height: 16),
          if (recipe.steps.isNotEmpty) ...[
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => CookingSessionPage(recipeId: recipe.id),
                ),
              ),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Modo de cozinhar'),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(child: Text('Ingredientes', style: text.titleMedium)),
              _ServingsStepper(recipeId: recipe.id, base: recipe.servings),
            ],
          ),
          const SizedBox(height: 4),
          for (final i in ref.watch(scaledIngredientsProvider(recipe.id)))
            Text('• $i'),
          const SizedBox(height: 16),
          Text('Preparação', style: text.titleMedium),
          const SizedBox(height: 4),
          for (var n = 0; n < recipe.steps.length; n++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${n + 1}. ${recipe.steps[n]}'),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text('Notas', style: text.titleMedium)),
              TextButton.icon(
                onPressed: () => editRecipeNotes(context, ref, recipe),
                icon: Icon(
                  recipe.notes.isEmpty ? Icons.add : Icons.edit_outlined,
                  size: 18,
                ),
                label: Text(recipe.notes.isEmpty ? 'Adicionar' : 'Editar'),
              ),
            ],
          ),
          if (recipe.notes.isEmpty)
            Text(
              'Ainda sem notas. Escreva o que quer lembrar na próxima vez.',
              style: text.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(recipe.notes),
              ),
            ),
          if (recipe.sourceUrl != null) ...[
            const SizedBox(height: 16),
            SelectableText('Fonte: ${recipe.sourceUrl}', style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Escolhe para quantas pessoas é a receita; as quantidades ajustam-se.
class _ServingsStepper extends ConsumerWidget {
  const _ServingsStepper({required this.recipeId, required this.base});

  final String recipeId;
  final int base;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(servingsOverrideProvider(recipeId)) ?? base;
    final notifier = ref.read(servingsOverrideProvider(recipeId).notifier);
    final text = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          icon: const Icon(Icons.remove),
          tooltip: 'Menos uma porção',
          visualDensity: VisualDensity.compact,
          onPressed: current > 1 ? () => notifier.state = current - 1 : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$current', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(current == 1 ? 'porção' : 'porções', style: text.labelSmall),
            ],
          ),
        ),
        IconButton.outlined(
          icon: const Icon(Icons.add),
          tooltip: 'Mais uma porção',
          visualDensity: VisualDensity.compact,
          onPressed: current < 99 ? () => notifier.state = current + 1 : null,
        ),
        if (current != base)
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Repor $base porções',
            visualDensity: VisualDensity.compact,
            onPressed: () => notifier.state = null,
          ),
      ],
    );
  }
}
