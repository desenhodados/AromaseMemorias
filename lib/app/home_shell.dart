import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/planner/presentation/plan_page.dart';
import '../features/recipes/application/category_providers.dart';
import '../features/recipes/application/recipe_deleter.dart';
import '../features/recipes/application/recipe_providers.dart';
import '../features/recipes/application/recipe_selection.dart';
import '../features/recipes/domain/recipe.dart';
import '../features/recipes/domain/recipe_category.dart';
import '../features/recipes/presentation/category_editor_dialog.dart';
import '../features/recipes/presentation/category_picker_sheet.dart';
import '../features/recipes/presentation/recipe_deleted_snackbar.dart';
import '../features/recipes/presentation/recipe_form_page.dart';
import '../features/recipes/presentation/recipe_import_page.dart';
import '../features/recipes/presentation/recipes_page.dart';
import '../features/shopping/presentation/shopping_page.dart';
import 'app_drawer.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _titles = ['Receitas', 'Semana', 'Compras'];
  static const _pages = [RecipesPage(), PlanPage(), ShoppingPage()];

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));

  void _showAddMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Nova receita'),
              onTap: () {
                Navigator.pop(ctx);
                _open(const RecipeFormPage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Importar por link'),
              onTap: () {
                Navigator.pop(ctx);
                _open(const RecipeImportPage());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _selectAllVisible() {
    final visible = ref.read(filteredRecipesProvider).valueOrNull ?? const <Recipe>[];
    ref.read(recipeSelectionProvider.notifier).selectAll(visible.map((r) => r.id));
  }

  /// Define a categoria de todas as receitas selecionadas.
  Future<void> _assignCategory() async {
    final messenger = ScaffoldMessenger.of(context);
    final categories = ref.read(allCategoriesProvider);
    final selection = ref.read(recipeSelectionProvider.notifier);

    final choice = await showCategoryPicker(context, categories);
    if (choice == null || !mounted) return;

    String? categoryId;
    RecipeCategory? target;
    if (choice == categoryPickerNew) {
      final created = await showCategoryEditor(
        context,
        takenLabels: RecipeCategory.takenLabels(categories),
      );
      if (created == null) return;
      await ref.read(categoryRepositoryProvider).save(created);
      categoryId = created.id;
      target = created;
    } else if (choice != categoryPickerNone) {
      categoryId = choice;
      target = categories.where((c) => c.id == choice).firstOrNull;
    }

    final count = await selection.assignCategory(categoryId);
    final noun = count == 1 ? 'receita' : 'receitas';
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          target == null
              ? 'Categoria removida de $count $noun.'
              : '$count $noun em "${target.label}".',
        ),
      ),
    );
  }

  Future<void> _setFavorite(bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    final count = await ref.read(recipeSelectionProvider.notifier).setFavorite(value);
    final noun = count == 1 ? 'receita' : 'receitas';
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          value ? '$count $noun nos favoritos.' : '$count $noun fora dos favoritos.',
        ),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final messenger = ScaffoldMessenger.of(context);
    final count = ref.read(recipeSelectionProvider).length;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(count == 1 ? 'Apagar 1 receita?' : 'Apagar $count receitas?'),
          content: const Text('Poderá desfazer durante alguns segundos depois de apagar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;

    final removed = await ref.read(recipeSelectionProvider.notifier).deleteSelected();
    showDeletedSnackBar(messenger, ref.read(recipeDeleterProvider), removed);
  }

  PreferredSizeWidget _selectionBar(int count, {required bool allFavorite}) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Cancelar seleção',
        onPressed: ref.read(recipeSelectionProvider.notifier).clear,
      ),
      title: Text(count == 1 ? '1 selecionada' : '$count selecionadas'),
      actions: [
        IconButton(
          icon: Icon(allFavorite ? Icons.favorite : Icons.favorite_border),
          tooltip: allFavorite ? 'Tirar dos favoritos' : 'Marcar como favoritas',
          onPressed: () => _setFavorite(!allFavorite),
        ),
        IconButton(
          icon: const Icon(Icons.category_outlined),
          tooltip: 'Definir categoria',
          onPressed: _assignCategory,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Apagar',
          onPressed: _deleteSelected,
        ),
        PopupMenuButton<String>(
          onSelected: (_) => _selectAllVisible(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'all', child: Text('Selecionar todas')),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(recipeSelectionProvider);
    final selecting = _index == 0 && selection.isNotEmpty;
    final recipes = ref.watch(recipesProvider).valueOrNull ?? const <Recipe>[];
    final selectedRecipes = recipes.where((r) => selection.contains(r.id));
    final allFavorite =
        selectedRecipes.isNotEmpty && selectedRecipes.every((r) => r.isFavorite);

    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(recipeSelectionProvider.notifier).clear();
      },
      child: Scaffold(
        appBar: selecting
            ? _selectionBar(selection.length, allFavorite: allFavorite)
            : AppBar(title: Text(_titles[_index])),
        drawer: selecting ? null : const AppDrawer(),
        body: IndexedStack(index: _index, children: _pages),
        floatingActionButton: _index == 0 && !selecting
            ? FloatingActionButton.extended(
                onPressed: _showAddMenu,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            ref.read(recipeSelectionProvider.notifier).clear();
            setState(() => _index = i);
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Receitas'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Semana'),
            NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Compras'),
          ],
        ),
      ),
    );
  }
}
