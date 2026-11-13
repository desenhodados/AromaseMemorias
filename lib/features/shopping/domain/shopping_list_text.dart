import 'shopping_item.dart';
import 'supermarket_section.dart';

/// Texto da lista para partilhar: só o que falta comprar, por secção.
///
/// Os títulos das secções vão entre `*...*` (negrito no WhatsApp). Devolve
/// texto vazio se não houver nada por comprar.
String shoppingListText(List<ShoppingItem> items, {required String title}) {
  final buffer = StringBuffer();

  for (final section in SupermarketSection.values) {
    final pending = items.where((i) => i.section == section && !i.checked);
    if (pending.isEmpty) continue;
    buffer
      ..writeln('*${section.label}*')
      ..writeAll([for (final i in pending) '• ${i.name}\n'])
      ..writeln();
  }

  final body = buffer.toString().trimRight();
  return body.isEmpty ? '' : '$title\n\n$body';
}
