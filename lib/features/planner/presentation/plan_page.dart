import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../../recipes/application/recipe_providers.dart';
import '../../recipes/domain/recipe.dart';
import '../application/plan_providers.dart';
import '../domain/meal_type.dart';
import '../domain/plan_entry.dart';

const _weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  Future<int?> _askServings(BuildContext context, int initial) =>
      showDialog<int>(
        context: context,
        builder: (_) => _ServingsDialog(initial: initial),
      );

  /// Escolhe a receita e depois para quantas pessoas.
  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
    MealType meal,
    List<Recipe> recipes,
    PlanEntry? current,
  ) async {
    final repo = ref.read(planRepositoryProvider);
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Escolher receita'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('— Remover —'),
          ),
          for (final r in recipes)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, r.id),
              child: Text(r.title),
            ),
        ],
      ),
    );
    if (id == null) return;
    if (id.isEmpty) {
      await repo.clear(day, meal);
      return;
    }
    final recipe = recipes.where((r) => r.id == id).firstOrNull;
    if (recipe == null || !context.mounted) return;

    final initial = current?.recipeId == id
        ? (current?.servings ?? recipe.servings)
        : recipe.servings;
    final servings = await _askServings(context, initial);
    if (servings == null) return;
    await repo.assign(
      day,
      meal,
      PlanEntry(
        recipeId: id,
        servings: servings == recipe.servings ? null : servings,
      ),
    );
  }

  Future<void> _editServings(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
    MealType meal,
    PlanEntry entry,
    Recipe recipe,
  ) async {
    final repo = ref.read(planRepositoryProvider);
    final servings = await _askServings(context, entry.servings ?? recipe.servings);
    if (servings == null) return;
    await repo.assign(
      day,
      meal,
      PlanEntry(
        recipeId: entry.recipeId,
        servings: servings == recipe.servings ? null : servings,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider).valueOrNull ?? const <String, PlanEntry>{};
    final recipes = ref.watch(recipesProvider).valueOrNull ?? const <Recipe>[];
    final byId = {for (final r in recipes) r.id: r};
    final today = DateTime.now();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 7,
      itemBuilder: (context, i) {
        final day = today.add(Duration(days: i));
        return AppCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_weekdays[day.weekday - 1]} ${day.day}/${day.month}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final meal in MealType.values)
                  _slot(context, ref, day, meal, plan, byId, recipes),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _slot(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
    MealType meal,
    Map<String, PlanEntry> plan,
    Map<String, Recipe> byId,
    List<Recipe> recipes,
  ) {
    final entry = plan[slotKey(day, meal)];
    final recipe = entry == null ? null : byId[entry.recipeId];

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(meal.label),
      subtitle: Text(recipe?.title ?? 'Toque para escolher'),
      trailing: (entry == null || recipe == null)
          ? const Icon(Icons.chevron_right)
          : TextButton.icon(
              onPressed: () => _editServings(context, ref, day, meal, entry, recipe),
              icon: const Icon(Icons.people_outline, size: 18),
              label: Text('${entry.servings ?? recipe.servings}'),
            ),
      onTap: () => _pick(context, ref, day, meal, recipes, entry),
    );
  }
}

class _ServingsDialog extends StatefulWidget {
  const _ServingsDialog({required this.initial});

  final int initial;

  @override
  State<_ServingsDialog> createState() => _ServingsDialogState();
}

class _ServingsDialogState extends State<_ServingsDialog> {
  late int _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Para quantas pessoas?'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.outlined(
            icon: const Icon(Icons.remove),
            onPressed: _value > 1 ? () => setState(() => _value--) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '$_value',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          IconButton.outlined(
            icon: const Icon(Icons.add),
            onPressed: _value < 99 ? () => setState(() => _value++) : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _value),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
