import 'recipe.dart';

/// Texto de uma receita para partilhar (WhatsApp, e-mail…). Usa os
/// [ingredients] e as [servings] indicados, para partilhar com as quantidades
/// ajustadas. Os títulos vão entre `*...*` (negrito no WhatsApp).
String recipeShareText(
  Recipe recipe, {
  required List<String> ingredients,
  required int servings,
  String? categoryLabel,
}) {
  final info = [
    if (recipe.minutes > 0) '⏱ ${recipe.minutes} min',
    '👥 $servings ${servings == 1 ? 'porção' : 'porções'}',
    if (categoryLabel != null) categoryLabel,
    if (recipe.modes.isNotEmpty) recipe.modes.map((m) => m.label).join(' / '),
  ];

  final buffer = StringBuffer()
    ..writeln('🍽️ *${recipe.title}*')
    ..writeln(info.join(' · '));

  if (ingredients.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('*Ingredientes*');
    for (final i in ingredients) {
      buffer.writeln('• $i');
    }
  }

  if (recipe.steps.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('*Preparação*');
    for (var n = 0; n < recipe.steps.length; n++) {
      buffer.writeln('${n + 1}. ${recipe.steps[n]}');
    }
  }

  final source = recipe.sourceUrl;
  if (source != null && source.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('Fonte: $source');
  }
  return buffer.toString().trimRight();
}
