import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/recipe_providers.dart';
import '../data/recipe_importer.dart';
import 'recipe_form_page.dart';

class RecipeImportPage extends ConsumerStatefulWidget {
  const RecipeImportPage({super.key});

  @override
  ConsumerState<RecipeImportPage> createState() => _RecipeImportPageState();
}

class _RecipeImportPageState extends ConsumerState<RecipeImportPage> {
  final _url = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _details;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) setState(() => _url.text = text);
  }

  Future<void> _import() async {
    final importer = ref.read(recipeImporterProvider);
    setState(() {
      _loading = true;
      _error = null;
      _details = null;
    });
    try {
      final draft = await importer.importFromUrl(_url.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => RecipeFormPage(recipe: draft, isNew: true),
        ),
      );
    } on RecipeImportException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _details = e.details;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Importar por link')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              enabled: !_loading,
              decoration: InputDecoration(
                labelText: 'Endereço da receita',
                helperText:
                    'Funciona com a maioria dos sites de receitas. Pode rever e editar antes de guardar.',
                helperMaxLines: 3,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste),
                  tooltip: 'Colar',
                  onPressed: _paste,
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_error!, style: TextStyle(color: scheme.error)),
                    if (_details != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SelectableText(
                          'Detalhe técnico: $_details',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loading ? null : _import,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_loading ? 'A importar…' : 'Importar'),
            ),
          ],
        ),
      ),
    );
  }
}
