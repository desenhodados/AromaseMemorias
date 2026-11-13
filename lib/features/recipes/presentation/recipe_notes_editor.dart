import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/recipe_providers.dart';
import '../domain/recipe.dart';

/// Abre o editor das notas pessoais de uma receita e guarda o resultado
/// (texto vazio = sem notas). Pode ser chamado do detalhe ou do modo de cozinhar.
Future<void> editRecipeNotes(BuildContext context, WidgetRef ref, Recipe recipe) async {
  final repo = ref.read(recipeRepositoryProvider);
  final notes = await showDialog<String>(
    context: context,
    builder: (_) => _NotesDialog(initial: recipe.notes),
  );
  if (notes == null) return;
  // Usa a versão mais recente da receita, caso tenha mudado entretanto.
  final latest = ref.read(recipeByIdProvider(recipe.id)) ?? recipe;
  await repo.save(latest.copyWith(notes: notes.trim()));
}

class _NotesDialog extends StatefulWidget {
  const _NotesDialog({required this.initial});

  final String initial;

  @override
  State<_NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<_NotesDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notas pessoais'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 3,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Ex.: menos sal da próxima vez',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
