import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/recipe_providers.dart';
import 'cooking_mode_ui.dart';
import 'recipe_form_page.dart';
import 'recipe_photo.dart';

class RecipeDetailPage extends ConsumerWidget {
  const RecipeDetailPage({super.key, required this.recipeId});

  final String recipeId;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(recipeRepositoryProvider);
    final storage = ref.read(photoStorageProvider);
    final photo = ref.read(recipeByIdProvider(recipeId))?.photoPath;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar receita?'),
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
    await repo.delete(recipeId);
    await storage.delete(photo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = ref.watch(recipeByIdProvider(recipeId));
    if (recipe == null) return const Scaffold();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => RecipeFormPage(recipe: recipe),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref),
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
              for (final m in recipe.modes)
                Chip(avatar: Icon(m.icon, size: 18), label: Text(m.label)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${recipe.minutes} min · ${recipe.servings} porções'),
          const SizedBox(height: 16),
          Text('Ingredientes', style: text.titleMedium),
          const SizedBox(height: 4),
          for (final i in recipe.ingredients) Text('• $i'),
          const SizedBox(height: 16),
          Text('Preparação', style: text.titleMedium),
          const SizedBox(height: 4),
          for (var n = 0; n < recipe.steps.length; n++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${n + 1}. ${recipe.steps[n]}'),
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
