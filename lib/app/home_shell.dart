import 'package:flutter/material.dart';

import '../features/planner/presentation/plan_page.dart';
import '../features/recipes/presentation/recipe_form_page.dart';
import '../features/recipes/presentation/recipe_import_page.dart';
import '../features/recipes/presentation/recipes_page.dart';
import '../features/shopping/presentation/shopping_page.dart';
import 'app_drawer.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      drawer: const AppDrawer(),
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddMenu,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Receitas'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Semana'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Compras'),
        ],
      ),
    );
  }
}
