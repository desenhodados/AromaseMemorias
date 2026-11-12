import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state.dart';
import '../application/recipe_providers.dart';
import '../domain/cooking_mode.dart';
import 'cooking_mode_ui.dart';
import 'recipe_card.dart';

class RecipesPage extends ConsumerWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(recipeFilterProvider);
    final notifier = ref.read(recipeFilterProvider.notifier);
    final recipes = ref.watch(filteredRecipesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Pesquisar receitas ou ingredientes',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: notifier.setQuery,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todas'),
                selected: filter.mode == null,
                onSelected: (_) => notifier.setMode(null),
              ),
              for (final m in CookingMode.values)
                ChoiceChip(
                  avatar: Icon(m.icon, size: 18),
                  label: Text(m.label),
                  selected: filter.mode == m,
                  onSelected: (_) => notifier.setMode(m),
                ),
              FilterChip(
                avatar: const Icon(Icons.favorite, size: 18),
                label: const Text('Favoritas'),
                selected: filter.onlyFavorites,
                onSelected: notifier.setOnlyFavorites,
              ),
            ],
          ),
        ),
        Expanded(
          child: recipes.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
            data: (list) => list.isEmpty
                ? const EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'Sem receitas',
                    message: 'Toque em Adicionar para criar ou importar a primeira.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                    itemCount: list.length,
                    itemBuilder: (_, i) => RecipeCard(recipe: list[i]),
                  ),
          ),
        ),
      ],
    );
  }
}
