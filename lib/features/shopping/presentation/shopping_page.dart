import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state.dart';
import '../application/shopping_providers.dart';

class ShoppingPage extends ConsumerWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shoppingItemsProvider);
    final repo = ref.read(shoppingRepositoryProvider);

    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Lista vazia',
        message: 'Planeie refeições na aba Semana e a lista de compras aparece aqui.',
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Próximos 7 dias',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: repo.clearChecked,
                child: const Text('Limpar marcados'),
              ),
            ],
          ),
        ),
        for (final item in items)
          CheckboxListTile(
            value: item.checked,
            title: Text(item.name),
            subtitle: item.count > 1 ? Text('em ${item.count} refeições') : null,
            onChanged: (v) => repo.setChecked(item.name, checked: v ?? false),
          ),
      ],
    );
  }
}
