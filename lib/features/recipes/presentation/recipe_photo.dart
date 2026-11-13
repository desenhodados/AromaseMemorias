import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/recipe_providers.dart';

/// Mostra a foto de uma receita (ou [placeholder] se não existir/falhar).
class RecipePhoto extends ConsumerWidget {
  const RecipePhoto({
    super.key,
    required this.photoPath,
    this.cacheWidth,
    this.placeholder,
  });

  final String? photoPath;
  final int? cacheWidth;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = photoPath;
    final storage = ref.watch(photoStorageProvider);
    final fallback = placeholder ?? const SizedBox.shrink();
    if (name == null || !storage.isSupported) return fallback;
    return Image.file(
      storage.fileFor(name),
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
