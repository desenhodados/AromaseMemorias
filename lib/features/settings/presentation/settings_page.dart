import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../../backup/presentation/backup_page.dart';
import '../../recipes/application/recipe_providers.dart';
import '../../recipes/domain/recipe.dart';
import '../../recipes/domain/recipe_category.dart';
import '../../recipes/presentation/manage_categories_page.dart';
import '../application/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  /// Sugere categorias (pelo título) para as receitas que ainda não têm.
  Future<void> _autoCategorize(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(recipeRepositoryProvider);
    final recipes = ref.read(recipesProvider).valueOrNull ?? const <Recipe>[];

    var changed = 0;
    for (final r in recipes) {
      if (r.categoryId != null) continue;
      final guess = RecipeCategory.guess(r.title);
      if (guess == null) continue;
      await repo.save(r.copyWith(categoryId: guess.id));
      changed++;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          changed == 0
              ? 'Não reconheci nenhuma receita sem categoria.'
              : changed == 1
                  ? '1 receita categorizada.'
                  : '$changed receitas categorizadas.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final label = Theme.of(context).textTheme.titleSmall?.copyWith(color: primary);

    return Scaffold(
      appBar: AppBar(title: const Text('Definições')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Aparência', style: label),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('Sistema'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('Claro'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('Escuro'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).setMode(s.first),
          ),
          const SizedBox(height: 24),
          Text('Receitas', style: label),
          const SizedBox(height: 8),
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Gerir categorias'),
              subtitle: const Text('Criar, editar e apagar as suas categorias'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const ManageCategoriesPage()),
              ),
            ),
          ),
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Categorizar automaticamente'),
              subtitle: const Text(
                'Sugere categorias (sopas, carne, sobremesas…) para as receitas que ainda não têm',
              ),
              onTap: () => _autoCategorize(context, ref),
            ),
          ),
          const SizedBox(height: 24),
          Text('Dados', style: label),
          const SizedBox(height: 8),
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Backup e restauro'),
              subtitle: const Text('Exportar ou importar as suas receitas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const BackupPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
