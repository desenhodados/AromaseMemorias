import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../../recipes/application/recipe_providers.dart';
import '../../recipes/domain/recipe.dart';
import '../application/plan_providers.dart';
import '../domain/meal_type.dart';

const _weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
    MealType meal,
    List<Recipe> recipes,
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
    } else {
      await repo.assign(day, meal, id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider).valueOrNull ?? const <String, String>{};
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
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(meal.label),
                    subtitle: Text(
                      byId[plan[slotKey(day, meal)]]?.title ??
                          'Toque para escolher',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pick(context, ref, day, meal, recipes),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
