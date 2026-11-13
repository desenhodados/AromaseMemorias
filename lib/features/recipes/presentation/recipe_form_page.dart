import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../application/category_providers.dart';
import '../application/recipe_providers.dart';
import '../data/photo_picker.dart';
import '../data/photo_storage.dart';
import '../domain/cooking_mode.dart';
import '../domain/recipe.dart';
import '../domain/recipe_category.dart';
import 'category_editor_dialog.dart';
import 'cooking_mode_ui.dart';
import 'recipe_category_ui.dart';
import 'recipe_photo.dart';

/// Valor especial do menu de categorias: abre o criador de categorias.
const _newCategory = '__nova__';

List<String> _splitLines(String text) =>
    text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

class RecipeFormPage extends ConsumerStatefulWidget {
  const RecipeFormPage({super.key, this.recipe, this.isNew = false});

  final Recipe? recipe;

  /// `true` quando [recipe] é um rascunho ainda não guardado (ex.: importado).
  final bool isNew;

  @override
  ConsumerState<RecipeFormPage> createState() => _RecipeFormPageState();
}

class _RecipeFormPageState extends ConsumerState<RecipeFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.recipe?.title);
  late final _minutes = TextEditingController(
    text: widget.recipe == null ? '' : '${widget.recipe!.minutes}',
  );
  late final _servings = TextEditingController(
    text: widget.recipe == null ? '' : '${widget.recipe!.servings}',
  );
  late final _ingredients = TextEditingController(
    text: widget.recipe?.ingredients.join('\n'),
  );
  late final _steps = TextEditingController(
    text: widget.recipe?.steps.join('\n'),
  );
  late final _notes = TextEditingController(text: widget.recipe?.notes);
  late final Set<CookingMode> _modes = {...?widget.recipe?.modes};
  late final String _id =
      widget.recipe?.id ?? DateTime.now().microsecondsSinceEpoch.toString();

  late final PhotoStorage _photos;

  /// Foto já guardada na receita (um rascunho importado conta como "nova").
  late final String? _originalPhoto =
      widget.isNew ? null : widget.recipe?.photoPath;
  String? _photoName;
  String? _categoryId;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _photos = ref.read(photoStorageProvider);
    _photoName = widget.recipe?.photoPath;
    _categoryId = widget.recipe?.categoryId;
  }

  @override
  void dispose() {
    // Saiu sem guardar: apaga a foto nova para não deixar ficheiros órfãos.
    if (!_saved && _photoName != _originalPhoto) _photos.delete(_photoName);
    _title.dispose();
    _minutes.dispose();
    _servings.dispose();
    _ingredients.dispose();
    _steps.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(ctx, PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(ctx, PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await ref.read(photoPickerProvider).pick(source);
      if (path == null) return;
      final name = await _photos.saveFromPath(path, recipeId: _id);
      if (_photoName != _originalPhoto) await _photos.delete(_photoName);
      if (mounted) setState(() => _photoName = name);
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível obter a foto.')),
      );
    }
  }

  void _removePhoto() {
    if (_photoName != _originalPhoto) _photos.delete(_photoName);
    setState(() => _photoName = null);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_modes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha pelo menos um modo.')),
      );
      return;
    }
    final modes = CookingMode.values.where(_modes.contains).toSet();
    final base = widget.recipe ?? Recipe(id: _id, title: '', modes: modes);
    final recipe = base.copyWith(
      title: _title.text.trim(),
      modes: modes,
      minutes: int.tryParse(_minutes.text.trim()) ?? 0,
      servings: int.tryParse(_servings.text.trim()) ?? 1,
      ingredients: _splitLines(_ingredients.text),
      steps: _splitLines(_steps.text),
      notes: _notes.text.trim(),
      photoPath: _photoName,
      clearPhoto: _photoName == null,
      categoryId: _categoryId,
      clearCategory: _categoryId == null,
    );
    await ref.read(recipeRepositoryProvider).save(recipe);
    _saved = true;
    if (_originalPhoto != null && _originalPhoto != _photoName) {
      await _photos.delete(_originalPhoto);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _createCategory(List<RecipeCategory> categories) async {
    final created = await showCategoryEditor(
      context,
      takenLabels: RecipeCategory.takenLabels(categories),
    );
    if (created == null) return;
    await ref.read(categoryRepositoryProvider).save(created);
    if (mounted) setState(() => _categoryId = created.id);
  }

  Widget _photoSection() {
    final scheme = Theme.of(context).colorScheme;
    if (_photoName == null) {
      return AppCard(
        onTap: _pickPhoto,
        child: SizedBox(
          height: 140,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 36, color: scheme.primary),
              const SizedBox(height: 8),
              const Text('Adicionar foto'),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: RecipePhoto(photoPath: _photoName, cacheWidth: 900),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            spacing: 8,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.edit),
                tooltip: 'Alterar foto',
                onPressed: _pickPhoto,
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remover foto',
                onPressed: _removePhoto,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(allCategoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recipe == null || widget.isNew ? 'Nova receita' : 'Editar receita',
        ),
        actions: [TextButton(onPressed: _save, child: const Text('Guardar'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_photos.isSupported) ...[
              _photoSection(),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Indique um título' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              // ignore: deprecated_member_use
              value: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sem categoria'),
                ),
                for (final c in categories)
                  DropdownMenuItem<String?>(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(c.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(c.label),
                      ],
                    ),
                  ),
                const DropdownMenuItem<String?>(
                  value: _newCategory,
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 8),
                      Text('Nova categoria…'),
                    ],
                  ),
                ),
              ],
              onChanged: (v) {
                if (v == _newCategory) {
                  _createCategory(categories);
                } else {
                  setState(() => _categoryId = v);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Modo de preparação'),
            Wrap(
              spacing: 8,
              children: [
                for (final m in CookingMode.values)
                  FilterChip(
                    avatar: Icon(m.icon, size: 18),
                    label: Text(m.label),
                    selected: _modes.contains(m),
                    onSelected: (v) => setState(() {
                      v ? _modes.add(m) : _modes.remove(m);
                    }),
                  ),
              ],
            ),
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minutes,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Minutos'),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _servings,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Porções'),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _ingredients,
              minLines: 4,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: 'Ingredientes (um por linha)',
                alignLabelWithHint: true,
              ),
            ),
            TextFormField(
              controller: _steps,
              minLines: 4,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: 'Passos (um por linha)',
                alignLabelWithHint: true,
              ),
            ),
            TextFormField(
              controller: _notes,
              minLines: 2,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notas pessoais',
                hintText: 'Ex.: menos sal da próxima vez',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
