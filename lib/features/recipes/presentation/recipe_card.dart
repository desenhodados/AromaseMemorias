import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../application/category_providers.dart';
import '../application/recipe_providers.dart';
import '../application/recipe_selection.dart';
import '../domain/recipe.dart';
import 'cooking_mode_ui.dart';
import 'recipe_category_ui.dart';
import 'recipe_detail_page.dart';
import 'recipe_photo.dart';

class RecipeCard extends ConsumerWidget {
  const RecipeCard({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final category = ref.watch(categoryByIdProvider(recipe.categoryId));
    final selection = ref.watch(recipeSelectionProvider);
    final selecting = selection.isNotEmpty;
    final selected = selection.contains(recipe.id);
    final selectionNotifier = ref.read(recipeSelectionProvider.notifier);

    return AppCard(
      selected: selected,
      onTap: selecting
          ? () => selectionNotifier.toggle(recipe.id)
          : () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => RecipeDetailPage(recipeId: recipe.id),
                ),
              ),
      onLongPress: () => selectionNotifier.toggle(recipe.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(
          children: [
            _Leading(recipe: recipe),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (recipe.minutes > 0)
                        _Meta(icon: Icons.schedule, label: '${recipe.minutes} min'),
                      _Meta(icon: Icons.people_outline, label: '${recipe.servings}'),
                      if (category != null)
                        _Meta(icon: category.icon, label: category.label),
                      if (recipe.notes.isNotEmpty)
                        const _Meta(icon: Icons.sticky_note_2_outlined, label: 'Nota'),
                      for (final m in recipe.modes)
                        _Meta(icon: m.icon, label: m.label, color: scheme.primary),
                    ],
                  ),
                ],
              ),
            ),
            if (selecting)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? scheme.primary : scheme.outline,
                ),
              )
            else
              IconButton(
                icon: Icon(recipe.isFavorite ? Icons.favorite : Icons.favorite_border),
                color: recipe.isFavorite ? Colors.red : null,
                onPressed: () => ref
                    .read(recipeRepositoryProvider)
                    .save(recipe.copyWith(isFavorite: !recipe.isFavorite)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c)),
      ],
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatar = CircleAvatar(
      backgroundColor: scheme.tertiaryContainer,
      foregroundColor: scheme.onTertiaryContainer,
      child: Icon(
        recipe.modes.isEmpty ? Icons.restaurant : recipe.modes.first.icon,
      ),
    );
    if (recipe.photoPath == null) return avatar;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: RecipePhoto(
          photoPath: recipe.photoPath,
          cacheWidth: 168,
          placeholder: avatar,
        ),
      ),
    );
  }
}
