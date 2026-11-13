import 'package:flutter/material.dart';

import '../../../core/text_utils.dart';
import '../domain/recipe_category.dart';
import 'recipe_category_ui.dart';

/// Cria ou edita uma categoria personalizada. [takenLabels] são os nomes já
/// usados por outras categorias (ver [RecipeCategory.takenLabels]).
Future<RecipeCategory?> showCategoryEditor(
  BuildContext context, {
  RecipeCategory? existing,
  required Set<String> takenLabels,
}) {
  return showDialog<RecipeCategory>(
    context: context,
    builder: (_) => _CategoryEditorDialog(existing: existing, takenLabels: takenLabels),
  );
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({required this.existing, required this.takenLabels});

  final RecipeCategory? existing;
  final Set<String> takenLabels;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final _name = TextEditingController(text: widget.existing?.label);
  late String _iconKey = widget.existing?.iconKey ?? 'restaurant';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Indique um nome');
      return;
    }
    if (widget.takenLabels.contains(foldAccents(name))) {
      setState(() => _error = 'Já existe uma categoria com este nome');
      return;
    }
    Navigator.pop(
      context,
      RecipeCategory(
        id: widget.existing?.id ?? 'c${DateTime.now().microsecondsSinceEpoch}',
        label: name,
        iconKey: _iconKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Nova categoria' : 'Editar categoria'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: 'Nome', errorText: _error),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            const Text('Ícone'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in categoryIconChoices.entries)
                  ChoiceChip(
                    showCheckmark: false,
                    label: Icon(e.value, size: 20),
                    selected: e.key == _iconKey,
                    onSelected: (_) => setState(() => _iconKey = e.key),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
