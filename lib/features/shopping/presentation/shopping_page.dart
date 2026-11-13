import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/text_sharer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/share_sheet.dart';
import '../application/shopping_providers.dart';
import '../domain/shopping_item.dart';
import '../domain/shopping_list_text.dart';
import '../domain/supermarket_section.dart';
import 'supermarket_section_ui.dart';

class ShoppingPage extends ConsumerWidget {
  const ShoppingPage({super.key});

  /// Escolher a secção de um ingrediente; a app lembra-se da escolha.
  Future<void> _changeSection(
    BuildContext context,
    WidgetRef ref,
    ShoppingItem item,
  ) {
    final repo = ref.read(sectionOverridesRepositoryProvider);
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Mudar de secção', style: theme.textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
              child: Text(
                item.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final s in SupermarketSection.values)
              ListTile(
                leading: Icon(s.icon),
                title: Text(s.label),
                trailing: s == item.section ? const Icon(Icons.check) : null,
                onTap: () {
                  repo.set(item.ingredientKey, s);
                  Navigator.pop(ctx);
                },
              ),
            if (item.sectionIsCustom)
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('Repor automático'),
                onTap: () {
                  repo.clear(item.ingredientKey);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Partilha o que falta comprar: WhatsApp, e-mail, SMS, copiar ou outras apps.
  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingItem> items,
  ) async {
    final now = DateTime.now();
    final end = now.add(const Duration(days: 6));
    final title =
        'Lista de compras (${now.day}/${now.month} – ${end.day}/${end.month})';
    final text = shoppingListText(items, title: '🛒 $title');
    final messenger = ScaffoldMessenger.of(context);

    if (text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não há itens por comprar.')),
      );
      return;
    }

    await showShareSheet(
      context,
      sharer: ref.read(textSharerProvider),
      subject: title,
      text: text,
      copiedMessage: 'Lista copiada.',
    );
  }

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

    final theme = Theme.of(context);
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
        child: Row(
          children: [
            Expanded(
              child: Text('Próximos 7 dias', style: theme.textTheme.titleMedium),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Partilhar lista',
              onPressed: () => _share(context, ref, items),
            ),
            TextButton(
              onPressed: repo.clearChecked,
              child: const Text('Limpar marcados'),
            ),
          ],
        ),
      ),
    ];

    for (final section in SupermarketSection.values) {
      final inSection = items.where((i) => i.section == section).toList();
      if (inSection.isEmpty) continue;

      // Por comprar primeiro, comprados no fim.
      final ordered = <ShoppingItem>[
        ...inSection.where((i) => !i.checked),
        ...inSection.where((i) => i.checked),
      ];
      final pending = inSection.where((i) => !i.checked).length;

      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Icon(section.icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                section.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$pending/${inSection.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
      for (final item in ordered) {
        children.add(
          ListTile(
            leading: Checkbox(
              value: item.checked,
              onChanged: (v) => repo.setChecked(item.key, checked: v ?? false),
            ),
            title: Text(
              item.name,
              style: item.checked
                  ? TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : null,
            ),
            subtitle: item.count > 1 ? Text('em ${item.count} refeições') : null,
            trailing: IconButton(
              icon: Icon(
                item.sectionIsCustom
                    ? Icons.drive_file_move
                    : Icons.drive_file_move_outlined,
              ),
              tooltip: 'Mudar de secção',
              onPressed: () => _changeSection(context, ref, item),
            ),
            onTap: () => repo.setChecked(item.key, checked: !item.checked),
            onLongPress: () => _changeSection(context, ref, item),
          ),
        );
      }
    }

    return ListView(children: [...children, const SizedBox(height: 24)]);
  }
}
